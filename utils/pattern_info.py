# Los Alamos National Laboratory
# Author: Jered Dominguez-Trujillo

import csv
import json
import os
import sys
import matplotlib.pyplot as plt
import numpy as np

from scipy import stats


def create_fig(nrows, ncols):
    col_width = 8
    row_height = 5

    return plt.subplots(
        nrows=nrows,
        ncols=ncols,
        figsize=(ncols * col_width, nrows * row_height),
        squeeze=False,
    )


def line_plot(ax, data, xlabel, ylabel):
    ax.plot(list(range(0, len(data))), data)
    ax.set_xlabel(xlabel)
    ax.set_ylabel(ylabel)


def hist_plot(pattern_id, ax, data, nbins, xlabel, ylabel):
    cur_mean = np.mean(data)
    cur_std = np.std(data)

    if min(data) >= 0:
        xmin = cur_mean
        xmax = cur_mean + 4 * cur_std
    else:
        xmin = cur_mean - 2 * cur_std
        xmax = cur_mean + 2 * cur_std

    ax.hist(data, bins=nbins, density=True, range=[xmin, xmax])
    ax.set_xlabel(xlabel)
    ax.set_ylabel(ylabel)


def main():
    fname = sys.argv[1]
    fname_pattern = fname.replace("json", "png")
    fname_pattern = fname_pattern.replace("/", "_")
    fname_delta = "delta_" + fname_pattern
    fname_hist = "hist_" + fname_pattern
    fname_abs_hist = "abshist_" + fname_pattern

    fname_csv = "pattern_stats.csv"
    if (not os.path.isfile(fname_csv)) == True:
        with open(fname_csv, "a") as csvfile:
            header_writer = csv.writer(csvfile, delimiter=",")
            header_writer.writerow(
                [
                    "Filename",
                    "Pattern",
                    "Length (Pattern)",
                    "Min (Pattern)",
                    "Max (Pattern)",
                    "Min (Delta)",
                    "Max (Delta)",
                    "Mean (Delta)",
                    "Variance (Delta)",
                    "Skew (Delta)",
                    "Kurtosis (Delta)",
                    "Mean (Abs Delta)",
                    "Variance (Abs Delta)",
                    "Skew (Abs Delta)",
                    "Kurtosis (Abs Delta)",
                ]
            )

    with open(fname) as json_file:
        data = json.load(json_file)

    if len(data) > 1:
        nrows = 2
        ncols = int(np.ceil((len(data) / 2)))

    fig_pattern, ax_pattern = create_fig(nrows, ncols)
    fig_delta, ax_delta = create_fig(nrows, ncols)
    fig_hist, ax_hist = create_fig(nrows, ncols)
    fig_abs_hist, ax_abs_hist = create_fig(nrows, ncols)

    nbins = 50
    for i, item in enumerate(data):
        cur_row = int(i / ncols)
        cur_col = i % ncols

        pattern = [int(val) for val in item["pattern"]]
        line_plot(ax_pattern[cur_row, cur_col], pattern, "Index", "Pattern Value")

        delta = np.diff(pattern)
        line_plot(ax_delta[cur_row, cur_col], delta, "Index", "Pattern Delta")

        with open(fname_csv, "a") as csvfile:
            stats_writer = csv.writer(csvfile, delimiter=",")
            pattern_stats = [fname, i]

            description = stats.describe(delta)[2:]
            abs_description = stats.describe(np.abs(delta))[2:]

            pattern_stats.extend(
                [
                    len(pattern),
                    np.min(pattern),
                    np.max(pattern),
                    np.min(delta),
                    np.max(delta),
                ]
            )
            pattern_stats.extend([val for val in description])
            pattern_stats.extend([val for val in abs_description])

            stats_writer.writerow(pattern_stats)

        hist_plot(
            i, ax_hist[cur_row, cur_col], delta, nbins, "Pattern Delta", "Frequency"
        )
        hist_plot(
            i,
            ax_abs_hist[cur_row, cur_col],
            np.abs(delta),
            nbins,
            "Pattern Delta (Absolute Value)",
            "Frequency",
        )

    fig_pattern.suptitle(fname.split("/"), fontsize=24)
    fig_pattern.savefig(fname_pattern, bbox_inches="tight")

    fig_delta.suptitle(fname.split("/"), fontsize=24)
    fig_delta.savefig(fname_delta, bbox_inches="tight")

    fig_hist.suptitle(fname.split("/"), fontsize=24)
    fig_hist.savefig(fname_hist, bbox_inches="tight")

    fig_abs_hist.suptitle(fname.split("/"), fontsize=24)
    fig_abs_hist.savefig(fname_abs_hist, bbox_inches="tight")


if __name__ == "__main__":
    main()
