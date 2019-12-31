# coding: utf-8
import sys
import pandas as pd
import json

# This script parses wireshark JSON data and outputs observational units. We did not end
# up using this script because the JSON files ended up being 400+ MB even when the wireshark
# traces were only 30 MB or so, but we are submitting it because this was part of the work
# that we did.

if len(sys.argv) < 2:
    print('Enter file name')
    sys.exit()
else:
    with open(sys.argv[1], 'r') as f:
        data = json.load(f)

def extract(data):
    row = {}
    
    row['ip_source'] = data['_source']['layers']['ip']['ip.src']
    row['ip_addr'] = data['_source']['layers']['ip']['ip.addr']

    row['tcp_winsize'] = data['_source']['layers']['tcp']['tcp.window_size_value']
    
    if 'tcp.analysis' in data['_source']['layers']['tcp'].keys():
    
        if 'tcp.analysis.payload' in data['_source']['layers']['tcp']['tcp.analysis'].keys():
            row['tcp_payload'] = data['_source']['layers']['tcp']['tcp.analysis']['tcp.analysis.payload']
        else:
            row['tcp_payload'] = 0

        if 'tcp.analysis.bytes_in_flight' in data['_source']['layers']['tcp']['tcp.analysis'].keys():
            row['tcp_analysis_bytesInFlight'] = data['_source']['layers']['tcp']['tcp.analysis']['tcp.analysis.bytes_in_flight']
        else:
            row['tcp_analysis_bytesInFlight'] = 0

        if 'tcp.analysis.push_bytes_sent' in data['_source']['layers']['tcp']['tcp.analysis'].keys():
            row['tcp_analysis_pushBytesSent'] = data['_source']['layers']['tcp']['tcp.analysis']['tcp.analysis.push_bytes_sent']
        else:
            row['tcp_analysis_pushBytesSent'] = 0    

        if 'tcp.analysis.initial_rtt' in data['_source']['layers']['tcp']['tcp.analysis'].keys():
            row['tcp_analysis_initialRTT'] = data['_source']['layers']['tcp']['tcp.analysis']['tcp.analysis.initial_rtt']
        else:
            row['tcp_analysis_initialRTT'] = 0

        if 'tcp.time_delta' in data['_source']['layers']['tcp']['Timestamps'].keys():
            row['tcp_time_delta'] = data['_source']['layers']['tcp']['Timestamps']['tcp.time_delta']
        else:
            row['tcp_time_delta'] = 0


    # Extract boolean values from strings in the 'Info' column
    tcp_key = data['_source']['layers']['tcp']

    # SYN ACKs
    try:
        if '_ws.expert.message' in tcp_key['tcp.flags_tree']['tcp.flags.syn_tree']['_ws.expert'].keys():
            if tcp_key['tcp.flags_tree']['tcp.flags.syn_tree']['_ws.expert']['_ws.expert.message'] == "Connection establish acknowledge (SYN+ACK): server port 443":
                row['syn_ack'] = 1
            else:
                row['syn_ack'] = 0
    except KeyError:
        row['syn_ack'] = 0

    # ACK to KAs, KAs, prev_not_captures, and retransmissions
    try:
        if '_ws.expert.message' in tcp_key['tcp.analysis']['tcp.analysis.flags']['_ws.expert'].keys():
            if tcp_key['tcp.analysis']['tcp.analysis.flags']['_ws.expert']['_ws.expert.message'] == "ACK to a TCP keep-alive segment":
                row['ka_ack'] = 1
            else:
                row['ka_ack'] = 0
            if tcp_key['tcp.analysis']['tcp.analysis.flags']['_ws.expert']['_ws.expert.message'] == "TCP keep-alive segment":
                row['ka'] = 1
            else:
                row['ka'] = 0
            if tcp_key['tcp.analysis']['tcp.analysis.flags']['_ws.expert']['_ws.expert.message'] == "Previous segment(s) not captured (common at capture start)":
                row['prev_nc'] = 1
            else:
                row['prev_nc'] = 0
            if tcp_key['tcp.analysis']['tcp.analysis.flags']['_ws.expert']['_ws.expert.message'] == "This frame is a (suspected) retransmission":
                row['retrans'] = 1
            else:
                row['retrans'] = 0
    except KeyError:
        row['ka_ack'] = 0
        row['ka'] = 0
        row['prev_nc'] = 0
        row['retrans'] = 0

    # Dup Acks
    try:
        if 'tcp.analysis.duplicate_ack' in tcp_key['tcp.analysis']['tcp.analysis.duplicate_ack_frame_tree']['_ws.expert'].keys():
            row['dup_ack'] = 1
        else:
            row['dup_ack'] = 0
    except KeyError:
        row['dup_ack'] = 0

    # TCP resets
    try:
        if '_ws.expert.message' in tcp_key['tcp.flags_tree']['tcp.flags.reset_tree']['_ws.expert'].keys():
            if tcp_key['tcp.flags_tree']['tcp.flags.reset_tree']['_ws.expert']['_ws.expert.message'] == "Connection reset (RST)":
                row['con_reset'] = 1
            else:
                row['con_reset'] = 0
    except KeyError:
        row['con_reset'] = 0


    else:
            row['tcp_payload'] = 0
            row['tcp_analysis_bytesInFlight'] = 0
            row['tcp_analysis_pushBytesSent'] = 0
            row['tcp_analysis_initialRTT'] = 0
            
    for flagName in data['_source']['layers']['tcp']['tcp.flags_tree'].keys():
        if flagName != "tcp.flags.syn_tree" and flagName != 'tcp.flags.str':
            row[flagName] = data['_source']['layers']['tcp']['tcp.flags_tree'][flagName]
        
    return row
    
df = pd.DataFrame([extract(data[0])], columns=extract(data[0]).keys())

for j in data[1:]:
        df = df.append(extract(j), ignore_index = True) 

df.to_csv(str(sys.argv[1])+'-tabular.csv')

df = pd.read_csv('./networks_sample.csv')
df.dtypes