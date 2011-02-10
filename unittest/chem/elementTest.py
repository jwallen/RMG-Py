#!/usr/bin/env python
# -*- coding: utf-8 -*-

import unittest

import rmgpy.chem.element as element

################################################################################

class ElementTest(unittest.TestCase):
    """
    Unit tests of the element module.
    """
    
    def testGetElement(self):
        """
        Test that the getElement() method performs correctly for a variety of
        queries.
        """
        for elem in element.elementList:
            self.assertTrue(element.getElement(elem.number) == elem)
            self.assertTrue(element.getElement(elem.symbol) == elem)

    def testPickle(self):
        """
        Test that the Element class can be safely pickled and unpickled with
        no loss of data.
        """
        import cPickle
        
        e0 = element.Element(number=6, symbol='C', name='carbon', mass=12.0*0.001)
        e = cPickle.loads(cPickle.dumps(e0))
        
        self.assertEqual(e0.number, e.number)
        self.assertEqual(e0.symbol, e.symbol)
        self.assertEqual(e0.name, e.name)
        self.assertEqual(e0.mass, e.mass)

################################################################################

if __name__ == '__main__':
    unittest.main( testRunner = unittest.TextTestRunner(verbosity=2) )
