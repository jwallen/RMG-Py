################################################################################
#
#	RMG - Reaction Mechanism Generator
#
#	Copyright (c) 2002-2009 Prof. William H. Green (whgreen@mit.edu) and the
#	RMG Team (rmg_dev@mit.edu)
#
#	Permission is hereby granted, free of charge, to any person obtaining a
#	copy of this software and associated documentation files (the 'Software'),
#	to deal in the Software without restriction, including without limitation
#	the rights to use, copy, modify, merge, publish, distribute, sublicense,
#	and/or sell copies of the Software, and to permit persons to whom the
#	Software is furnished to do so, subject to the following conditions:
#
#	The above copyright notice and this permission notice shall be included in
#	all copies or substantial portions of the Software.
#
#	THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
#	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
#	DEALINGS IN THE SOFTWARE.
#
################################################################################

from data cimport Database, Dictionary
from structure cimport Structure
from species cimport Species

################################################################################

cdef class Reaction:

	cdef public int id
	cdef public list atomLabels
	cdef public object bestKinetics
	cdef public object family
	cdef public list kinetics
	cdef public double multiplier
	cdef public list products
	cdef public list reactants
	cdef public Reaction reverse
	cdef public bint thirdBody
	cdef public object canteraReaction

	cdef public object E0
	cdef public object kf
	cdef public object kb

	cpdef fromXML(Reaction self, document, rootElement)

	cpdef toXML(Reaction self, document, rootElement)
	
	cpdef bint hasTemplate(Reaction self, list reactants, list products)

	cpdef bint isUnimolecular(Reaction self)

	cpdef bint isBimolecular(Reaction self)

	cpdef bint equivalent(Reaction self, Reaction other)

	cpdef double getEnthalpyOfReaction(Reaction self, double T)

	cpdef double getEntropyOfReaction(Reaction self, double T)

	cpdef double getFreeEnergyOfReaction(Reaction self, double T)

	cpdef double getEquilibriumConstant(Reaction self, double T)

	cpdef int getStoichiometricCoefficient(Reaction self, Species spec)

	cpdef bint isIsomerization(Reaction self)

	cpdef bint isDissociation(Reaction self)

	cpdef bint isAssociation(Reaction self)

	cpdef calculateMicrocanonicalRate(Reaction self, Elist, double T, reacDensStates, prodDensStates=?)

################################################################################

cdef class PDepReaction(Reaction):
	"""
	A reaction with kinetics that depend on both temperature and pressure. Much
	of the functionality is inherited from :class:`Reaction`, with one
	exception: as the kinetics are explicitly functions of pressure, the
	pressure must be specified when calling :meth:`getRateConstant` and
	:meth:`getBestKinetics`.
	"""

	cdef public object network

################################################################################

cpdef kineticsInverseLaplaceTransform(kinetics, E0, densStates, Elist, T)

################################################################################

cpdef tuple checkForExistingReaction(Reaction rxn)

cpdef tuple makeNewReaction(Reaction forward, bint checkExisting=?)

cpdef list prepareStructures(Reaction forward, Reaction reverse, list speciesList, list atomLabels)

cpdef tuple processNewReaction(Reaction rxn)

cpdef PDepReaction makeNewPDepReaction(list reactants, list products, object network, object kinetics)
