# Los Alamos National Laboratory
# Author: Jered Dominguez-Trujillo

import json
import sys
import matplotlib.pyplot as plt
import numpy as np


def main():
    fname = sys.argv[1]
    outname1 = fname.replace('json', 'png')
    outname1 = outname1.replace('/', '_')
    outname2 = 'delta_' + outname1
    outname3 = 'hist_' + outname1

    with open(fname) as json_file:
        data = json.load(json_file)

    if len(data) > 1:
        nrows = 2
        ncols = int(np.ceil((len(data) / 2)))

    fig1, axes1 = plt.subplots(nrows=nrows, ncols=ncols, figsize=(ncols * 8, nrows * 5), squeeze=False)
    fig2, axes2 = plt.subplots(nrows=nrows, ncols=ncols, figsize=(ncols * 8, nrows * 5), squeeze=False)
    fig3, axes3 = plt.subplots(nrows=nrows, ncols=ncols, figsize=(ncols * 8, nrows * 5), squeeze=False)

    for i, item in enumerate(data):
        pattern = [int(val) for val in item["pattern"]]
        axes1[int(i / ncols), i % ncols].plot(list(range(0, len(pattern))), pattern)
        axes1[int(i / ncols), i % ncols].set_xlabel("Index")
        axes1[int(i / ncols), i % ncols].set_ylabel("Pattern Value")

        delta = np.diff(pattern)
        axes2[int(i / ncols), i % ncols].plot(list(range(0, len(delta))), delta)
        axes2[int(i / ncols), i % ncols].set_xlabel("Index")
        axes2[int(i / ncols), i % ncols].set_ylabel("Pattern Delta")

        axes3[int(i / ncols), i % ncols].hist(delta, bins=50)
        axes3[int(i / ncols), i % ncols].set_xlabel("Pattern Delta")
        axes3[int(i / ncols), i % ncols].set_ylabel("# of Occurrences")

    fig1.suptitle(fname.split('/'), fontsize=24)
    fig1.savefig(outname1, bbox_inches='tight')

    fig2.suptitle(fname.split('/'), fontsize=24)
    fig2.savefig(outname2, bbox_inches='tight')

    fig3.suptitle(fname.split('/'), fontsize=24)
    fig3.savefig(outname3, bbox_inches='tight')

if __name__ == "__main__":
    main()
