"""Dominions Calc, a utility to help with Dominions math,
By Braddock Gaskill (braddock@braddock.com) 2017"""

from random import randint
from copy import deepcopy
from math import floor, sqrt
from itertools import islice

import numpy as np


class Ship(object):
    """Represents a class of ship, and the defining characteristics"""
    def __init__(self, name, cost, tech, attack, defense, damage):
        self.name = name
        self.cost = cost
        self.tech = tech
        self.attack = attack
        self.defense = defense
        self.damage = damage


global ships
ships = {
        'Frigate' : Ship('Frigate',     5, 1.,  1, 2, 5),
        'Destroyer': Ship('Destroyer',  10, 2.,  2, 3, 11),
        'Cruiser': Ship('Cruiser',    20, 3.5, 4, 6, 24),
        'Battleship': Ship('Battleship', 40, 5.5, 8, 12,53),
        'Dreadnought': Ship('Dreadnought', 80, 9., 16, 24,116),
        'SuperDreadnought': Ship('SuperDreadnought', 160, 15., 32, 48, 255)
       }


class Fleet(object):
    """Represents a fleet of ships"""
    def __init__(self, frigates=0, destroyers=0, cruisers=0, battleships=0,
            dreadnoughts=0, superdreadnoughts=0):
        global ships
        self.ships = []
        self.ships.append((ships['Frigate'], frigates))
        self.ships.append((ships['Destroyer'], destroyers))
        self.ships.append((ships['Cruiser'], cruisers))
        self.ships.append((ships['Battleship'], battleships))
        self.ships.append((ships['Dreadnought'], dreadnoughts))
        self.ships.append((ships['SuperDreadnought'], superdreadnoughts))
      
    def number_of_ships(self):
        return sum([s[1] for s in self.ships])

    def fleet_destroyed(self):
        """Has the fleet been destroyed?"""
        return 0 == self.number_of_ships()

    def get_ship_by_index(self, i):
        count = 0
        for idx, (ship, n) in enumerate(self.ships):
            count += n
            if i < count and count > 0:
                return idx
        raise Exception("Could not find ship by index " + str(i))

    def get_random_ship(self):
        total_ships = self.number_of_ships()
        which_lost = randint(0, total_ships - 1)
        idx = self.get_ship_by_index(which_lost)
        return idx

    def destroy_ship(self, idx):
        self.ships[idx] = (self.ships[idx][0], self.ships[idx][1] - 1)
        if self.ships[idx][1] < 0:
            raise Exception("destroy_ship destroyed a non-existent ship")


class Fight(object):
    """Represents a fight between two fleets"""

    def __init__(self, attacker, defender):
        self.attacker = deepcopy(attacker)
        self.defender = deepcopy(defender)

    def determine_losses(self, fleet, damage):
        """Determine the ships destroyed in one round of fighting"""
        while True:  # Until damage < 1
            victim = fleet.get_random_ship()
            fleet.destroy_ship(victim)
            damage -= fleet.ships[victim][0].damage
            if fleet.number_of_ships() == 0:
                damage = 0
            if damage < 1:
                break

    def round(self):
        """One round of fighting
        return - True if the attacker wins (defender destroyed), 
                 false if the defender wins (attacker destroyed), 
                 None if neither side wins yet.
        """
        attack_damage = 0.0
        for ship in self.attacker.ships:
            a = ship[0].attack
            attack_damage += randint(0, a + 1) + a

        defense_damage = 0.0
        for ship in self.defender.ships:
            d = ship[0].defense
            defense_damage += randint(0, d + 1) + d

        attack_succeeds = None
        if self.defender.fleet_destroyed():
            attack_succeeds = True
        else:
            self.determine_losses(self.attacker, defense_damage)
            self.determine_losses(self.defender, attack_damage)

        if self.defender.fleet_destroyed():
            attack_succeeds = True
        if self.attacker.fleet_destroyed():
            attack_succeeds = False
        return attack_succeeds

    def fight(self):
        """Perform rounds of fighting until one fleet is destroyed.
        return value - True if the attacker wins, false if the defender wins"""
        while True:
            attack_succeeds = self.round()
            if attack_succeeds is not None:
                return attack_succeeds


