################################################################################
#
#   RMG - Reaction Mechanism Generator
#
#   Copyright (c) 2009-2011 by the RMG Team (rmg_dev@mit.edu)
#
#   Permission is hereby granted, free of charge, to any person obtaining a
#   copy of this software and associated documentation files (the 'Software'),
#   to deal in the Software without restriction, including without limitation
#   the rights to use, copy, modify, merge, publish, distribute, sublicense,
#   and/or sell copies of the Software, and to permit persons to whom the
#   Software is furnished to do so, subject to the following conditions:
#
#   The above copyright notice and this permission notice shall be included in
#   all copies or substantial portions of the Software.
#
#   THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
#   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
#   DEALINGS IN THE SOFTWARE.
#
################################################################################

cimport numpy

from .graph cimport Vertex, Edge, Graph

cdef class VF2:

    cdef Graph graph1, graph2
    cdef int Nvertices1, Nvertices2
    cdef int Nedges1, Nedges2
    cdef numpy.int32_t[::1] mapping1, mapping2
    cdef numpy.int32_t[::1] terminal1, terminal2

    cdef dict initialMapping
    cdef bint subgraph
    cdef bint findAll
    
    cdef bint isMatch
    cdef list mappingList

    cpdef bint isIsomorphic(self, Graph graph1, Graph graph2, dict initialMapping) except -2
        
    cpdef list findIsomorphism(self, Graph graph1, Graph graph2, dict initialMapping)

    cpdef bint isSubgraphIsomorphic(self, Graph graph1, Graph graph2, dict initialMapping) except -2

    cpdef list findSubgraphIsomorphisms(self, Graph graph1, Graph graph2, dict initialMapping)

    cdef isomorphism(self, Graph graph1, Graph graph2, dict initialMapping, bint subgraph, bint findAll)

    cdef bint match(self, int callDepth) except -2

    cdef bint feasible(self, int index1, int index2) except -2

    cdef addToMapping(self, int index1, int index2)
        
    cdef removeFromMapping(self, int index1, int index2)
