import os
import sys
import matplotlib.pyplot as plt
import pandas as pd

base = os.getcwd() + '/' + sys.argv[1]

app = sys.argv[1].split('/')[2]
problem = sys.argv[1].split('/')[3]
func = sys.argv[1].split('/')[4]

arch = sys.argv[2]

subdirs = [x[0] for x in os.walk(base) if x[0] != base]

df = pd.DataFrame(columns=['ranks', 'pattern', 'Total Bandwidth (MB/s)', 'Average Bandwidth per Rank (MB/s)', 'Type'])

pfile = os.getcwd() + '/patterns/' + app + '/' + problem + '/' + func + '.json'

gs_types = os.popen("cat " + pfile + " | grep -o -P 'kernel.{0,20}'| grep -o 'Gather\|Scatter' ").read()
gs_types = gs_types.split('\n')

rank_set = set()
pattern_set = set()
for d in subdirs:
    f_list = [os.path.join(d, x) for x in os.listdir(d) if os.path.isfile(os.path.join(d, x))]
    
    for f in f_list:
        ranks = int(d.split('/')[-1][:-1])
        pattern = int(f.split('/')[-1].split('_')[-1][:-5])

        rank_set.add(ranks)
        pattern_set.add(pattern)
        
        gs_type = gs_types[pattern]

        df_tmp = pd.read_csv(f, header=None)
        df_tmp = df_tmp.astype(float)
        row = [ranks, pattern, df_tmp[0].sum(), df_tmp[0].mean(), gs_type]

        df.loc[len(df)] = row

plt.figure()

for p in pattern_set:

    sub_df = df.loc[df['pattern'] == p]
    ranks = list(sub_df['ranks'])
    totals = list(sub_df['Total Bandwidth (MB/s)'])

    ranks, totals = zip(*sorted(zip(ranks, totals)))

    if list(sub_df['Type'])[0] == 'Gather':
        marker = '-o'
    else:
        marker = '--o'
            
    plt.plot(ranks, totals, marker,  label='Pattern ' + str(p))

plt.xlabel('Ranks')
plt.ylabel('Total Bandwidth (MB/s)')
plt.title(app + ', ' + problem + ': Gather/Scatter Total Bandwidths (' + arch + ')')

plt.legend()

plt.savefig(os.getcwd() + '/figures/' + arch + '/' + app + '/' + problem + '/' + func + '/total.png', bbox_inches='tight')


plt.figure()

for p in pattern_set:

    sub_df = df.loc[df['pattern'] == p]
    ranks = list(sub_df['ranks'])
    averages = list(sub_df['Average Bandwidth per Rank (MB/s)'])

    ranks, averages = zip(*sorted(zip(ranks, averages)))

    if list(sub_df['Type'])[0] == 'Gather':
        marker = '-o'
    else:
        marker = '--o'
            
    plt.plot(ranks, averages, marker,  label='Pattern ' + str(p))

plt.xlabel('Ranks')
plt.ylabel('Average Bandwidth per Rank (MB/s)')
plt.title(app + ', ' + problem + ': Gather/Scatter Average Bandwidth per Rank (' + arch + ')')

plt.legend()

plt.savefig(os.getcwd() + '/figures/' + arch + '/' + app + '/' + problem + '/' + func + '/average.png', bbox_inches='tight')
