library(tidyverse)
library(ggplot2)
library(ggpubr)
library(psych)
library(patchwork)
# Load the data
data <- read.csv("wheelRunAnalysis.csv") %>%
  mutate(sessionType = ifelse(trialNum  > 100, "Weekend", "Workday")) %>%
  mutate(session = as.factor(session)) %>%
  group_by(sessionType) %>%
  mutate(sessionID = row_number())

# Plot the running distance
p1 <- data %>%
  filter(sessionType == "Workday") %>%
  mutate(wheelRunDist = wheelRunDist/5) %>% # 5 mice in the cage
  ggplot(aes(x = sessionID, y = wheelRunDist, group = 1)) +
  geom_line(linewidth = 1) +
  geom_point(shape=21, fill="black", size=4)+
  labs(title = "Wheel Running Distance (Workday)",
       x = "Session",
       y = "Wheel running distance (km)") +
  scale_x_continuous(breaks = seq(0, 30, 5)) +
  scale_y_continuous(limits = c(0, 7), breaks = seq(0, 7, 1)) +
  theme_pubr()

p2<- data %>%
  filter(sessionType == "Weekend") %>%
  mutate(wheelRunDist = wheelRunDist/5/2) %>% # 5 mice in the cage for 2 days
  ggplot(aes(x = sessionID, y = wheelRunDist, group = 1)) +
  geom_line(linewidth = 1) +
  geom_point(shape=21, fill="black", size=4)+
  labs(title = "Wheel Running Distance (Weekend)",
       x = "Session",
       y = "Distance (km)") +
  scale_x_continuous(breaks = seq(0, 8, 1)) +
  scale_y_continuous(limits = c(0, 7), breaks = seq(0, 7, 1)) +
  theme_pubr()

# Plot the runing speed
data %>%
  filter(sessionType == "Weekend") %>%
  ggplot(aes(x = sessionID, y = wheelRunSpeed, group = 1)) +
  geom_line(linewidth = 1) +
  geom_point(shape=21, fill="black", size=4)+
  labs(title = "Wheel Running Speed (Workday)",
       x = "Session",
       y = "Speed (km/h)") +
  scale_x_continuous(breaks = seq(0, 8,1)) +
  scale_y_continuous(limits = c(0, 3), breaks = seq(0, 3, 0.5)) +
  theme_pubr()

# statistical results of wheel running
dataNew <- data %>%
  mutate(wheelRunDistPerMousePerDay = ifelse(sessionType == "Workday", wheelRunDist/5, wheelRunDist/5/2)) %>% # 5 mice in the cage, 1 day for workday, 2 days for weekend
  mutate(wheelRunDurationPerMousePerDay = ifelse(sessionType == "Workday", wheelRunDuration/5, wheelRunDuration/5/2)) # 5 mice in the cage, 1 day for workday, 2 days for weekend

# discriptive statistics
dataNew %>%
  describe()

p1|p2
