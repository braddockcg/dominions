from random import randint
from copy import deepcopy


class Ship(object):
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
    def __init__(self, attacker, defender):
        self.attacker = deepcopy(attacker)
        self.defender = deepcopy(defender)

    def determine_losses(self, fleet, damage):
        while True:  # Until damage < 1
            victim = fleet.get_random_ship()
            fleet.destroy_ship(victim)
            damage -= fleet.ships[victim][0].damage
            if fleet.number_of_ships() == 0:
                damage = 0
            if damage < 1:
                break

    def round(self):
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
        while True:
            attack_succeeds = self.round()
            if attack_succeeds is not None:
                return attack_succeeds

"""
Runs a series of mock battles between two fleets, and 
predicts the probability that the attacker will win against
the defender.

Example Usage:
    import dominions_calc as dc 
    dc.chance_of_winning(dc.Fleet(frigates=29,destroyers=2), dc.Fleet(frigates=20))
    Attacker has 43.00% chance of winning.
"""
def chance_of_winning(attacker, defender):
    n = 100
    wins = 0
    for i in range(n):
        attacker_won = Fight(attacker, defender).fight()
        if attacker_won:
            wins += 1
    percent = 100. * float(wins) / n
    print("Attacker has %.1f%% chance of winning." % percent)
    return percent

