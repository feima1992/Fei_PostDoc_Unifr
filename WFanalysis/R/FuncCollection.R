# %% library import
library(tidyverse)
library(ggpubr)
library(ggsci)
library(rstatix)
library(ggh4x)
library(export)
library(ggeasy)
library(patchwork)
library(gridExtra)
library(scales)

# %% LoadActProps
LoadActProps <- function(filePath) {
    # load data from csv file
    data <- read.csv(filePath, header = TRUE, sep = ",") %>%
        mutate(Intensity = Area * MeanIntensity) %>%
        mutate(Area = Area * 0.018 * 0.018) %>%
        mutate(AreaSensory = AreaSensory * 0.018 * 0.018) %>%
        mutate(AreaMotor = AreaMotor * 0.018 * 0.018) %>%
        mutate(AreaNotSensoryMotor = AreaNotSensoryMotor * 0.018 * 0.018) %>%
        mutate(WeightedCentroid_1 = (WeightedCentroid_1 - 256) * 0.018) %>%
        mutate(WeightedCentroid_2 = (256 - WeightedCentroid_2) * 0.018) %>%
        mutate(LateralMost = (LateralMost - 256) * 0.018) %>%
        mutate(MedialMost = (MedialMost - 256) * 0.018) %>%
        mutate(AnteriorMost = (256 - AnteriorMost) * 0.018) %>%
        mutate(PosteriorMost = (256 - PosteriorMost) * 0.018) %>%
        mutate(SpanLateralMedial = SpanLateralMedial * 0.018) %>%
        mutate(SpanAnteriorPosterior = SpanAnteriorPosterior * 0.018) %>%
        filter(ComponentId == 1, FrameTime == 0.35)

    # define the training duration if have column "trainingDuration"
    if ("trainingDuration" %in% colnames(data)) {
        data <- data %>%
            mutate(trainingDuration = case_when(
                trainingDuration == "1week" ~ "Early",
                trainingDuration == "2week" ~ "Early",
                trainingDuration == "3week" ~ "Mid",
                trainingDuration == "4week" ~ "Mid",
                trainingDuration == "5week" ~ "Late",
                trainingDuration == "6week" ~ "Late",
                TRUE ~ ""
            )) %>%
            mutate(trainingDuration = factor(trainingDuration, levels = c("", "Early", "Mid", "Late")))
    }
    
    phase_names <- c("Baseline", "Post-Training", "Baseline", "parallel-control")
    new_phase_names <- c("Pre-\ntraining", "Post-\ntraining", "Control-\npre", "Control-\npost")
    # rename the phase if have column "phase"
    if ("phase" %in% colnames(data)) {
        data_trained <- data %>%
            filter(group == "Trained") %>%
            mutate(phase = case_when(phase == phase_names[1] ~ new_phase_names[1], phase == phase_names[2] ~ new_phase_names[2])) %>%
            mutate(phase = factor(phase, levels = new_phase_names[1:2]))
        data_untrained <- data %>%
            filter(group == "Untrained") %>%
            mutate(phase = case_when(phase == phase_names[3] ~ new_phase_names[3], phase == phase_names[4] ~ new_phase_names[4])) %>%
            mutate(phase = factor(phase, levels = new_phase_names[3:4]))
        data <- bind_rows(data_trained, data_untrained)
    }

    return(data)
}

# %% PlotActProps
PlotActProps <- function(df, y, ylabel = "") {
    # set y label if not provided
    if (ylabel == "") {
        ylabel <- y
    }

    # set y position for significance
    ymin <- min(df[[y]])
    ymax <- max(df[[y]])
    sig_yposition <- ymax + (ymax - ymin) * 0.1

    # set color values
    colorValues <- c("#E64B35FF", "#00A087FF")
    comparisons <- c(1,2)
    
    if ("phase" %in% colnames(df)) {
        x <- "phase"
    } else{
        x <- "group"
    }


    # plot
    fig <- df %>%
        ggplot(aes(x = get(x), y = get(y), color = get(x))) +
        geom_jitter(width = 0.08, size =1.5, alpha = 0.25,stroke = NA) +
        geom_signif(comparisons = list(levels(droplevels(df[[x]]))), y_position = sig_yposition, textsize = 4, test = t.test, color = "black") +
        stat_summary(fun = "mean", size = 3, geom = "point") +
        scale_color_manual(values = colorValues) +
        labs(x = "", y = ylabel) +
        labs_pubr() +
        theme_pubr() +
        easy_center_title() +
        easy_remove_legend() +
        scale_y_continuous(breaks = pretty_breaks(n = 5))+
        theme(axis.title.y = element_text(hjust = 0.5)) +
        theme(axis.text.x = element_text(hjust = 0.5))
    
    return(fig)
}

