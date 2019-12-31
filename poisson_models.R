library(pscl)
library(tidyverse)

tcp_data <- read.csv(file="TCP_dataset3.csv", header=TRUE, sep=",")
nrow(tcp_data)

tcp_data <- tcp_data %>%
  mutate(zero_RST_post_fin = post_fin_resets == 0) # makes an indicator variable of whether or not
                                                   # there were zero  TCP resets post FIN/ACK

# The code below fits a logistic regression model. GLM stands for generalized linear model, so in
# a nutshell this means that the log odds of zero TCP resets post FIN/ACK is a linear function of
# these predictors.
model1 <- glm(zero_RST_post_fin ~ avg_TCP_delta + avg_TCP_delta:avg_DupAcks + 
                avg_TCP_delta:avg_KAs + avg_TCP_delta:avg_iRTT + avg_ack_RTT + avg_TCP_delta:avg_iRTT + 
                avg_iRTT + avg_Retransmissions + avg_WindowUpdates + avg_ack_RTT +
                avg_KAs + avg_DupAcks, family = "binomial", data = tcp_data)

print(summary(model1))

# The code below fits a zero inflated poisson model. There are two parts: the first part accounts
# for the probability that there are zero TCP resets post FIN/ACK, and the second part predicts
# the number of poisson counts of TCP resets post FIN/ACK after accounting for the probability
# that there are zero.
model2 <- zeroinfl(formula = post_fin_resets ~ avg_TCP_delta + avg_TCP_delta:avg_DupAcks + 
                     avg_TCP_delta:avg_KAs + avg_TCP_delta:avg_iRTT + avg_TCP_delta:avg_iRTT + 
                     avg_iRTT + avg_WindowUpdates + avg_ack_RTT +
                     avg_KAs + avg_DupAcks | avg_TCP_delta + avg_TCP_delta:avg_DupAcks + 
                     avg_TCP_delta:avg_KAs + avg_TCP_delta:avg_iRTT + avg_ack_RTT + avg_TCP_delta:avg_iRTT + 
                     avg_iRTT + avg_Retransmissions + avg_WindowUpdates + avg_ack_RTT +
                     avg_KAs + avg_DupAcks, data = tcp_data)

print(summary(model2))

# The code below fits a zero inflated model exactly like the model above, but it uses a different
# probability called the negative binomial distribution. This allows the variance of the response
# to be larger than its mean, which would otherwise violate the assumptions of the poisson model.
# Standard errors are higher, so the model must be pruned down to reflect that we probably overfit
# before.
model3 <- zeroinfl(formula = post_fin_resets ~ avg_TCP_delta + avg_TCP_delta:avg_iRTT + 
                     avg_iRTT + avg_WindowUpdates + avg_DupAcks + 
                     avg_Retransmissions + avg_ack_RTT | avg_TCP_delta + avg_ack_RTT + avg_ack_RTT +
                     avg_KAs  + avg_TCP_delta:avg_KAs + avg_DupAcks, dist = "negbin", data = tcp_data)

print(summary(model3))


