#!/usr/bin/env python
# encoding: utf-8

atoms = {
    'C': 2,
    'H': 6,
}

bonds = {
    'C-C': 1,
    'C-H': 6,
}

linear = False

externalSymmetry = 6

spinMultiplicity = 1

opticalIsomers = 1

energy = {
    'CBS-QB3': GaussianLog('ethane_cbsqb3.log'),
    'Klip_2': -79.64199436,
}

geometry = GaussianLog('ethane_cbsqb3.log')

frequencies = GaussianLog('ethane_cbsqb3.log')

frequencyScaleFactor = 0.99

rotors = [
    HinderedRotor(scanLog=GaussianLog('ethane_scan_1.log'), pivots=[1,5], top=[1,2,3,4], symmetry=3),
]