# %% PlotActProps for reaching and grasping training data
PlotActPropsRg <- function(df, y, ylabel = "", group = "group") {
    # split data frame by group
    figs <- list()
    if (group == "") {
        df <- list(df)
    } else {
        df <- group_split(df, group)
    }

    for (i in 1:length(df)) {
        figs[[i]] <- PlotActProps(df[[i]], y, ylabel)
    }

    # combine figures into a single row

    fig <- wrap_plots(figs, nrow = 1)

    return(fig)
}

# %% PlotActProps for reaching and grasping training data, training duration effect
PlotActPropsRgDevelop <- function(df, y, ylabel = "") {
    # set y label if not provided
    if (ylabel == "") {
        ylabel <- y
    }


    # set colors: gray, light red, medium red, dark red
    colorValues <- c("#999999", "#f1d2e3", "#f16bb5", "#e72020")

    # plot
    df <- df %>%
        filter(group == "Trained") %>%
        mutate(trainingDurationValue = case_when(trainingDuration == "Early" ~ 1,
                                           trainingDuration == "Mid" ~ 2,
                                           trainingDuration == "Late" ~ 3,
                                           TRUE ~ 0))

    df_mean <- df %>%
        group_by(trainingDuration, phase) %>%
        summarize(mean = mean(get(y), na.rm = TRUE), sem = sd(get(y), na.rm = TRUE) / sqrt(n()), .groups = "drop")
    
    # define y position for geom_signif
    ymin <- min(df_mean$mean, na.rm = TRUE)
    ymax <- max(df_mean$mean, na.rm = TRUE)
    y_position_base <- ymax + (ymax - ymin) * 0.1
    
    if (y_position_base > 0) {
        y_position <- y_position_base + (ymax - ymin) * c(0, 0.2, 0.4)
    } else {
        y_position <- y_position_base - (ymax - ymin) * c(0, -0.07, -0.14)
    }
    

    fig <- ggplot(data=df, aes(x = trainingDurationValue, y = get(y))) +
        geom_point(data=df_mean, aes(x = interaction(trainingDuration, phase), y = mean, shape = phase, color = trainingDuration), size = 3)+
        geom_errorbar(data=df_mean,aes(x = interaction(trainingDuration, phase), y = mean, ymin = mean - sem, ymax = mean + sem), width = 0.2) +
        stat_poly_line(data=df, aes(x = trainingDurationValue+1, y = get(y)), formula = y ~ x, method = "lm", se = TRUE, color = "black") +
        stat_poly_eq(use_label(c("eq", "adj.R2", "f", "p")), rr.digits=2, p.digits=2,coef.digits=2,output.type='expression') +
        geom_signif(data = df, aes(x = interaction(trainingDuration, phase), y = get(y)),comparisons = list(c(1, 2), c(1, 3), c(1, 4)), y_position = y_position, textsize = 4, test = t.test, color = "black") +
        scale_color_manual(values = colorValues) +
        labs(x = "", y = ylabel) +
        guides(x = "axis_nested") +
        labs_pubr() +
        theme_pubr() +
        easy_center_title() +
        easy_remove_legend() +
        scale_y_continuous(expand = expansion(mult = 0.2))

    return(fig)
}

