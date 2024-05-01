## Class to perform widefield imaging with single cell resolution using mescore package

#%% Importing necessary libraries
from copy import deepcopy
import os
import re
import numpy as np
import pandas as pd
import tifffile
from ipywidgets import IntSlider, VBox
import fastplotlib as fpl

from caiman.motion_correction import high_pass_filter_space
from caiman.summary_images import correlation_pnr

import mesmerize_core as mc
from mesmerize_core.arrays import LazyTiff
from mesmerize_viz import *

from mesmerize_core.caiman_extensions.cnmf import cnmf_cache

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

#%% Class definition
class WFS:
    
    #%% Constructor
    def __init__(self, batch_folder = r"D:\Data\SingleCellData", data_folder_name ="mesmerize-cnmfe", gSig = 3, min_corr = 0.8, min_pnr = 10):

        # set important parameters
        self.gSig = 3
        self.min_corr = 0.8
        self.min_pnr = 10
        print('Parameters set as: gSig = {}, min_corr = {}, min_pnr = {}'.format(self.gSig, self.min_corr, self.min_pnr))
    
        # set the batch folder
        self.batch_folder = batch_folder
        self.data_folder_name = data_folder_name

        # set the mesmerize core object
        self.mc = mc

        # set the batch file
        self.mc.set_parent_raw_data_path(self.batch_folder)
        self.batch_file = self.mc.get_parent_raw_data_path().joinpath(self.data_folder_name + "/batch.pickle")
        
        # create the batch pickle file if it does not exist
        if not self.batch_file.exists():
            self.df = self.mc.create_batch(self.batch_file)
        else:
            self.df = self.mc.load_batch(self.batch_file)
            
        # Update the batch file
        self.Update()

    #%% Method to update the batch dataframe file
    def Update(self):
        # remove the items having outputs error
        for i, row in self.df.iterrows():
            if row["outputs"] is not None and row["outputs"]["success"] is False:
                self.df.caiman.remove_item(row['uuid'])
                print(f"Item {row.item_name} with algo {row.algo} has an error in the output and will be removed")
        
                
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
        self.df = self.df.sort_values(by = ['algo','item_name'], ascending = [False, True])
    
    #%% Method to run the item selected with mouse session and algorithm         
    def Run(self, mouse, session, algo):
        # get the item from the mouse and session
        item_name = f"{mouse}_{session}"
        # get the item from the batch
        df = self.df
        row = df[(df['item_name'] == item_name) & (df['algo'] == algo)]
        if row.empty:
            print(f"Item {item_name} with algo {algo} not found in the batch")
            return
        # run the item
        process = row.caiman.run()
        # on Windows you MUST reload the batch dataframe after every iteration because it uses the `local` backend.
        # "DummyProcess" is used for local backend so this is automatic
        if process.__class__.__name__ == "DummyProcess":
            df = df.caiman.reload_from_disk()
        print(f"Item {item_name} processed with algo {algo}")
        self.Update()

    def RunAll(self):
        self._runAll()
        self.Update()
        self._runAll()

    def _runAll(self):
        for i, row in self.df.iterrows():
            if row["outputs"] is not None: # item has already been run
                continue # skip this item
            print(f"Processing item {row.item_name} with algo {row.algo}")
            process = row.caiman.run()
            
            # on Windows you MUST reload the batch dataframe after every iteration because it uses the `local` backend.
            # "DummyProcess" is used for local backend so this is automatic
            if process.__class__.__name__ == "DummyProcess":
                self.df = self.df.caiman.reload_from_disk()
    #%% Properties
    @property
    def params_mcorr(self):
        params_mcorr ={
            "main":
            {
                "gSig_filt": (3, 3), # a gSig_filt value that brings out "landmarks" in the movie
                "pw_rigid": True,
                "max_shifts": (5, 5),
                "strides": (48, 48),
                "overlaps": (24, 24),
                "max_deviation_rigid": 3,
                "border_nan": "copy",
                }
            }
        return params_mcorr
    @property
    def params_cnmfe(self):
        params_cnmfe ={
            "main":
            {
                'method_init': 'corr_pnr',  # use this for 1 photon
                'K': None,
                'gSig': (self.gSig, self.gSig),
                'gSiz': (4 * self.gSig + 1, 4 * self.gSig + 1),
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
                'min_corr': self.min_corr,             # min correlation of peak (from PNR) value to accept a component
                'min_pnr': self.min_pnr,               # min peak to noise ratio to accept a component
            }
        }
        return params_cnmfe
