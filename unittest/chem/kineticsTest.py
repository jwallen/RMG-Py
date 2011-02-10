#!/usr/bin/env python
# -*- coding: utf-8 -*-

import numpy
import unittest

from rmgpy.chem.kinetics import *

################################################################################

class KineticsTest(unittest.TestCase):
    """
    Contains unit tests for the rmgpy.chem.kinetics module, used for working with
    kinetics models.
    """

    def testArrheniusChangeT0(self):
        """
        Test the ArrheniusModel.changeT0() method.
        """
        kinetics = ArrheniusModel(A=1.0e6, n=1.0, Ea=10000.0, T0=298.15)
        Tlist = numpy.arange(300, 2001, 100, numpy.float64)

        klist0 = numpy.zeros_like(Tlist)
        for i in range(Tlist.shape[0]):
            klist0[i] = kinetics.getRateCoefficient(Tlist[i])

        kinetics.changeT0(1.0)
        klist = numpy.zeros_like(Tlist)
        for i in range(Tlist.shape[0]):
            klist[i] = kinetics.getRateCoefficient(Tlist[i])
        
        for i in range(Tlist.shape[0]):
            self.assertAlmostEqual(klist0[i], klist[i], 6)

    def testArrheniusFitToData(self):
        """
        Test the ArrheniusModel.fitToData() method.
        """
        kinetics0 = ArrheniusModel(A=1.0e6, n=1.0, Ea=10000.0, T0=298.15)
        Tlist = numpy.arange(300, 2001, 100, numpy.float64)
        klist = numpy.zeros_like(Tlist)
        for i in range(Tlist.shape[0]):
            klist[i] = kinetics0.getRateCoefficient(Tlist[i])

        kinetics = ArrheniusModel()
        kinetics.fitToData(Tlist, klist, kinetics0.T0)

        self.assertAlmostEqual(kinetics0.A, kinetics.A, 6)
        self.assertAlmostEqual(kinetics0.n, kinetics.n, 6)
        self.assertAlmostEqual(kinetics0.T0, kinetics.T0, 6)
        self.assertAlmostEqual(kinetics0.Ea, kinetics.Ea, 6)

    def testPDepArrheniusFitToData(self):
        """
        Test the PDepArrheniusModel.fitToData() method.
        """

        P0 = 1e3; P1 = 1e5
        arrh0 = ArrheniusModel(A=1.0e6, n=1.0, Ea=10000.0, T0=298.15, Tmin=300, Tmax=2000, numReactants=2, comment='These parameters are completely made up')
        arrh1 = ArrheniusModel(A=1.0e12, n=0.0, Ea=20000.0, T0=298.15, Tmin=300, Tmax=2000, numReactants=2, comment='These parameters are also completely made up')

        Tlist = numpy.arange(300, 2001, 100, numpy.float64)
        Plist = numpy.array([P0, P1], numpy.float64)
        K = numpy.zeros((len(Tlist), 2), numpy.float64)
        for i in range(Tlist.shape[0]):
            K[i,0] = arrh0.getRateCoefficient(Tlist[i], P0)
            K[i,1] = arrh1.getRateCoefficient(Tlist[i], P1)

        kinetics = PDepArrheniusModel()
        kinetics.fitToData(Tlist, Plist, K, T0=298.15)

        self.assertTrue(len(kinetics.pressures), 2)
        self.assertTrue(len(kinetics.arrhenius), 2)
        self.assertAlmostEqual(kinetics.arrhenius[0].A, arrh0.A, 6)
        self.assertAlmostEqual(kinetics.arrhenius[0].n, arrh0.n, 6)
        self.assertAlmostEqual(kinetics.arrhenius[0].T0, arrh0.T0, 6)
        self.assertAlmostEqual(kinetics.arrhenius[0].Ea, arrh0.Ea, 6)
        self.assertAlmostEqual(kinetics.arrhenius[1].A / 1.0e12, arrh1.A / 1.0e12, 6)
        self.assertAlmostEqual(kinetics.arrhenius[1].n, arrh1.n, 6)
        self.assertAlmostEqual(kinetics.arrhenius[1].T0, arrh1.T0, 6)
        self.assertAlmostEqual(kinetics.arrhenius[1].Ea, arrh1.Ea, 6)

    def testChebyshevFitToData(self):
        """
        Test the ChebyshevModel.fitToData() method.
        """

        coeffs = numpy.array([[1.0e0,2.0e-3,3.0e-6], [4.0e0,5.0e-3,6.0e-6], [7.0e0,8.0e-3,9.0e-6], [10.0e0,11.0e-3,12.0e-6]], numpy.float64)

        kinetics0 = ChebyshevModel(coeffs=coeffs, Tmin=300, Tmax=2000, Pmin=1e3, Pmax=1e7, numReactants=2, comment='These parameters are completely made up and unrealistic')

        Tlist = numpy.arange(300, 2001, 100, numpy.float64)
        Plist = numpy.array([1e3, 1e4, 1e5, 1e6, 1e7], numpy.float64)
        K = numpy.zeros((len(Tlist), len(Plist)), numpy.float64)
        for i in range(len(Tlist)):
            for j in range(len(Plist)):
                K[i,j] = kinetics0.getRateCoefficient(Tlist[i], Plist[j])

        kinetics = ChebyshevModel()
        kinetics.fitToData(Tlist, Plist, K, degreeT=4, degreeP=3, Tmin=300, Tmax=2000, Pmin=1e3, Pmax=1e7)

        self.assertEqual(kinetics0.degreeT, kinetics.degreeT)
        self.assertEqual(kinetics0.degreeP, kinetics.degreeP)
        for i in range(kinetics0.degreeT):
            for j in range(kinetics0.degreeP):
                self.assertAlmostEqual(kinetics0.coeffs[i,j], kinetics.coeffs[i,j], 6)
        self.assertEqual(kinetics0.Tmin, kinetics.Tmin)
        self.assertEqual(kinetics0.Tmax, kinetics.Tmax)
        self.assertEqual(kinetics0.Pmin, kinetics.Pmin)
        self.assertEqual(kinetics0.Pmax, kinetics.Pmax)

    def testArrheniusEPToArrhenius(self):
        """
        Test the ArrheniusEPModel.toArrhenius() method.
        """
        kinetics0 = ArrheniusEPModel(A=1.0e6, n=1.0, alpha=0.5, E0=10000.0)

        Tlist = numpy.arange(300, 2001, 100, numpy.float64)
        dHrxnlist = numpy.arange(-100000, 100001, 10000, numpy.float64)

        for dHrxn in dHrxnlist:
            kinetics = kinetics0.toArrhenius(dHrxn)
            for T in Tlist:
                k0 = kinetics0.getRateCoefficient(T, dHrxn)
                k = kinetics.getRateCoefficient(T)
            self.assertAlmostEqual(k0, k, 6)

    def testPickleArrhenius(self):
        """
        Test that an ArrheniusModel object can be successfully pickled and
        unpickled with no loss of information.
        """
        
        kinetics0 = ArrheniusModel(A=1.0e6, n=1.0, Ea=10000.0, T0=298.15, Tmin=300, Tmax=2000, numReactants=2, comment='These parameters are completely made up')
        import cPickle
        kinetics = cPickle.loads(cPickle.dumps(kinetics0))

        self.assertEqual(kinetics0.A, kinetics.A)
        self.assertEqual(kinetics0.n, kinetics.n)
        self.assertEqual(kinetics0.T0, kinetics.T0)
        self.assertEqual(kinetics0.Ea, kinetics.Ea)

        self.assertEqual(kinetics0.Tmin, kinetics.Tmin)
        self.assertEqual(kinetics0.Tmax, kinetics.Tmax)
        self.assertEqual(kinetics0.Pmin, kinetics.Pmin)
        self.assertEqual(kinetics0.Pmax, kinetics.Pmax)
        self.assertEqual(kinetics0.numReactants, kinetics.numReactants)
        self.assertEqual(kinetics0.comment, kinetics.comment)

    def testPickleArrheniusEP(self):
        """
        Test that an ArrheniusEPModel object can be successfully pickled and
        unpickled with no loss of information.
        """

        kinetics0 = ArrheniusEPModel(A=1.0e6, n=1.0, alpha=0.5, E0=10000.0, Tmin=300, Tmax=2000, numReactants=2, comment='These parameters are completely made up')
        import cPickle
        kinetics = cPickle.loads(cPickle.dumps(kinetics0))

        self.assertEqual(kinetics0.A, kinetics.A)
        self.assertEqual(kinetics0.n, kinetics.n)
        self.assertEqual(kinetics0.alpha, kinetics.alpha)
        self.assertEqual(kinetics0.E0, kinetics.E0)

        self.assertEqual(kinetics0.Tmin, kinetics.Tmin)
        self.assertEqual(kinetics0.Tmax, kinetics.Tmax)
        self.assertEqual(kinetics0.Pmin, kinetics.Pmin)
        self.assertEqual(kinetics0.Pmax, kinetics.Pmax)
        self.assertEqual(kinetics0.numReactants, kinetics.numReactants)
        self.assertEqual(kinetics0.comment, kinetics.comment)

    def testPickleMultiArrhenius(self):
        """
        Test that a MultiArrheniusModel object can be successfully pickled and
        unpickled with no loss of information.
        """

        arrh0 = ArrheniusModel(A=1.0e6, n=1.0, Ea=10000.0, T0=298.15, Tmin=300, Tmax=2000, numReactants=2, comment='These parameters are completely made up')
        arrh1 = ArrheniusModel(A=1.0e12, n=0.0, Ea=20000.0, T0=298.15, Tmin=300, Tmax=2000, numReactants=2, comment='These parameters are also completely made up')

        kinetics0 = MultiArrheniusModel(arrheniusList=[arrh0, arrh1], Tmin=300, Tmax=2000, numReactants=2, comment='These parameters are completely made up')
        import cPickle
        kinetics = cPickle.loads(cPickle.dumps(kinetics0))

        Narrh = 2
        self.assertEqual(len(kinetics0.arrheniusList), Narrh)
        self.assertEqual(len(kinetics.arrheniusList), Narrh)
        for i in range(Narrh):
            self.assertEqual(kinetics0.arrheniusList[i].A, kinetics.arrheniusList[i].A)
            self.assertEqual(kinetics0.arrheniusList[i].n, kinetics.arrheniusList[i].n)
            self.assertEqual(kinetics0.arrheniusList[i].T0, kinetics.arrheniusList[i].T0)
            self.assertEqual(kinetics0.arrheniusList[i].Ea, kinetics.arrheniusList[i].Ea)

        self.assertEqual(kinetics0.Tmin, kinetics.Tmin)
        self.assertEqual(kinetics0.Tmax, kinetics.Tmax)
        self.assertEqual(kinetics0.Pmin, kinetics.Pmin)
        self.assertEqual(kinetics0.Pmax, kinetics.Pmax)
        self.assertEqual(kinetics0.numReactants, kinetics.numReactants)
        self.assertEqual(kinetics0.comment, kinetics.comment)

    def testPicklePDepArrhenius(self):
        """
        Test that a PDepArrheniusModel object can be successfully pickled and
        unpickled with no loss of information.
        """

        P0 = 1e3; P1 = 1e5
        arrh0 = ArrheniusModel(A=1.0e6, n=1.0, Ea=10000.0, T0=298.15, Tmin=300, Tmax=2000, numReactants=2, comment='These parameters are completely made up')
        arrh1 = ArrheniusModel(A=1.0e12, n=0.0, Ea=20000.0, T0=298.15, Tmin=300, Tmax=2000, numReactants=2, comment='These parameters are also completely made up')

        kinetics0 = PDepArrheniusModel(pressures=[P0,P1], arrhenius=[arrh0, arrh1], Tmin=300, Tmax=2000, Pmin=1e3, Pmax=1e5, numReactants=2, comment='These parameters are completely made up')
        import cPickle
        kinetics = cPickle.loads(cPickle.dumps(kinetics0))

        Narrh = 2
        self.assertEqual(len(kinetics0.pressures), Narrh)
        self.assertEqual(len(kinetics.pressures), Narrh)
        self.assertEqual(len(kinetics0.arrhenius), Narrh)
        self.assertEqual(len(kinetics.arrhenius), Narrh)
        for i in range(Narrh):
            self.assertEqual(kinetics0.pressures[i], kinetics.pressures[i])
            self.assertEqual(kinetics0.arrhenius[i].A, kinetics.arrhenius[i].A)
            self.assertEqual(kinetics0.arrhenius[i].n, kinetics.arrhenius[i].n)
            self.assertEqual(kinetics0.arrhenius[i].T0, kinetics.arrhenius[i].T0)
            self.assertEqual(kinetics0.arrhenius[i].Ea, kinetics.arrhenius[i].Ea)

        self.assertEqual(kinetics0.Tmin, kinetics.Tmin)
        self.assertEqual(kinetics0.Tmax, kinetics.Tmax)
        self.assertEqual(kinetics0.Pmin, kinetics.Pmin)
        self.assertEqual(kinetics0.Pmax, kinetics.Pmax)
        self.assertEqual(kinetics0.numReactants, kinetics.numReactants)
        self.assertEqual(kinetics0.comment, kinetics.comment)

    def testPickleChebyshev(self):
        """
        Test that a ChebyshevModel object can be successfully pickled and
        unpickled with no loss of information.
        """

        coeffs = numpy.array([[1.0,2.0,3.0,4.0], [5.0,6.0,7.0,8.0], [9.0,10.0,11.0,12.0]], numpy.float64)

        kinetics0 = ChebyshevModel(coeffs=coeffs, Tmin=300, Tmax=2000, Pmin=1e3, Pmax=1e5, numReactants=2, comment='These parameters are completely made up and unrealistic')
        import cPickle
        kinetics = cPickle.loads(cPickle.dumps(kinetics0))

        degreeT = 3; degreeP = 4
        self.assertEqual(kinetics0.coeffs.shape[0], degreeT)
        self.assertEqual(kinetics0.coeffs.shape[1], degreeP)
        self.assertEqual(kinetics0.degreeT, degreeT)
        self.assertEqual(kinetics0.degreeP, degreeP)
        self.assertEqual(kinetics.coeffs.shape[0], degreeT)
        self.assertEqual(kinetics.coeffs.shape[1], degreeP)
        self.assertEqual(kinetics.degreeT, degreeT)
        self.assertEqual(kinetics.degreeP, degreeP)
        for i in range(degreeT):
            for j in range(degreeP):
                self.assertEqual(kinetics0.coeffs[i,j], kinetics.coeffs[i,j])
        
        self.assertEqual(kinetics0.Tmin, kinetics.Tmin)
        self.assertEqual(kinetics0.Tmax, kinetics.Tmax)
        self.assertEqual(kinetics0.Pmin, kinetics.Pmin)
        self.assertEqual(kinetics0.Pmax, kinetics.Pmax)
        self.assertEqual(kinetics0.numReactants, kinetics.numReactants)
        self.assertEqual(kinetics0.comment, kinetics.comment)

    def testPickleThirdBody(self):
        """
        Test that a ThirdBodyModel object can be successfully pickled and
        unpickled with no loss of information.
        """

        arrhHigh = ArrheniusModel(A=1.0e6, n=1.0, Ea=10000.0, T0=298.15, Tmin=300, Tmax=2000, numReactants=2, comment='These parameters are completely made up')
        efficiencies = {'N2': 0.5, 'Ar': 1.5}

        kinetics0 = ThirdBodyModel(arrheniusHigh=arrhHigh, efficiencies=efficiencies, Tmin=300, Tmax=2000, Pmin=1e3, Pmax=1e5, numReactants=2, comment='These parameters are completely made up and unrealistic')
        import cPickle
        kinetics = cPickle.loads(cPickle.dumps(kinetics0))

        self.assertEqual(kinetics0.arrheniusHigh.A, kinetics.arrheniusHigh.A)
        self.assertEqual(kinetics0.arrheniusHigh.n, kinetics.arrheniusHigh.n)
        self.assertEqual(kinetics0.arrheniusHigh.T0, kinetics.arrheniusHigh.T0)
        self.assertEqual(kinetics0.arrheniusHigh.Ea, kinetics.arrheniusHigh.Ea)
        for collider, efficiency in kinetics0.efficiencies.iteritems():
            self.assertTrue(collider in kinetics.efficiencies)
            self.assertEqual(efficiency, kinetics.efficiencies[collider])

        self.assertEqual(kinetics0.Tmin, kinetics.Tmin)
        self.assertEqual(kinetics0.Tmax, kinetics.Tmax)
        self.assertEqual(kinetics0.Pmin, kinetics.Pmin)
        self.assertEqual(kinetics0.Pmax, kinetics.Pmax)
        self.assertEqual(kinetics0.numReactants, kinetics.numReactants)
        self.assertEqual(kinetics0.comment, kinetics.comment)

    def testPickleLindemann(self):
        """
        Test that a LindemannModel object can be successfully pickled and
        unpickled with no loss of information.
        """

        arrhLow = ArrheniusModel(A=1.0e6, n=1.0, Ea=10000.0, T0=298.15, Tmin=300, Tmax=2000, numReactants=2, comment='These parameters are completely made up')
        arrhHigh = ArrheniusModel(A=1.0e12, n=0.0, Ea=20000.0, T0=298.15, Tmin=300, Tmax=2000, numReactants=2, comment='These parameters are also completely made up')
        efficiencies = {'N2': 0.5, 'Ar': 1.5}

        kinetics0 = LindemannModel(arrheniusLow=arrhLow, arrheniusHigh=arrhHigh, efficiencies=efficiencies, Tmin=300, Tmax=2000, Pmin=1e3, Pmax=1e5, numReactants=2, comment='These parameters are completely made up and unrealistic')
        import cPickle
        kinetics = cPickle.loads(cPickle.dumps(kinetics0))

        self.assertEqual(kinetics0.arrheniusLow.A, kinetics.arrheniusLow.A)
        self.assertEqual(kinetics0.arrheniusLow.n, kinetics.arrheniusLow.n)
        self.assertEqual(kinetics0.arrheniusLow.T0, kinetics.arrheniusLow.T0)
        self.assertEqual(kinetics0.arrheniusLow.Ea, kinetics.arrheniusLow.Ea)
        self.assertEqual(kinetics0.arrheniusHigh.A, kinetics.arrheniusHigh.A)
        self.assertEqual(kinetics0.arrheniusHigh.n, kinetics.arrheniusHigh.n)
        self.assertEqual(kinetics0.arrheniusHigh.T0, kinetics.arrheniusHigh.T0)
        self.assertEqual(kinetics0.arrheniusHigh.Ea, kinetics.arrheniusHigh.Ea)
        for collider, efficiency in kinetics0.efficiencies.iteritems():
            self.assertTrue(collider in kinetics.efficiencies)
            self.assertEqual(efficiency, kinetics.efficiencies[collider])

        self.assertEqual(kinetics0.Tmin, kinetics.Tmin)
        self.assertEqual(kinetics0.Tmax, kinetics.Tmax)
        self.assertEqual(kinetics0.Pmin, kinetics.Pmin)
        self.assertEqual(kinetics0.Pmax, kinetics.Pmax)
        self.assertEqual(kinetics0.numReactants, kinetics.numReactants)
        self.assertEqual(kinetics0.comment, kinetics.comment)

    def testPickleTroe(self):
        """
        Test that a TroeModel object can be successfully pickled and
        unpickled with no loss of information.
        """

        arrhLow = ArrheniusModel(A=1.0e6, n=1.0, Ea=10000.0, T0=298.15, Tmin=300, Tmax=2000, numReactants=2, comment='These parameters are completely made up')
        arrhHigh = ArrheniusModel(A=1.0e12, n=0.0, Ea=20000.0, T0=298.15, Tmin=300, Tmax=2000, numReactants=2, comment='These parameters are also completely made up')
        efficiencies = {'N2': 0.5, 'Ar': 1.5}

        kinetics0 = TroeModel(arrheniusLow=arrhLow, arrheniusHigh=arrhHigh, efficiencies=efficiencies, alpha=0.6, T3=1000.0, T1=500.0, T2=300.0, Tmin=300, Tmax=2000, Pmin=1e3, Pmax=1e5, numReactants=2, comment='These parameters are completely made up and unrealistic')
        import cPickle
        kinetics = cPickle.loads(cPickle.dumps(kinetics0))

        self.assertEqual(kinetics0.alpha, kinetics.alpha)
        self.assertEqual(kinetics0.T3, kinetics.T3)
        self.assertEqual(kinetics0.T1, kinetics.T1)
        self.assertEqual(kinetics0.T2, kinetics.T2)
        self.assertEqual(kinetics0.arrheniusLow.A, kinetics.arrheniusLow.A)
        self.assertEqual(kinetics0.arrheniusLow.n, kinetics.arrheniusLow.n)
        self.assertEqual(kinetics0.arrheniusLow.T0, kinetics.arrheniusLow.T0)
        self.assertEqual(kinetics0.arrheniusLow.Ea, kinetics.arrheniusLow.Ea)
        self.assertEqual(kinetics0.arrheniusHigh.A, kinetics.arrheniusHigh.A)
        self.assertEqual(kinetics0.arrheniusHigh.n, kinetics.arrheniusHigh.n)
        self.assertEqual(kinetics0.arrheniusHigh.T0, kinetics.arrheniusHigh.T0)
        self.assertEqual(kinetics0.arrheniusHigh.Ea, kinetics.arrheniusHigh.Ea)
        for collider, efficiency in kinetics0.efficiencies.iteritems():
            self.assertTrue(collider in kinetics.efficiencies)
            self.assertEqual(efficiency, kinetics.efficiencies[collider])

        self.assertEqual(kinetics0.Tmin, kinetics.Tmin)
        self.assertEqual(kinetics0.Tmax, kinetics.Tmax)
        self.assertEqual(kinetics0.Pmin, kinetics.Pmin)
        self.assertEqual(kinetics0.Pmax, kinetics.Pmax)
        self.assertEqual(kinetics0.numReactants, kinetics.numReactants)
        self.assertEqual(kinetics0.comment, kinetics.comment)

################################################################################

if __name__ == '__main__':
    unittest.main( testRunner = unittest.TextTestRunner(verbosity=2) )
