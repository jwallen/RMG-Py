#!/usr/bin/env python
# -*- coding: utf-8 -*-

import unittest
import quantities as pq

import rmgpy.chem.constants as constants

################################################################################

class ConstantsTest(unittest.TestCase):
    """
    Unit tests of the constants module.
    """
    
    def testValues(self):
        """
        Check that the values of the constants match those obtained from the
        quantities package.
        """
        R = float(pq.constants.R.simplified)
        self.assertAlmostEqual(constants.R / R, 1.0, 8, 'Expected R = %g, got R = %g' % (R, constants.R))

        kB = float(pq.constants.Boltzmann_constant.simplified)
        self.assertAlmostEqual(constants.kB / kB, 1.0, 8, 'Expected kB = %g, got kB = %g' % (kB, constants.kB))

        h = float(pq.constants.h.simplified)
        self.assertAlmostEqual(constants.h / h, 1.0, 8, 'Expected h = %g, got h = %g' % (h, constants.h))

        c = float(299792458)
        self.assertAlmostEqual(constants.c / c, 1.0, 8, 'Expected c = %g, got c = %g' % (c, constants.c))

        pi = float(pq.constants.pi.simplified)
        self.assertAlmostEqual(constants.pi / pi, 1.0, 8, 'Expected pi = %g, got pi = %g' % (pi, constants.pi))

################################################################################

if __name__ == '__main__':
    unittest.main( testRunner = unittest.TextTestRunner(verbosity=2) )