def chance_of_winning(attacker, defender):
    """
    Runs a series of mock battles between two fleets, and 
    predicts the probability that the attacker will win against
    the defender.

    Example Usage:
        import dominions_calc as dc 
        dc.chance_of_winning(dc.Fleet(frigates=29,destroyers=2), dc.Fleet(frigates=20))
        Attacker has 43.00% chance of winning.
    """
    n = 100
    wins = 0
    for i in range(n):
        attacker_won = Fight(attacker, defender).fight()
        if attacker_won:
            wins += 1
    percent = 100. * float(wins) / n
    print("Attacker has %.1f%% chance of winning." % percent)
    return percent


def population_gen(start_pop, habitability, owned=True):
    """This generator yields the population as it grows
    for a planet"""
    pop = start_pop
    while True:
        if owned:
            divisor = 1000.
        else:
            divisor = 2000.
        pop = floor(pop * ((float(habitability) / divisor) + 1.05))
        yield pop


def population(n, start_pop, habitability, owned=True):
    """Project population into the future.  Returns a list,
    one population per turn.  n specifies the number of turns
    to return"""
    return list(islice(population_gen(start_pop, habitability, owned), n))


def production(pop, level, industry_percent):
    """Compute the production of technology and industry units
    for the given population and industrial level.
    pop = population of planet
    level = industry level of planet
    industry_percent = percentage of workforce allocated 
                       to industry (vs technology)
    
    Returns a tuple (industry_units, tech_units)"""
    pop = float(pop)
    level = float(level)
    industry_fraction = (industry_percent / 100.)
    tech_fraction = 1 - industry_fraction
    iu = floor(industry_fraction * (pop / 1000.) * sqrt(level))
    tu = floor(tech_fraction * (pop / 2500.) * sqrt(level))
    return (iu, tu)


def project_production(n, start_pop, habitability, owned, level, industry_percent):
    """Project industrial and technological output for a planet for the 
    next n months"""
    r=[]
    populations = population(n, start_pop, habitability, owned)
    for i in range(n):
        (iu, tu) = production(populations[i], level, industry_percent)
        r.append((iu, tu))
    return r


def sum_project_production(turns, start_pop, habitability, owned, level, industry_percent):
    units = project_production(turns, start_pop, habitability, owned, level, industry_percent)
    iu = sum([x[0] for x in units])
    tu = sum([x[1] for x in units])
    return (iu, tu)
    

def argmax(arr):
    return arr.index(max(arr))
    #return np.argmax(arr)


def industry_level_gain(turns, current_industry_level, new_industry_level, population, habitability):
    baseline_iu, _ = sum_project_production(turns, population, habitability, True, current_industry_level, 100.0)
    new_iu, _ = sum_project_production(turns, population, habitability, True, new_industry_level, 100.0)
    gain = new_iu - baseline_iu - 100.0*(new_industry_level - current_industry_level)
    print("Over %i turns at level %.2f, %i IUs are produced" % (turns, current_industry_level, baseline_iu))
    print("              at level %.2f, %i IUs are produced, a net gain of %i" % (new_industry_level, new_iu, gain))
    return gain


def industry_level_payback(turns, current_industry_level, population, habitability): 
    """Compute the optimal amount by which to increase your industry level on a planet.
    This brute force computes the projected industry unit gain for expendatures of between
    0 and 10,000 industrial units and returns the most profitable investment over the
    specified number of tunrs"""
    baseline_iu, _ = sum_project_production(turns, population, habitability, True, current_industry_level, 100.0)
    print("baseline=", baseline_iu)
    gains = []
    for investment in range(10000):
        level = current_industry_level + float(investment) / 100.0
        iu, _ = sum_project_production(turns, population, habitability, True, level, 100.0)
        gain = iu - baseline_iu - investment
        gains.append(gain)
    best_investment = argmax(gains) 
    print("Best investment is %i units to increase industry level to %.2f\nfor a net gain over %i turns of %i units" % (best_investment, current_industry_level + (float(best_investment) / 100.), turns, gains[best_investment]))
    return best_investment

        