# %% Figure of act props development as a function of training duration
FigureActPropsRgDevelop <- function(filePath, fileName = "fig") {
    # load data from csv file
    data <- LoadActProps(filePath)
    # plot the development of the activity properties
    figAreaDevelop <- PlotActPropsRgDevelop(df = data, y = "Area", ylabel = bquote("Largest component area "(mm^2)))
    figIntensityDevelop <- PlotActPropsRgDevelop(df = data, y = "Intensity", ylabel = "Intensity")
    figAreaSensoryDevelop <- PlotActPropsRgDevelop(df = data, y = "AreaSensory", ylabel = "Area Sensory")
    figIntensitySensoryDevelop <- PlotActPropsRgDevelop(df = data, y = "IntensitySensory", ylabel = "Intensity Sensory")
    figAreaMotorDevelop <- PlotActPropsRgDevelop(df = data, y = "AreaMotor", ylabel = "Area Motor")
    figIntensityMotorDevelop <- PlotActPropsRgDevelop(df = data, y = "IntensityMotor", ylabel = "Intensity Motor")
    figAreaNotSensoryMotorDevelop <- PlotActPropsRgDevelop(df = data, y = "AreaNotSensoryMotor", ylabel = "Area Not Sensory or Motor")
    figIntensityNotSensoryMotorDevelop <- PlotActPropsRgDevelop(df = data, y = "IntensityNotSensoryMotor", ylabel = "Intensity Not Sensory or Motor")
    figMLcentroidDevelop <- PlotActPropsRgDevelop(df = data, y = "WeightedCentroid_1", ylabel = bquote("Weighted centroid (ML) "(mm)))
    figAPcentroidDevelop <- PlotActPropsRgDevelop(df = data, y = "WeightedCentroid_2", ylabel = bquote("Weighted centroid (AP) "(mm)))
    figLateralMostDevelop <- PlotActPropsRgDevelop(df = data, y = "LateralMost", ylabel = bquote("Lateral position "(mm)))
    figMedialMostDevelop <- PlotActPropsRgDevelop(df = data, y = "MedialMost", ylabel = bquote("Medial position "(mm)))
    figAnteriorMostDevelop <- PlotActPropsRgDevelop(df = data, y = "AnteriorMost", ylabel = bquote("Anterior position "(mm)))
    figPosteriorMostDevelop <- PlotActPropsRgDevelop(df = data, y = "PosteriorMost", ylabel = bquote("Posterior position "(mm)))
    figSpanLateralMedialDevelop <- PlotActPropsRgDevelop(df = data, y = "SpanLateralMedial", ylabel = bquote("Span (Lateral-Medial) "(mm)))
    figSpanAnteriorPosteriorDevelop <- PlotActPropsRgDevelop(df = data, y = "SpanAnteriorPosterior", ylabel = bquote("Span (Anterior-Posterior) "(mm)))

    P1 <- (figAreaDevelop | figIntensityDevelop) /
        (figMLcentroidDevelop | figAPcentroidDevelop) + plot_annotation(tag_levels = "A")
    graph2ppt(x = P1, file = fileName, width = 7.8, height = 7.6, paper = "A4", orient = "portrait", center = TRUE, append = TRUE)

    P2 <- (figAreaSensoryDevelop | figIntensitySensoryDevelop) /
        (figAreaMotorDevelop | figIntensityMotorDevelop) /
        (figAreaNotSensoryMotorDevelop | figIntensityNotSensoryMotorDevelop) + plot_annotation(tag_levels = "A")
    graph2ppt(x = P2, file = fileName, width = 7.8, height = 11.4, paper = "A4", orient = "portrait", center = TRUE, append = TRUE)

    P3 <- (figLateralMostDevelop | figMedialMostDevelop) /
        (figAnteriorMostDevelop | figPosteriorMostDevelop) /
        (figSpanLateralMedialDevelop | figSpanAnteriorPosteriorDevelop) + plot_annotation(tag_levels = "A")
    graph2ppt(x = P3, file = fileName, width = 7.8, height = 11.4, paper = "A4", orient = "portrait", center = TRUE, append = TRUE)
    return(list(P1, P2, P3))
}

