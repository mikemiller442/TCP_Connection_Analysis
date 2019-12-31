csv_list = c("henry_1_units.csv", "henry_2_units.csv", "michael_trace_12_10_units.csv",
             "uncommon_trace_units.csv", "nh1_units.csv", "tcp_12_10_nick_units.csv",
             "henry_trace_12_11_units.csv", "michael_trace_12_17_units.csv",
             "tcp_12_17_3_units.csv", "tcp_12_17_4_units.csv", "tcp_12_17_5_units.csv")

final_tcp <- data.frame() # initializes csv before row-binding all of our previous
						  # observational units into one final data set

for (i in csv_list) {
  temp_csv <- read.csv(file = i, header = TRUE, sep = ",")
  final_tcp <- rbind(final_tcp, temp_csv) # row binds a set of observational units into the data set
}

write.csv(final_tcp, file = "TCP_dataset3.csv") # writes the final data set as a .csv file
