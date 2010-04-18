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

from graph cimport Graph
from chem cimport Atom, Bond

################################################################################

cdef class Structure:

	cdef public Graph graph
	cdef public int symmetryNumber

	cpdef list atoms(Structure self)
	
	cpdef list bonds(Structure self)

	cpdef addAtom(Structure self, Atom atom)

	cpdef addBond(Structure self, Bond bond)

	cpdef dict getBonds(Structure self, Atom atom)

	cpdef Bond getBond(Structure self, Atom atom1, Atom atom2)

	cpdef bint hasBond(Structure self, Atom atom1, Atom atom2)

	cpdef removeAtom(Structure self, Atom atom)

	cpdef removeBond(Structure self, Bond bond)

	cpdef bint isIsomorphic(Structure self, Structure other, dict map12=?, dict map21=?)

	cpdef tuple findIsomorphism(Structure self, Structure other, dict map12=?, dict map21=?)

	cpdef bint isSubgraphIsomorphic(Structure self, Structure other, dict map12=?, dict map21=?)

	cpdef tuple findSubgraphIsomorphisms(Structure self, Structure other, dict map12=?, dict map21=?)

	cpdef initialize(Structure self, list atoms, list bonds)
	
	cpdef copy(Structure self, bint returnMap=?)

	cpdef Structure merge(Structure self, Structure other)

	cpdef list split(Structure self)

	cpdef resetCachedStructureInfo(Structure self)

	cpdef list getSmallestSetOfSmallestRings(Structure self)

	cpdef str getFormula(Structure self)

	cpdef double getMolecularWeight(Structure self)

	cpdef fromXML(Structure self, document, rootElement)
		
	cpdef fromAdjacencyList(Structure self, str adjlist, bint addH=?, bint withLabel=?)
	
	cpdef fromCML(Structure self, str cmlstr)

	cpdef fromInChI(Structure self, str inchistr)

	cpdef fromSMILES(Structure self, str smilesstr)

	cpdef fromOBMol(Structure self, object obmol)

	cpdef str toAdjacencyList(Structure self, str label=?, bint strip_hydrogens=?)

	cpdef object toOBMol(Structure self)

	cpdef str toCML(Structure self)
	
	cpdef str toInChI(Structure self)

	cpdef str toSMILES(Structure self)

	cpdef toXML(Structure self, document, rootElement)

	cpdef toDOT(Structure self)
	
	cpdef simplifyAtomTypes(Structure self)

	cpdef updateAtomTypes(Structure self)
		
	cpdef int getRadicalCount(Structure self)

	cpdef getAdjacentResonanceIsomers(Structure self)

	cpdef findAllDelocalizationPaths(Structure self, Atom atom1)

	cpdef clearLabeledAtoms(Structure self)

	cpdef bint containsLabeledAtom(Structure self, str label)

	cpdef Atom getLabeledAtom(Structure self, str label)

	cpdef dict getLabeledAtoms(Structure self)

	cpdef bint isAtomInCycle(Structure self, Atom atom)

	cpdef bint isBondInCycle(Structure self, Bond bond)

	cpdef list getAllCycles(Structure self, Atom atom)

	cpdef bint isCyclic(Structure self)

	cpdef int calculateNumberOfRotors(Structure self)
		
	cpdef bint isLinear(Structure self)

	cpdef int calculateAtomSymmetryNumber(Structure self, Atom atom)

	cpdef int calculateBondSymmetryNumber(Structure self, Bond bond)

	cpdef int calculateAxisSymmetryNumber(Structure self)

	cpdef int calculateCyclicSymmetryNumber(Structure self)

	cpdef int calculateSymmetryNumber(Structure self)

	cpdef int countInternalRotors(Structure self)

	cpdef calculateLennardJonesParameters(Structure self)