from collections import defaultdict

def parse_file(fname: str):
    lines = []
    with open(fname) as f: lines = f.readlines()
    
    result = {}
    current_p = None
    current_n = None
    
    for line in lines:
        parts = line.strip().split()
        if not parts:
            continue
        
        if parts[0] == "P":
            current_p = parts[1]
            result[current_p] = {}
        
        elif parts[0] == "N":
            current_n = int(parts[1])
            result[current_p][current_n] = defaultdict(lambda: defaultdict(list))
        
        elif parts[0] == "r":
            r_type = parts[1]
            measures = parts[2:]
            for m in measures:
                key, val = m.split(":")
                result[current_p][current_n][r_type][key].append(int(val))
    
    final_result = {}
    for p, n_dict in result.items():
        final_result[p] = {}
        for n, r_dict in n_dict.items():
            final_result[p][n] = {}
            for r_type, measures in r_dict.items():
                final_result[p][n][r_type] = {
                    k: sum(v)/len(v) for k, v in measures.items()
                }
    
    return final_result


parsed = parse_file("./result.txt")
print(parsed)
