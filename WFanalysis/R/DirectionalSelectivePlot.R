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
library(ggrepel)

#%% read in the data

df <- read.csv("1.csv")

#%% bar plot of eightDirPD, add count and percentage labels convert it to polar plot

df %>%
  filter(goodResp == 2) %>%
  filter(!is.na(eightDirPD)) %>%
  mutate(eightDirPD = factor(eightDirPD, levels = c(0, 45, 90, 135, 180, 225, 270, 315)))%>%
  ggplot(aes(x = eightDirPD, fill = eightDirPD)) +
  geom_vline(aes(xintercept = gaussianPD), color = "grey")+
  geom_bar(width =1) +
  scale_x_discrete(drop = FALSE) +
  geom_text(stat = "count", aes(label = stat(count), y = stat(count) + 1), vjust = -0.5) +
  geom_text(stat = "count", aes(label = paste0(round(stat(count)/sum(stat(count))*100, 1), "%"), y = stat(count) + 1), vjust = 1.5) +
  coord_polar(start = 4.35, direction = -1) +
  theme_minimal() +
  theme(legend.position = "none") +
  labs(title = "Distribution of Eight Directional Preference S2376",
       x = "Eight Directional Preference",
       y = "Count") +
  scale_y_continuous(limit = c(0, 58)) 

#%% hist of gaussian PD and plot as bar plot
df %>%
  filter(goodResp == 2) %>%
  filter(!is.na(gaussianWidth)) %>%
  mutate(gaussianWidth = ifelse(gaussianWidth > 250, 250, gaussianWidth)) %>%
  ggplot(aes(x = gaussianWidth, fill = gaussianWidth)) +
  geom_bar(width = 0.8) +
  scale_x_binned(breaks = seq(0, 360, 10), limits = c(0, 250)) +
  theme_pubr() 



df %>%
  filter(goodResp == 2) %>%
  filter(!is.na(gaussianPD)) %>%
  mutate(gaussianPD = ifelse(gaussianPD > 360, gaussianPD - 360, gaussianPD)) %>%
  mutate(gaussianPD = ifelse(gaussianPD < 0, gaussianPD + 360, gaussianPD)) %>%
  ggplot(aes(x = gaussianPD)) +
  geom_vline(aes(xintercept = gaussianPD), color = "grey") +
  geom_histogram(aes(y = ..count..),breaks = seq(0, 360, 30), color = "black", fill = NA) +
  coord_polar(start = 4.7, direction = -1) +
  scale_x_continuous(breaks = seq(0, 360, 45))
           
           

