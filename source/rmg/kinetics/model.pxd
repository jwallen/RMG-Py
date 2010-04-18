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



################################################################################

cdef class KineticsModel:
	
	cdef public double Tmin
	cdef public double Tmax
	cdef public double Pmin
	cdef public double Pmax
	cdef public int rank
	cdef public str comment
	cdef public int numReactants

	cpdef bint isTemperatureInRange(KineticsModel self, double T)

	cpdef bint isPressureInRange(KineticsModel self, double P)

################################################################################

cdef class ArrheniusModel(KineticsModel):
	
	cdef public double A
	cdef public double Ea
	cdef public double n
	
	cpdef bint equals(ArrheniusModel self, ArrheniusModel other)

	cpdef double getRateConstant(ArrheniusModel self, double T, double P=?)
	
	cpdef ArrheniusModel getReverse(ArrheniusModel self, double dHrxn, double Keq, double T)
	
	cpdef fitToData(ArrheniusModel self, Tlist, K)

################################################################################

cdef class ArrheniusEPModel(KineticsModel):
	
	cdef public double A
	cdef public double E0
	cdef public double n
	cdef public double alpha
	
	cpdef bint equals(ArrheniusEPModel self, ArrheniusEPModel other)

	cpdef double getActivationEnergy(ArrheniusEPModel self, double dHrxn)

	cpdef ArrheniusModel getArrhenius(ArrheniusEPModel self, double dHrxn)

	cpdef double getRateConstant(ArrheniusEPModel self, double T, double dHrxn)

	cpdef fromDatabase(ArrheniusEPModel self, list data, str comment, int numReactants)

################################################################################

cdef class PDepArrheniusModel(KineticsModel):
	
	cdef public list pressures
	cdef public list arrhenius

	cpdef __getAdjacentExpressions(PDepArrheniusModel self, double P)

	cpdef double getRateConstant(PDepArrheniusModel self, double T, double P)

	cpdef fitToData(PDepArrheniusModel self, list Tlist, list Plist, object K)

	cpdef ArrheniusModel getArrhenius(PDepArrheniusModel self, double P)

################################################################################

cdef class ChebyshevModel(KineticsModel):
	
	cdef public int degreeT
	cdef public int degreeP
	cdef public object coeffs

	cpdef double __chebyshev(ChebyshevModel self, int n, double x)

	cpdef double __getReducedTemperature(ChebyshevModel self, double T)
	
	cpdef double __getReducedPressure(ChebyshevModel self, double P)
	
	cpdef double getRateConstant(ChebyshevModel self, double T, double P)
	
	cpdef fitToData(ChebyshevModel self, list Tlist, list Plist, object K, int degreeT, int degreeP)

