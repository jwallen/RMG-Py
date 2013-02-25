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

################################################################################

cdef class Vertex(object):

    cpdef Vertex copy(self)

    cpdef bint equivalent(self, Vertex other) except -2

    cpdef bint isSpecificCaseOf(self, Vertex other) except -2
    
################################################################################

cdef class Edge(object):

    cpdef Edge copy(self)

    cpdef bint equivalent(Edge self, Edge other) except -2

    cpdef bint isSpecificCaseOf(self, Edge other) except -2

################################################################################

cdef class Graph:
    
    # Dict-of-dicts representation (fast editing)
    cdef list vertices_dod
    cdef dict edges_dod
    
    # Compressed sparse row representation (fast iterating)
    cdef Vertex[::1] vertices_csr
    cdef Edge[::1] edges_csr                # Array of edges
    cdef numpy.int32_t[::1] rows_csr        # Array of indices of first nonzero element of each row
    cdef numpy.int32_t[::1] cols_csr        # Array of column index of each element in edgelist
    
    # For graph isomorphism
    cdef readonly numpy.int32_t[:,::1] connectivity
    
    cpdef bint isEditable(self) except -2
    
    cpdef bint isTraversable(self) except -2
    
    cpdef setEditable(self)
    
    cpdef setTraversable(self)
    
    cpdef toDictOfDictsFormat(self)
            
    cpdef toCompressedSparseRowFormat(self)

    cpdef Vertex addVertex(self, Vertex vertex)

    cpdef Edge addEdge(self, Vertex vertex1, Vertex vertex2, Edge edge)

    cpdef dict getEdges(self, Vertex vertex)

    cpdef Edge getEdge(self, Vertex vertex1, Vertex vertex2)

    cpdef bint hasVertex(self, Vertex vertex) except -2

    cpdef bint hasEdge(self, Vertex vertex1, Vertex vertex2) except -2

    cpdef removeVertex(self, Vertex vertex)

    cpdef removeEdge(self, Vertex vertex1, Vertex vertex2)

    cpdef Graph copy(self, bint deep=?)

    cpdef Graph merge(self, Graph other)

    cpdef list split(self)

    cpdef resetConnectivityValues(self)

    cpdef updateConnectivityValues(self)

    cpdef sortVertices(self)

    cpdef bint isIsomorphic(self, Graph other, dict initialMap=?) except -2

    cpdef list findIsomorphism(self, Graph other, dict initialMap=?)

    cpdef bint isSubgraphIsomorphic(self, Graph other, dict initialMap=?) except -2

    cpdef list findSubgraphIsomorphisms(self, Graph other, dict initialMap=?)
    
    cpdef bint isMappingValid(self, Graph other, dict mapping) except -2

    cpdef bint isCyclic(self) except -2

    cpdef bint isVertexInCycle(self, Vertex vertex) except -2

    cpdef bint isEdgeInCycle(self, Vertex vertex1, Vertex vertex2) except -2

    cpdef bint __isChainInCycle(self, list chain) except -2

    cpdef list getAllCyclicVertices(self)
    
    cpdef list getAllPolycyclicVertices(self)

    cpdef list getAllCycles(self, Vertex startingVertex)

    cpdef list __exploreCyclesRecursively(self, list chain, list cycles)

    cpdef list getSmallestSetOfSmallestRings(self)
