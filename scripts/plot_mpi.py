# Los Alamos National Laboratory
# Author: Jered Dominguez-Trujillo

import os
import sys
import csv
import matplotlib.pyplot as plt
import pandas as pd

def generate_scaling(base, app, problem, func, nonfp, fp, arch, subdirs, pfile, gs_types):
    df = pd.DataFrame(columns=['ranks', 'bytes', 'pattern', 'Total Bandwidth (MB/s)', 'Average Bandwidth per Rank (MB/s)', 'Type'])

    rank_set = set()
    pattern_set = set()
    for d in subdirs:
        f_list = [os.path.join(d, x) for x in os.listdir(d) if os.path.isfile(os.path.join(d, x))]
    
        for f in f_list:
            if "bytes" not in f:
                fbytes = f + ".bytes"
                size_bytes = pd.read_csv(fbytes, header=None)[0]

                ranks = int(d.split('/')[-1][:-1])
                pattern = int(f.split('/')[-1].split('_')[-1][:-5])

                rank_set.add(ranks)
                pattern_set.add(pattern)
        
                gs_type = gs_types[pattern]

                df_tmp = pd.read_csv(f, header=None)
                df_tmp = df_tmp.astype(float)
                row = [ranks, size_bytes, pattern, df_tmp[0].sum(), df_tmp[0].mean(), gs_type]

                df.loc[len(df)] = row

    return df, pattern_set

    
def generate_throughput(base, app, problem, func, nonfp, fp, arch, subdirs, pfile, gs_types):
    df = pd.DataFrame(columns=['ranks', 'megabytes', 'count', 'pattern', 'Total Bandwidth (MB/s)', 'Average Bandwidth per Rank (MB/s)', 'Type'])

    ranks_list = []
    count_list = []
    pattern_set = set()
    for d in subdirs:
        f_list = [os.path.join(d, x) for x in os.listdir(d) if os.path.isfile(os.path.join(d, x))]
    
        for f in f_list:
            if "bytes" not in f:
                fbytes = f + ".bytes"
                size_megabytes = pd.read_csv(fbytes, header=None)[0].sum() / 1000000.0

                ranks = int(d.split('/')[-1][:-1]) 
                count = int(f.split('/')[-1].split('_')[-3][:-1])
                pattern = int(f.split('/')[-1].split('_')[-1][:-5])

                ranks_list.append(ranks)
                count_list.append(count)
                pattern_set.add(pattern)
        
                gs_type = gs_types[pattern]

                df_tmp = pd.read_csv(f, header=None)
                df_tmp = df_tmp.astype(float)
                row = [ranks, size_megabytes, count, pattern, df_tmp[0].sum(), df_tmp[0].mean(), gs_type]

                df.loc[len(df)] = row

    return df, pattern_set


