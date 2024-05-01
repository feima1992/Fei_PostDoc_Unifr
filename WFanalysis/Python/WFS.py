## Class to perform widefield imaging with single cell resolution using mescore package

#%% Importing necessary libraries
import os
import re
import numpy as np
import pandas as pd
import hdf5storage

from caiman.base.rois import register_multisession
from upsetplot import from_contents, UpSet
from matplotlib import pyplot as plt

import mesmerize_core as mc
from mesmerize_viz import *

from mesmerize_core.caiman_extensions.cnmf import cnmf_cache

from caiman.source_extraction.cnmf.deconvolution import GetSn

if os.name == "nt":
    # disable the cache on windows, this will be automatic in a future version
    cnmf_cache.set_maxsize(0)

#%% search_file function
def search_file(top_dir, include_strs=[], exclude_strs=[]):
    file_list = []
    for root, dirs, files in os.walk(top_dir, followlinks=True):
        for file in files:
            full_path = os.path.abspath(os.path.join(root, file))
            if all(map(lambda x: re.findall(x, full_path), include_strs)):
                file_list.append(full_path)
    for exclude_str in exclude_strs:
        file_list = list(filter(lambda file_name: not re.findall(
            exclude_str, file_name), file_list))
    return list(set(file_list))

#%% Zscore function add to mc
def run_zscore(self, offset_method ="floor", sn_method = "logmexp", range_ff = [0.25,0.5]):
            
    # get the estimates for the item
    cnmfe = self.get_output()
    denoised_traces = cnmfe.estimates.C
    residuals = cnmfe.estimates.YrA
    raw_traces = denoised_traces + residuals
    # get the snr for the item
    denoised_traces_zscore = []
    raw_traces_zscore = []
    noise_levels = []
    for idx, raw_trace in enumerate(raw_traces):
        denoised_trace = denoised_traces[idx,:]
        noise_level = GetSn(raw_trace, method = sn_method, range_ff = range_ff)
        if offset_method == "floor":
            raw_offset = np.floor(np.min(raw_trace))
            denoise_offset = np.floor(np.min(denoised_trace))
        elif offset_method == "mean":
            raw_offset = np.mean(raw_trace)
            denoise_offset = np.mean(denoised_trace)
        elif offset_method == "median":
            raw_offset = np.median(raw_trace)
            denoise_offset = np.median(denoised_trace)
        elif offset_method == "none":
            raw_offset = 0
            denoise_offset = 0
        else:
            raise ValueError(f"offset_method should be one of ['floor', 'mean', 'median', 'none']")
        raw_traces_zscore.append((raw_trace - raw_offset) / noise_level)
        denoised_traces_zscore.append((denoised_trace - denoise_offset) / noise_level)
        noise_levels.append(noise_level)
    cnmfe.estimates.raw_traces_zscore = raw_traces_zscore
    cnmfe.estimates.denoised_traces_zscore = denoised_traces_zscore
    cnmfe.estimates.noise_levels = noise_levels
    # save new hdf5 file with new F_dff vals
    cnmfe_obj_path = self.get_output_path()
    cnmfe_obj_path.unlink()
    cnmfe.save(str(cnmfe_obj_path))
    return self
mc.CNMFExtensions.run_zscore = run_zscore

def get_zscore(self, type = "denoised", component_indices = None):
    if component_indices is None:
        component_indices = np.arange(len(self.get_output().estimates.raw_traces_zscore))
    if type == "raw":
        return self.get_output().estimates.raw_traces_zscore[component_indices]
    elif type == "denoised":
        return self.get_output().estimates.denoised_traces_zscore[component_indices]
    elif type == "noise":
        return self.get_output().estimates.noise_levels[component_indices]
    else:
        raise ValueError(f"type should be one of ['raw', 'denoised', 'noise']")
mc.CNMFExtensions.get_zscore = get_zscore

