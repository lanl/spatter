import json

patterns = './spatter.json'

with open(patterns, 'r') as json_file:

    json_objects = json.load(json_file)

    i = 1
    for item in json_objects:
        fname = 'spatter' + str(i) +'.json'

        with open(fname, 'w') as out_file:
            json.dump([item], out_file, separators=(',', ':'))

        i += 1
