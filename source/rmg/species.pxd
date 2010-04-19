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

################################################################################

cdef class LennardJones:

	cdef public double sigma
	cdef public double epsilon
	
	cpdef fromXML(LennardJones self, document, rootElement)

	cpdef toXML(LennardJones self, document, rootElement)

################################################################################

cdef class ThermoSnapshot:
	
	cdef public double temperature
	cdef public double heatCapacity
	cdef public double enthalpy
	cdef public double entropy
	cdef public double freeEnergy

	cpdef bint isValid(ThermoSnapshot self, double temperature)

	cpdef update(ThermoSnapshot self, double temperature, object thermoData)

################################################################################

cdef class Species:
	
	cdef public object id
	cdef public str label
	cdef public LennardJones lennardJones
	cdef public bint reactive
	cdef public object spectralData
	cdef public double E0
	cdef public double expDownParam
	cdef public list structure
	cdef public object thermoData
	cdef public ThermoSnapshot thermoSnapshot
		
	cpdef toCantera(Species self)
		
	cpdef str getFormula(Species self)

	cpdef fromXML(Species self, document, rootElement)

	cpdef toXML(Species self, document, rootElement)

	cpdef fromAdjacencyList(Species self, str adjstr)

	cpdef fromCML(Species self, str cmlstr)
	
	cpdef fromInChI(Species self, str inchistr)

	cpdef fromSMILES(Species self, str smilesstr)

	cpdef fromOBMol(Species self, obmol)

	cpdef str toCML(Species self)

	cpdef str toInChI(Species self)

	cpdef toOBMol(Species self)

	cpdef str toSMILES(Species self)

	cpdef str toAdjacencyList(Species self, bint strip_hydrogens=?)

	cpdef getResonanceIsomers(Species self)
	
	cpdef getThermoData(Species self)
		
	cpdef object generateThermoData(Species self, thermoClass=?)

	cpdef generateSpectralData(Species self)

	cpdef calculateDensityOfStates(Species self, Elist)

	cpdef double getHeatCapacity(Species self, double T)

	cpdef double getEnthalpy(Species self, double T)

	cpdef double getEntropy(Species self, double T)

	cpdef double getFreeEnergy(Species self, double T)

	cpdef double getMolecularWeight(Species self)

	cpdef bint isIsomorphic(Species self, object other)
	
	cpdef bint isSubgraphIsomorphic(Species self, Structure other)

	cpdef findSubgraphIsomorphisms(Species self, Structure other)

	cpdef calculateLennardJonesParameters(Species self)

################################################################################

cpdef checkForExistingSpecies(Structure structure)

cpdef makeNewSpecies(Structure structure, str label=?, bint reactive=?, bint checkExisting=?)

cpdef processNewSpecies(Species spec)

