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

from species cimport Species
from reaction cimport Reaction

################################################################################

cdef class ReactionModel:

	cdef public list species
	cdef public list reactions

################################################################################

cdef class CoreEdgeReactionModel:

	cdef public ReactionModel core
	cdef public ReactionModel edge
	cdef public double absoluteTolerance
	cdef public double relativeTolerance
	cdef public double fluxToleranceKeepInEdge
	cdef public double fluxToleranceMoveToCore
	cdef public double fluxToleranceInterrupt
	cdef public int maximumEdgeSpecies
	cdef public list termination
	cdef public list unirxnNetworks
	cdef public int networkCount

	cpdef initialize(CoreEdgeReactionModel self, list coreSpecies)

	cpdef enlarge(CoreEdgeReactionModel self, object newObject)

	cpdef addSpeciesToCore(CoreEdgeReactionModel self, Species spec)

	cpdef addSpeciesToEdge(CoreEdgeReactionModel self, Species spec)

	cpdef removeSpeciesFromEdge(CoreEdgeReactionModel self, Species spec)

	cpdef addReactionToCore(CoreEdgeReactionModel self, Reaction rxn)

	cpdef addReactionToEdge(CoreEdgeReactionModel self, Reaction rxn)

	cpdef tuple getLists(CoreEdgeReactionModel self)

	cpdef getStoichiometryMatrix(CoreEdgeReactionModel self)

	cpdef getReactionRates(CoreEdgeReactionModel self, double T, double P, dict Ci)

	cpdef addReactionToUnimolecularNetworks(CoreEdgeReactionModel self, Reaction newReaction)

	cpdef updateUnimolecularReactionNetworks(CoreEdgeReactionModel self)

	cpdef loadSeedMechanism(CoreEdgeReactionModel self, str path)

################################################################################

cdef class TemperatureModel:

	cdef public str type
	cdef public list temperatures
	
	cpdef bint isIsothermal(TemperatureModel self)

	cpdef setIsothermal(TemperatureModel self, double temperature)

	cpdef double getTemperature(TemperatureModel self, double time=?)

################################################################################

cdef class PressureModel:

	cdef public str type
	cdef public list pressures
	
	cpdef bint isIsobaric(PressureModel self)

	cpdef setIsobaric(PressureModel self, double pressure)

	cpdef double getPressure(PressureModel self, double time=?)

################################################################################

cdef class IdealGas:

	cpdef double getTemperature(IdealGas self, double P, double V, object N)

	cpdef double getPressure(IdealGas self, double T, double V, object N)

	cpdef double getVolume(IdealGas self, double T, double P, object N)

	cpdef double getdPdV(IdealGas self, double P, double V, double T, object N)

	cpdef double getdPdT(IdealGas self, double P, double V, double T, object N)

	cpdef double getdVdT(IdealGas self, double P, double V, double T, object N)

	cpdef double getdVdP(IdealGas self, double P, double V, double T, object N)

	cpdef double getdTdP(IdealGas self, double P, double V, double T, object N)

	cpdef double getdTdV(IdealGas self, double P, double V, double T, object N)

	cpdef double getdPdNi(IdealGas self, double P, double V, double T, object N, int i)

	cpdef double getdTdNi(IdealGas self, double P, double V, double T, object N, int i)

	cpdef double getdVdNi(IdealGas self, double P, double V, double T, object N, int i)

################################################################################

cdef class IncompressibleLiquid:

	cdef public double P
	cdef public double V
	cdef public double T
	cdef public double N
	cdef public double Vmol

	cpdef double getTemperature(self, double P, double V, object N)

	cpdef double getPressure(self, double T, double V, object N)

	cpdef double getVolume(self, double T, double P, object N)

	cpdef double getdPdV(self, double P, double V, double T, object N)

	cpdef double getdPdT(self, double P, double V, double T, object N)

	cpdef double getdVdT(self, double P, double V, double T, object N)

	cpdef double getdVdP(self, double P, double V, double T, object N)

	cpdef double getdTdP(self, double P, double V, double T, object N)

	cpdef double getdTdV(self, double P, double V, double T, object N)

	cpdef double getdPdNi(self, double P, double V, double T, object N, int i)

	cpdef double getdTdNi(self, double P, double V, double T, object N, int i)

	cpdef double getdVdNi(self, double P, double V, double T, object N, int i)

################################################################################

cdef class ReactionSystem:

	cdef public TemperatureModel temperatureModel
	cdef public PressureModel pressureModel
	cdef public object volumeModel
	cdef public dict initialConcentration

	cpdef setModels(ReactionSystem self, TemperatureModel temperatureModel, PressureModel pressureModel, object volumeModel)

################################################################################

cdef class TerminationTime:

	cdef public double time

################################################################################

cdef class TerminationConversion:

	cdef public Species species
	cdef public double conversion

