library(tidyverse)

# given two SYN/ACKS and the location of the FIN/ACK, extract all relevant information
# that occured before and after the FIN/ACK, giving us insight into the behavior and
# closure of the TCP connection
write_flow_units <- function(df, post_fin_df) {
  tcp_pre_fin_unit <- df %>%
    summarize(numPackets = n(),
              avg_window_size = sum(tcp.window_size)/n(),
              avg_TCP_delta= sum(tcp.time_delta)/n(),
              avg_bytes_in_flight = sum(tcp.analysis.bytes_in_flight)/n(),
              avg_pushBytesSent = sum(tcp.analysis.push_bytes_sent)/n(),
              avg_iRTT = sum(tcp.analysis.initial_rtt)/n(),
              avg_ack_RTT = sum(tcp.analysis.ack_rtt)/n(),
              avg_tcp_length = sum(tcp.len)/n(),
              avg_AckLostSegments = sum(tcp.analysis.ack_lost_segment)/n(),
              avg_LostSegments = sum(tcp.analysis.lost_segment)/n(),
              avg_OutOfOrders = sum(tcp.analysis.out_of_order)/n(),
              avg_DupAcks = sum(tcp.analysis.duplicate_ack)/n(),
              avg_Resets = sum(tcp.flags.reset)/n(),
              num_Resets = sum(tcp.flags.reset),
              avg_Retransmissions = sum(tcp.analysis.retransmission)/n(),
              avg_KA_acks = sum(tcp.analysis.keep_alive_ack)/n(),
              avg_KAs = sum(tcp.analysis.keep_alive)/n(),
              avg_WindowUpdates = sum(tcp.analysis.window_update)/n())
  
  source_ip <- df$ip.src[1]
  addr_ip <- df$ip.dst[1]
  
  ip_info <- data.frame("ip_source" = c(source_ip), "ip_addr" = c(addr_ip))
  
  tcp_post_fin_unit <- post_fin_df %>%
    summarize(post_fin_resets = sum(tcp.flags.reset)) # sums the number of TCP resets
                                                      # post FIN/ACK
  
  tcp_flow_unit <- cbind(tcp_pre_fin_unit,tcp_post_fin_unit)
  tcp_flow_unit <- cbind(tcp_flow_unit,ip_info)
  return(tcp_flow_unit)
}

# given a set of packets exchanged between two IP addresses, find all TCP connections
# between them and send them to write_flow_units() to be turned into observational units, i.e.
# to extract relevant information
IP_flow <- function(df) {
  current_flow_df <- data.frame()
  
  previous_syn_ack <- 0
  seen_syn_ack_yet <- 0
  
  first_fin <- 0
  seen_fin <- 0
  
  for (i in 1:nrow(df)) { # loop through the set of packets
    if (df$tcp.flags.syn[i] == 1) { # if you see a syn/ack
      if (seen_syn_ack_yet == 1) {
        if (i-previous_syn_ack < 5) { # if the TCP connection is less than five packets
          previous_syn_ack <- i
          seen_fin <- 0
        } else{
          tcp_subset <- df[previous_syn_ack:(i-1),] # makes a subset of packets that corresponds
                                                    # with the previous SYN/ACK seen and the one
                                                    # you just saw.
          post_fin_subset <- df[first_fin:(i-1),] # makes a subset of packets after the FIN/ACK
                                                  # but before the most recent SYN/ACK
          
          current_unit <- write_flow_units(tcp_subset, post_fin_subset) # extracts information
          current_flow_df <- rbind(x=current_flow_df,y=current_unit) # adds new observational
                                                  # units to the growing count
          
          previous_syn_ack <- i # updates the index of the most recent SYN/ACK
          seen_fin <- 0 # acknowledge that you haven't seen a FIN/ACK in the current TCP connection
        }
      } else {
        previous_syn_ack <- i
        seen_syn_ack_yet <- 1
      }
    }
    if (df$tcp.flags.fin[i] == 1 & seen_fin == 0) { # this records that you have seen a FIN/ACK
                                                    # in this connection
      first_fin <- i
      seen_fin <- 1
    }
  }
  return(current_flow_df)
}

# Reads in a .csv file of TCP packets. The goal of this script is to take a set of TCP packets
# from many different hosts and output a .csv file of TCP connections as observational units. Each
# observational unit would contain all of the relevant information from a TCP connection.
tabular_data <- read.csv(file="tcp_12_17_5.csv", header=TRUE, sep=",", stringsAsFactors=FALSE)
tabular_data[is.na(tabular_data)] <- 0 # replaces NA values with zeros

flows_df <- data.frame()

ips <- unique(tabular_data$ip.src) # makes a list of unique IP addresses present in this trace
combs <- combn(ips, 2)             # finds all combinations of two IP addresses so that we can
                                   # filter by interactions between two hosts
for (i in 1:ncol(combs)) {
  ip1 <- combs[1,i]
  ip2 <- combs[2,i]
  current_tcp_sample <- tabular_data %>%
    filter((ip.src == ip1 & ip.dst == ip2) | (ip.src == ip2 & ip.dst == ip1))
  if (nrow(current_tcp_sample) > 5) {
    set_of_flows <- IP_flow(current_tcp_sample) # given a set of interactions between two hosts,
                                                # this function will extract all TCP connections
                                                # them
    flows_df <- rbind(x=flows_df,y=set_of_flows) # row binds the set of connections to the growing
                                                 # set of observational units
  }
}

write.csv(flows_df, file = "tcp_12_17_5_units.csv")
  
  
  