#%% Class definition
class WFS:
    
    #%% Constructor
    def __init__(self, batch_folder = r"D:\Data\SingleCellData", data_folder_name ="mesmerize-cnmfe", gSig = 3, min_corr = 0.8, min_pnr = 10):

        # set the batch folder
        self.batch_folder = batch_folder
        self.data_folder_name = data_folder_name

        # set the mesmerize core object
        self.mc = mc

        # set the batch file
        self.mc.set_parent_raw_data_path(self.batch_folder)
        self.batch_file = self.mc.get_parent_raw_data_path().joinpath(self.data_folder_name + "/batch.pickle")
        
        # load the batch file
        self.Load()
            
        # Update the batch file
        self.Update()
    
    #%% Method to load the batch dataframe file
    def Load(self):
        # create the batch pickle file if it does not exist
        if not self.batch_file.exists():
            self.df = self.mc.create_batch(self.batch_file)
        else:
            self.df = self.mc.load_batch(self.batch_file)
        return self
    
    #%% Method to update the batch dataframe file
    def Update(self, errorRetry = False):
        # remove the items having outputs error from the batch if errorRetry is True
        if errorRetry: self.RemoveError()
                
        # scan all the tiffs in the batch folder
        self.tif_files = search_file(self.batch_folder, [".tif"])
        if len(self.tif_files) == 0:
            print("No tiff files found in the batch folder")
            return
        
        # add tiff files to the batch for motion correction
        algo = 'mcorr'
        for tiff_file in self.tif_files:
            item_name = tiff_file.split("\\")[-1].split(".")[0]            
            # add the tiff file to the batch if it does not exist
            df_mcorr = self.df[self.df['algo'] == 'mcorr']
            if item_name not in df_mcorr['item_name'].values:
                self.df.caiman.add_item(
                    algo = algo,
                    input_movie_path = tiff_file,
                    params = self.params_mcorr,
                    item_name = item_name
                )
                print(f"Motion correction item {item_name} added to the batch")
            
        # add motion corrected items to the batch for CNMFE
        df_mcorr = self.df[self.df['algo'] == 'mcorr']
        algo = 'cnmfe'
        for i, row in df_mcorr.iterrows():
            item_name = row['item_name']
            outputs = row['outputs']
            # add the tiff file to the batch if it does not exist
            df_cnmfe = self.df[self.df['algo'] == 'cnmfe']
            if item_name not in df_cnmfe['item_name'].values and outputs is not None:
                self.df.caiman.add_item(
                    algo = 'cnmfe',
                    input_movie_path = row,
                    params = self.params_cnmfe,
                    item_name = item_name
                )
                print(f"CNMFE item {item_name} added to the batch")
                
        # sort the rows of the dataframe
        self.df = self.df.sort_values(by = ['algo','item_name'], ascending = [False, True], ignore_index=True)
        return self
    
    #%% Method to filter items in the batch dataframe
    def Index(self, mouse = None, session = None, algo = None, runSuccess = None):
        # select the rows of the dataframe
        df = self.df
        idx = np.ones(len(df), dtype = bool)
        if mouse is not None:
            idx_mouse = df['item_name'].str.contains(mouse)
            idx = np.logical_and(idx, idx_mouse)
        if session is not None:
            idx_session = df['item_name'].str.contains(session)
            idx = np.logical_and(idx, idx_session)
        if algo is not None:
            idx_algo = df['algo'] == algo
            idx = np.logical_and(idx, idx_algo)
        runResults = [X['success'] if X is not None else None for X in df['outputs']]
        if runSuccess is not None:
            idx_runSuccess = np.array(runResults) == runSuccess
            idx = np.logical_and(idx, idx_runSuccess)
        # convert to numeric index
        idx = np.where(idx)[0]
        # if no index found return all the indexes
        if len(idx) == 0:
            print("No items found with the given parameters, returning indexes of all items")
            idx = np.arange(len(df))
        return idx
    
    #%% remove error items from the batch dataframe
    def RemoveError(self):
        for i in self.Index(runSuccess = False):
            self.df.caiman.remove_item(self.df.iloc[i].uuid)
            print(f"Item {self.df.iloc[i].item_name} with algo {self.df.iloc[i].algo} has error outputs and removed from the batch")
        return self
    
    #%% Method to run the item selected with mouse session and algorithm         
    def Run(self, mouse = None, session = None, algo = None):
        for i in self.Index(mouse = mouse, session = session, algo = algo):
            print()
            print("==============================================================")
            if self.df.iloc[i].outputs is None:
                print(f"Item {self.df.iloc[i].item_name} processed with algo {self.df.iloc[i].algo}")
                process = self.df.iloc[i].caiman.run()
                if process.__class__.__name__ == "DummyProcess":
                    self.df = self.df.caiman.reload_from_disk()
            else:
                print(f"Item {self.df.iloc[i].item_name} with algo {self.df.iloc[i].algo} already processed")
        self.Update()
        return self
    
    #%% Method to evaluate the item selected with mouse session and algorithm
    def Eval(self, mouse = None, session =None, algo = "cnmfe", runSuccess = True):
        print(f"Evaluating items with params {self.params_eval}")
        for i in self.Index(mouse = mouse, session = session, algo = algo, runSuccess = runSuccess):
            print()
            print(f"Evaluating item {self.df.iloc[i].item_name}")
            # run the evaluation
            self.df.iloc[i].cnmf.run_eval(self.params_eval)
            # print the evaluation results
            nAll = len(self.df.iloc[i].cnmf.get_output().estimates.C)
            nGood = len(self.df.iloc[i].cnmf.get_output().estimates.idx_components)
            nBad = len(self.df.iloc[i].cnmf.get_output().estimates.idx_components_bad)
            print(f"Total number of components: {nAll}, Good components: {nGood}, Bad components: {nBad}")
            # run the detrend_dfof
            self.df.iloc[i].cnmf.run_detrend_dfof(detrend_only  = True)
            # run the zscore
            self.df.iloc[i].cnmf.run_zscore()

        return self
    
    #%%
    def Zscore(self, mouse = None, session = None, algo = "cnmfe", runSuccess = True, offset_method ="floor", sn_method = "logmexp", range_ff = [0.25,0.5]):
        for i in self.Index(mouse = mouse, session = session, algo = algo, runSuccess = runSuccess):
            
            # get the estimates for the item
            cnmfe = self.df.iloc[i].cnmf.get_output().estimates
            denoised_traces = cnmfe.C
            residuals = cnmfe.YrA
            raw_traces = denoised_traces + residuals
            # get the snr for the item
            denoised_traces_zscore = []
            raw_traces_zscore = []
            noise_levels = []
            for idx, raw_trace in enumerate(raw_traces):
                denoised_trace = denoised_traces[idx,:]
                noise_level = GetSn(raw_trace, offset_method = offset_method, sn_method = sn_method, range_ff = range_ff)
                if offset_method == "floor":
                    raw_offset = np.floor(np.min(raw_trace))
                    denoise_offset = np.floor(np.min(denoised_trace))
                elif offset_method == "mean":
                    raw_offset = np.mean(raw_trace)
                    denoise_offset = np.mean(denoised_trace)
                elif offset_method == "median":
                    raw_offset = np.median(raw_trace)
                    denoise_offset = np.median(denoised_trace)
                elif offset_method == "none":
                    raw_offset = 0
                    denoise_offset = 0
                else:
                    raise ValueError(f"offset_method should be one of ['floor', 'mean', 'median', 'none']")
                raw_traces_zscore.append((raw_trace - raw_offset) / noise_level)
                denoised_traces_zscore.append((denoised_trace - denoise_offset) / noise_level)
                noise_levels.append(noise_level)
            
            print(f"Zscoring item {self.df.iloc[i].item_name}")
        return self

    #%% Method to run all the items in the batch
    def RunAll(self):
        self.Run()
        self.Update()
        self.Run()
        return self
    
    #%% Method to do the registration of multiple session
    def _getTemplate(self, mouse, sessions = None, filtgSize = (5,5)):
        # initialize the item_name and template lists
        item_name = []
        template = []
        # select the motion corrected items for the mouse and sessions
        df_mcorr = self.df[(self.df['algo'] == 'mcorr') & (self.df['item_name'].str.contains(mouse))]
        if sessions is not None:
            session_tf = [df_mcorr['item_name'].str.contains(session) for session in sessions]
            df_mcorr = df_mcorr[np.logical_or(*session_tf)]
        # get the template from the motion corrected items
        for i, row in df_mcorr.iterrows():
            outputs = row['outputs']
            if outputs is not None:
                item_name.append(row['item_name'])
                templateImg = row.caiman.get_corr_image()
                template.append(templateImg)
        # combine item_name and template as a dataframe
        df_template = pd.DataFrame({'item_name': item_name, 'template': template})
        # sort the dataframe
        df_template = df_template.sort_values(by = ['item_name'], ascending = [True], ignore_index=True)
        return df_template

    def _getEstimatesA(self, mouse, sessions = None):
        # initialize the item_name and estimatesA lists
        item_name = []
        estimatesA = []
        # select the CNMFE items for the mouse and sessions
        df_cnmfe = self.df[(self.df['algo'] == 'cnmfe') & (self.df['item_name'].str.contains(mouse))]
        if sessions is not None:
            session_tf = [df_cnmfe['item_name'].str.contains(session) for session in sessions]
            df_cnmfe = df_cnmfe[np.logical_or(*session_tf)]
        # get the estimatesA from the CNMFE items
        for i, row in df_cnmfe.iterrows():
            outputs = row['outputs']
            if outputs is not None:
                item_name.append(row['item_name'])
                estimatesA.append(row.cnmf.get_output().estimates.select_components(use_object=True).A)
        # combine item_name and template as a dataframe
        df_estimatesA = pd.DataFrame({'item_name': item_name, 'estimatesA': estimatesA})
        # sort the dataframe
        df_estimatesA = df_estimatesA.sort_values(by = ['item_name'], ascending = [True], ignore_index=True)
        return df_estimatesA
    
    #%% Method to register neuron ID across multiple sessions
    def Register(self, mouse, sessions = None, overwrite = False):
        if not hasattr(self, 'session_register'):
            self.session_register = []
        else:
            mouse_reg = [reg['mouse'] for reg in self.session_register]
            if mouse in mouse_reg:
                sessions = mouse_reg[mouse_reg.index(mouse)]['item_name']
                if overwrite is False:
                    print(f"Session register already exists for {mouse} and sessions {sessions}")
                    return self
                else:
                    print(f"Overwriting the session register for {mouse} and sessions {sessions}")
                    self.session_register.pop(mouse_reg.index(mouse))
        
        # inner join the template and estimatesA dataframes on item_name
        df_template = self._getTemplate(mouse, sessions = sessions)
        df_estimatesA = self._getEstimatesA(mouse, sessions = sessions)
        df_template_estimatesA = pd.merge(df_template, df_estimatesA, on = 'item_name')
        
        # get the template and estimatesA as list
        template = df_template_estimatesA['template'].tolist()
        estimatesA = df_template_estimatesA['estimatesA'].tolist()
        item_name = df_template_estimatesA['item_name'].tolist()
        
        # print the information of the items names to be registered
        print(f"Registering sessions {item_name}")
        
        spatial_union, assignments, matchings = register_multisession(A=estimatesA, dims = template[0].shape)
    
        self.session_register.append({'mouse': mouse, 'item_name': item_name, 'assignments': assignments})
        
        # upset plot of the results
        assignments_tf = ~ np.isnan(assignments)
        assignments_id = np.arange(assignments.shape[0])
        assignments_dict = {item_name[i]: assignments_id[assignments_tf[:,i]] for i in range(len(item_name))}
        
        UpSet(from_contents(assignments_dict), show_counts="%d", show_percentages=True).plot()
        plt.title(f"Registration across sessions")
        
        return self
    
    #%% Method to export the registered neurons to a .mat file
    def ExportSessionRegister(self, mouse = None, overwrite = False):
        # export the session_register to a .mat file if it exists
        if hasattr(self, 'session_register'):
            if mouse is None:
                mouse_reg = [reg['mouse'] for reg in self.session_register]
                session_reg = self.session_register[mouse_reg.index(mouse)]
            else:
                session_reg = self.session_register
            for i, reg in enumerate(session_reg):
                assignments = reg['assignments']
                item_name = reg['item_name']
                    
                # create the .mat file
                mat_file = str(self.mc.get_parent_raw_data_path().joinpath(f"{mouse}_sessionAssignment.mat"))
                
                if os.path.exists(mat_file) & (overwrite is False): continue
                
                hdf5storage.savemat(mat_file, {'item_name': item_name, 'assignments': assignments})
                print(f"Session register results exported to {mat_file}")
    
    def ExportCoordAndTrace(self, mouse = None, session = None, algo = "cnmfe", runSuccess = True, overwrite = False):
        for i in self.Index(mouse = mouse, session = session, algo = algo, runSuccess = runSuccess):
            row = self.df.iloc[i]
            # skip if the file already exists otherwise export
            item_name = row["item_name"]
            fileExport = str(self.mc.get_parent_raw_data_path().joinpath(f"{item_name}_coordAndTrace.mat"))
            if os.path.exists(fileExport) & (overwrite is False): continue
            print(f"Exporting coordinates and traces for item {item_name}")              
            # get the coordinates and traces
            good_cell_idx = row.cnmf.get_good_components()
            [contourXsYs, centerXY] = row.cnmf.get_contours(component_indices = good_cell_idx)
            dfof = row.cnmf.get_detrend_dfof(component_indices = good_cell_idx)
            zscore = row.cnmf.get_zscore(component_indices = good_cell_idx)
            # export the coordinates and traces to a .mat file
            hdf5storage.savemat(fileExport, {'good_cell_idx': good_cell_idx, 'contourXsYs': contourXsYs, 'centerXY': centerXY, 'dfof': dfof, 'zscore': zscore})
            print(f"Coordinates and traces exported to {fileExport}")
        
    #%% Properties
    
    @property
    def params_mcorr(self):
        params_mcorr ={
            "main":
            {
                "gSig_filt": (5, 5), # a gSig_filt value that brings out "landmarks" in the movie
                "pw_rigid": True,
                "max_shifts": (5, 5),
                "strides": (48, 48),
                "overlaps": (24, 24),
                "max_deviation_rigid": 3,
                "border_nan": "copy"
                }
            }
        return params_mcorr
    
    @property
    def params_cnmfe(self):
        gSig = 3
        params_cnmfe ={
            "main":
            {
                'method_init': 'corr_pnr',  # use this for 1 photon
                'K': None,
                'gSig': (gSig, gSig),
                'gSiz': (4 * gSig + 1, 4 * gSig + 1),
                'merge_thr': 0.7,
                'p': 1,
                'tsub': 2,
                'ssub': 1,
                'rf': 40,
                'stride': 20,
                'only_init': True,    # set it to True to run CNMF-E
                'nb': 0,
                'nb_patch': 0,
                'method_deconvolution': 'oasis',       # could use 'cvxpy' alternatively
                'low_rank_background': None,
                'update_background_components': True,  # sometimes setting to False improve the results
                'normalize_init': False,               # just leave as is
                'center_psf': True,                    # leave as is for 1 photon
                'ssub_B': 2,
                'ring_size_factor': 1.4,
                'del_duplicates': True,                # whether to remove duplicates from initialization
                'min_corr': 0.85,             # min correlation of peak (from PNR) value to accept a component
                'min_pnr': 10               # min peak to noise ratio to accept a component
            }
        }
        return params_cnmfe
    
    @property
    def params_eval(self):
        params_eval = {
                'min_SNR': 3.0, # SNR threshold for accepting a component
                'rval_thr': 0.85, # space correlation threshold for accepting a component
                'use_cnn': False, # use the CNN to classify if a component is a neuron or not, off for 1p data
                'SNR_lowest': 0.5, # neurons must have a minimum SNR
                'rval_lowest': -1 # neurons must have a minimum space correlation
        }
        return params_eval