# %% Figure of act props for reaching and grasping training data
FigureActPropsRg <- function(filePath, fileName = "fig") {
    data <- LoadActProps(filePath2)

    figArea <- PlotActPropsRg(df = data, y = "Area", ylabel = "Area size of proprioceptive activation (mm2)")
    figIntensity <- PlotActPropsRg(df = data, y = "Intensity", ylabel = "Intensity of proprioceptive activation")

    figAreaSensory <- PlotActPropsRg(df = data, y = "AreaSensory", ylabel = bquote("Area sensory "(mm^2)))
    figIntensitySensory <- PlotActPropsRg(df = data, y = "IntensitySensory", ylabel = "Intensity sensory")

    figAreaMotor <- PlotActPropsRg(df = data, y = "AreaMotor", ylabel = bquote("Area motor "(mm^2)))
    figIntensityMotor <- PlotActPropsRg(df = data, y = "IntensityMotor", ylabel = "Intensity motor")

    figAreaNotSensoryMotor <- PlotActPropsRg(df = data, y = "AreaNotSensoryMotor", ylabel = bquote("Area not sensory or motor "(mm^2)))
    figIntensityNotSensoryMotor <- PlotActPropsRg(df = data, y = "IntensityNotSensoryMotor", ylabel = "Intensity not sensory or motor")

    figMLcentroid <- PlotActPropsRg(df = data, y = "WeightedCentroid_1", ylabel = bquote("Weighted centroid (ML) "(mm)))

    figAPcentroid <- PlotActPropsRg(df = data, y = "WeightedCentroid_2", ylabel = bquote("Weighted centroid (AP) "(mm)))

    figLateralPos <- PlotActPropsRg(df = data, y = "LateralMost", ylabel = bquote("Lateral position "(mm)))

    figMedialPos <- PlotActPropsRg(df = data, y = "MedialMost", ylabel = bquote("Medial position "(mm)))

    figAnteriorPos <- PlotActPropsRg(df = data, y = "AnteriorMost", ylabel = bquote("Anterior position "(mm)))

    figPosteriorPos <- PlotActPropsRg(df = data, y = "PosteriorMost", ylabel = bquote("Posterior position "(mm)))

    figExtendML <- PlotActPropsRg(df = data, y = "SpanLateralMedial", ylabel = bquote("ML extension "(mm)))

    figExtendAP <- PlotActPropsRg(df = data, y = "SpanAnteriorPosterior", ylabel = bquote("AP extension "(mm)))

    if ("Parallel-control" %in% data$phase) {
        P <- figArea / figIntensity + plot_annotation(tag_levels = "A")
        graph2ppt(x = P, file = fileName, width = 5, height = 6, paper = "A4", orient = "portrait", center = TRUE, append = TRUE)

        P <- figAreaSensory / figIntensitySensory + plot_annotation(tag_levels = "A")
        graph2ppt(x = P, file = fileName, width = 7.8, height = 7.6, paper = "A4", orient = "portrait", center = TRUE, append = TRUE)

        P <- figAreaMotor / figIntensityMotor + plot_annotation(tag_levels = "A")
        graph2ppt(x = P, file = fileName, width = 7.8, height = 7.6, paper = "A4", orient = "portrait", center = TRUE, append = TRUE)

        P <- figAreaNotSensoryMotor / figIntensityNotSensoryMotor + plot_annotation(tag_levels = "A")
        graph2ppt(x = P, file = fileName, width = 7.8, height = 7.6, paper = "A4", orient = "portrait", center = TRUE, append = TRUE)

        P <- figMLcentroid / figAPcentroid + plot_annotation(tag_levels = "A")
        graph2ppt(x = P, file = fileName, width = 7.8, height = 7.6, paper = "A4", orient = "portrait", center = TRUE, append = TRUE)

        P <- figLateralPos / figMedialPos + plot_annotation(tag_levels = "A")
        graph2ppt(x = P, file = fileName, width = 7.8, height = 7.6, paper = "A4", orient = "portrait", center = TRUE, append = TRUE)

        P <- figAnteriorPos / figPosteriorPos + plot_annotation(tag_levels = "A")
        graph2ppt(x = P, file = fileName, width = 7.8, height = 7.6, paper = "A4", orient = "portrait", center = TRUE, append = TRUE)

        P <- figExtendML / figExtendAP + plot_annotation(tag_levels = "A")
        graph2ppt(x = P, file = fileName, width = 7.8, height = 7.6, paper = "A4", orient = "portrait", center = TRUE, append = TRUE)
    } else {
        P <- (figArea | figIntensity) /
            (figMLcentroid | figAPcentroid) + plot_annotation(tag_levels = "A")
        graph2ppt(x = P, file = fileName, width = 5, height = 6, paper = "A4", orient = "portrait", center = TRUE, append = TRUE)

        P <- (figAreaSensory | figIntensitySensory) /
            (figAreaMotor | figIntensityMotor) /
            (figAreaNotSensoryMotor | figIntensityNotSensoryMotor) + plot_annotation(tag_levels = "A")
        graph2ppt(x = P, file = fileName, width = 7.8, height = 11.4, paper = "A4", orient = "portrait", center = TRUE, append = TRUE)

        P <- (figLateralPos | figMedialPos) /
            (figAnteriorPos | figPosteriorPos) /
            (figExtendML | figExtendAP) + plot_annotation(tag_levels = "A")
        graph2ppt(x = P, file = fileName, width = 7.8, height = 11.4, paper = "A4", orient = "portrait", center = TRUE, append = TRUE)
    }
}

