#!/usr/bin/env python3
# Planet parsing and mapping code
# By Braddock Gaskill 10 November 2018

import cstruct
import sys

# pip install ansicolors
from colors import color


class PlanetRecord(cstruct.CStruct):
    __byte_order__ = cstruct.LITTLE_ENDIAN
    __struct__ = """
        unsigned char name_length;
        char name[20];
        unsigned char x;
        unsigned char y;
        unsigned char owner;
        double population;
        unsigned char habitability;
        unsigned char industry_percent;
        unsigned char technology_percent;
        unsigned char pad1[5];
        double industrial_level;
        unsigned short ships[6];
        unsigned char radars[3];
        unsigned char pad2[1];
    """

    def __init__(self):
        self.id = -1

    def Name(self):
        return self.name.decode('latin1').rstrip('\000')


def load_planets(fname="Planets.Dom"):
    buffer = open(fname, "rb").read()
    sz = PlanetRecord.size
    planets = []
    for i in range(200):
        p = PlanetRecord()
        p.unpack(buffer[i * sz:i * sz + sz])
        p.id = i + 1
        planets.append(p)
    return planets


def planets_to_space(planets):
    space = [[None] * 50 for _ in range(50)]
    for p in planets:
        space[p.y - 1][p.x - 1] = p
    return space


def print_ansi_map(planets, use_color=True):
    cmap = {
        1: 'green',
        2: 'yellow',
        3: 'blue',
        4: 'red'
    }
    space = planets_to_space(planets)
    for y in range(1, 51):
        for x in range(1, 51):
            p = space[y-1][x-1]
            if p is None:
                print("   ", end='')
            else:
                c = cmap.get(p.owner, 'default')
                print(color("%3d" % p.id, bg=c), end='')
        print()


if __name__ == "__main__":
    fname = sys.argv[1]
    planets = load_planets(fname)
    print_ansi_map(planets)