def generate_plots(throughput, scaling, df, pattern_set, base, app, problem, func, nonfp, fp, arch, key, xlab, ctitle1, ctitle2):
    plt.figure()

    with open(base + '/total.csv', 'w', newline='') as tfile:
        totalwriter = csv.writer(tfile)
        for pid, p in enumerate(pattern_set):
            sub_df = df.loc[df['pattern'] == p]
            xvals = list(sub_df[key])
            totals = list(sub_df['Total Bandwidth (MB/s)'])

            xvals, totals = zip(*sorted(zip(xvals, totals)))

            if pid == 0:
                totalwriter.writerow(['Pattern'] + list(xvals))
                tfile.flush()

            rounded_totals = [round(val, 2) for val in totals]
            totalwriter.writerow([p] + rounded_totals)
            tfile.flush()
 
            if list(sub_df['Type'])[0] == 'Gather':
                marker = '-o'
            else:
                marker = '--o'
            
            plt.plot(xvals, totals, marker,  label='Pattern ' + str(p))

    if throughput:
        plt.xscale('log', base=2)

    plt.xlabel(xlab)
    plt.ylabel('Total Bandwidth (MB/s)')

    if fp:
        plt.title(app + ', ' + problem + ': FP Gather/Scatter ' + ctitle1 + ' (' + arch + ')', y=1.1)
    elif nonfp:
        plt.title(app + ', ' + problem + ': Non-FP Gather/Scatter ' + ctitle1 + ' (' + arch + ')', y=1.1)
    else:
        plt.title(app + ', ' + problem + ': Gather/Scatter ' + ctitle1 + ' (' + arch + ')', y=1.1)

    plt.legend()

    plt.savefig(os.getcwd() + '/figures/' + scaling + '/' + arch + '/' + app + '/' + problem + '/' + func + '/total.png', bbox_inches='tight')


    if (not throughput):
        plt.figure()

        with open(base + '/average.csv', 'w', newline='') as afile:
            averagewriter = csv.writer(afile)
            for count, p in enumerate(pattern_set):
                sub_df = df.loc[df['pattern'] == p]
                xvals = list(sub_df[key])
                averages = list(sub_df['Average Bandwidth per Rank (MB/s)'])

                xvals, averages = zip(*sorted(zip(xvals, averages)))

                if count == 0:
                    averagewriter.writerow(['Pattern'] + list(xvals))
                    afile.flush()

                rounded_averages = [round(val, 2) for val in averages]
                averagewriter.writerow([p] + rounded_averages)
                afile.flush() 

                if list(sub_df['Type'])[0] == 'Gather':
                    marker = '-o'
                else:
                    marker = '--o'
            
                plt.plot(xvals, averages, marker,  label='Pattern ' + str(p))

        plt.xlabel(xlab)
        plt.ylabel('Average Bandwidth per Rank (MB/s)')
        if fp:
            plt.title(app + ', ' + problem + ': FP Gather/Scatter ' + ctitle2 + ' (' + arch + ')', y=1.1)
        elif nonfp:
            plt.title(app + ', ' + problem + ': Non-FP Gather/Scatter ' + ctitle2 + ' (' + arch + ')', y=1.1)
        else:
            plt.title(app + ', ' + problem + ': Gather/Scatter ' + ctitle2 + ' (' + arch + ')', y=1.1)

        plt.legend()

        plt.savefig(os.getcwd() + '/figures/' + scaling + '/' + arch + '/' + app + '/' + problem + '/' + func + '/average.png', bbox_inches='tight')


def main():
    base = os.getcwd() + '/' + sys.argv[1]

    app = sys.argv[1].split('/')[2]
    problem = sys.argv[1].split('/')[3]
    func = sys.argv[1].split('/')[4]

    nonfp = False
    fp = False
    if 'fp' in func:
        fp = True
    if 'nonfp' in func:
        fp = False
        nonfp = True

    arch = sys.argv[2]
    weakscaling = int(sys.argv[3])
    throughput = int(sys.argv[4])

    if weakscaling == 0:
        scaling = 'spatter.strongscaling'
    else:
        scaling = 'spatter.weakscaling'

    subdirs = [x[0] for x in os.walk(base) if x[0] != base]

    pfile = os.getcwd() + '/datafiles/' + app + '/' + problem + '/' + func + '.json'

    gs_types = os.popen("cat " + pfile + " | grep -o -P 'kernel.{0,20}'| grep -o 'Gather\|Scatter' ").read()
    gs_types = gs_types.split('\n')


    if throughput == 0:
        print("Generating Scaling Plots")
        sdf, pattern_set = generate_scaling(base, app, problem, func, nonfp, fp, arch, subdirs, pfile, gs_types)
        generate_plots(throughput, scaling, sdf, pattern_set, base, app, problem, func, nonfp, fp, arch, 'ranks', 'Ranks', 'Total Bandwidths', 'Average Bandwidth per Rank')
    else:
        print("Generating Throughput Plots")
        tdf, pattern_set = generate_throughput(base, app, problem, func, nonfp, fp, arch, subdirs, pfile, gs_types)
        generate_plots(throughput, scaling, tdf, pattern_set, base, app, problem, func, nonfp, fp, arch, 'megabytes', 'MB Transferred', 'Throughput', '')

if __name__ == "__main__":
    main()