# %% Figure of act props for enriched environment data
FigureActPropsEnrich <- function(filePath, fileName = fileName) {
    data <- LoadActProps(filePath)

    figArea <- PlotActProps(df = data, y = "Area", ylabel = "Area size of\nproprioceptive activation (mm2)")
    figIntensity <- PlotActProps(df = data, y = "Intensity", ylabel = "Intensity")

    figAreaSensory <- PlotActProps(df = data, y = "AreaSensory", ylabel = bquote("Area sensory "(mm^2)))
    figIntensitySensory <- PlotActProps(df = data, y = "IntensitySensory", ylabel = "Intensity sensory")

    figAreaMotor <- PlotActProps(df = data, y = "AreaMotor", ylabel = bquote("Area motor "(mm^2)))
    figIntensityMotor <- PlotActProps(df = data, y = "IntensityMotor", ylabel = "Intensity motor")

    figAreaNotSensoryMotor <- PlotActProps(df = data, y = "AreaNotSensoryMotor", ylabel = bquote("Area not sensory or motor "(mm^2)))
    figIntensityNotSensoryMotor <- PlotActProps(df = data, y = "IntensityNotSensoryMotor", ylabel = "Intensity not sensory or motor")

    figMLcentroid <- PlotActProps(df = data, y = "WeightedCentroid_1", ylabel = bquote("Weighted centroid (ML) "(mm)))

    figAPcentroid <- PlotActProps(df = data, y = "WeightedCentroid_2", ylabel = bquote("Weighted centroid (AP) "(mm)))

    figLateralPos <- PlotActProps(df = data, y = "LateralMost", ylabel = bquote("Lateral position "(mm)))

    figMedialPos <- PlotActProps(df = data, y = "MedialMost", ylabel = bquote("Medial position "(mm)))

    figAnteriorPos <- PlotActProps(df = data, y = "AnteriorMost", ylabel = bquote("Anterior position "(mm)))

    figPosteriorPos <- PlotActProps(df = data, y = "PosteriorMost", ylabel = bquote("Posterior position "(mm)))

    figExtendML <- PlotActProps(df = data, y = "SpanLateralMedial", ylabel = bquote("ML extension "(mm)))

    figExtendAP <- PlotActProps(df = data, y = "SpanAnteriorPosterior", ylabel = bquote("AP extension "(mm)))

    P <- (figArea | figIntensity) /
        (figMLcentroid | figAPcentroid) + plot_annotation(tag_levels = "A")
    graph2ppt(x = P, file = fileName, width = 7.8, height = 7.6, paper = "A4", orient = "portrait", center = TRUE, append = TRUE)

    P <- (figAreaSensory | figIntensitySensory) /
        (figAreaMotor | figIntensityMotor) /
        (figAreaNotSensoryMotor | figIntensityNotSensoryMotor) + plot_annotation(tag_levels = "A")
    graph2ppt(x = P, file = fileName, width = 7.8, height = 11.4, paper = "A4", orient = "portrait", center = TRUE, append = TRUE)



    P <- (figLateralPos | figMedialPos) /
        (figAnteriorPos | figPosteriorPos) /
        (figExtendML | figExtendAP) + plot_annotation(tag_levels = "A")
    graph2ppt(x = P, file = fileName, width = 7.8, height = 11.4, paper = "A4", orient = "portrait", center = TRUE, append = TRUE)
}
