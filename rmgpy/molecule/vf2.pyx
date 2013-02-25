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

"""
This module contains graph ismorphism functions that implement the VF2
algorithm of Vento and Foggia.
"""

import numpy

from cpython.sequence cimport PySequence_Index

################################################################################

class VF2Error(Exception):
    """
    An exception raised if an error occurs within the VF2 graph isomorphism
    algorithm. Pass a string describing the error.
    """
    pass

cdef class VF2:
    """
    An implementation of the second version of the Vento-Foggia (VF2) algorithm
    for graph and subgraph isomorphism.
    """
    
    def __init__(self):
        self.graph1 = None
        self.graph2 = None

    cpdef bint isIsomorphic(self, Graph graph1, Graph graph2, dict initialMapping) except -2:
        """
        Return ``True`` if graph `graph1` is isomorphic to graph `graph2` with
        the optional initial mapping `initialMapping`, or ``False`` otherwise.
        """
        self.isomorphism(graph1, graph2, initialMapping, False, False)
        return self.isMatch
        
    cpdef list findIsomorphism(self, Graph graph1, Graph graph2, dict initialMapping):
        """
        Return a list of dicts of all valid isomorphism mappings from graph
        `graph1` to graph `graph2` with the optional initial mapping 
        `initialMapping`. If no valid isomorphisms are found, an empty list is
        returned.
        """
        self.isomorphism(graph1, graph2, initialMapping, False, True)
        return self.mappingList

    cpdef bint isSubgraphIsomorphic(self, Graph graph1, Graph graph2, dict initialMapping) except -2:
        """
        Return ``True`` if graph `graph1` is subgraph isomorphic to subgraph
        `graph2` with the optional initial mapping `initialMapping`, or
        ``False`` otherwise.
        """
        self.isomorphism(graph1, graph2, initialMapping, True, False)
        return self.isMatch

    cpdef list findSubgraphIsomorphisms(self, Graph graph1, Graph graph2, dict initialMapping):
        """
        Return a list of dicts of all valid subgraph isomorphism mappings from
        graph `graph1` to subgraph `graph2` with the optional initial mapping 
        `initialMapping`. If no valid subgraph isomorphisms are found, an empty
        list is returned.
        """
        self.isomorphism(graph1, graph2, initialMapping, True, True)
        return self.mappingList
        
    cdef isomorphism(self, Graph graph1, Graph graph2, dict initialMapping, bint subgraph, bint findAll):
        """
        Evaluate the isomorphism relationship between graphs `graph1` and
        `graph2` with optional initial mapping `initialMapping`. If `subgraph`
        is ``True``, `graph2` is treated as a possible subgraph of `graph1`.
        If `findAll` is ``True``, all isomorphisms are found; otherwise only
        the first is found.
        """
        cdef int callDepth, index1, index2
        
        self.graph1 = graph1
        if graph1.vertices_csr is None: graph1.setTraversable()
        self.Nvertices1 = graph1.vertices_csr.shape[0]
        self.Nedges1 = graph1.edges_csr.shape[0]
        self.mapping1 = numpy.empty(self.Nvertices1, numpy.int32)
        self.terminal1 = numpy.empty(self.Nvertices1, numpy.int32)
            
        self.graph2 = graph2
        if graph2.vertices_csr is None: graph2.setTraversable()
        self.Nvertices2 = graph2.vertices_csr.shape[0]
        self.Nedges2 = graph2.edges_csr.shape[0]
        self.mapping2 = numpy.empty(self.Nvertices2, numpy.int32)
        self.terminal2 = numpy.empty(self.Nvertices2, numpy.int32)
            
        self.initialMapping = initialMapping
        self.subgraph = subgraph
        self.findAll = findAll
    
        # Clear previous result
        self.isMatch = False
        self.mappingList = []
        
        # Some quick isomorphism checks based on graph sizes
        if not self.subgraph and self.Nvertices2 != self.Nvertices1:
            # The two graphs don't have the same number of vertices, so they
            # cannot be isomorphic
            return
        elif not self.subgraph and self.Nvertices2 == self.Nvertices1 == 0:
            # The two graphs don't have any vertices; this means they are
            # trivially isomorphic
            self.isMatch = True
            return
        elif self.subgraph and self.Nvertices2 > self.Nvertices1:
            # The second graph has more vertices than the first, so it cannot be
            # a subgraph of the first
            return

        # Initialize callDepth with the size of the smallest graph
        # Each recursive call to VF2_match will decrease it by one;
        # when the whole graph has been explored, it should reach 0
        # It should never go below zero!
        callDepth = self.Nvertices2
        
        # Initialize mapping by clearing any previous mapping information
        for index1 in range(self.Nvertices1):
            self.mapping1[index1] = -1
            self.terminal1[index1] = 0
        for index2 in range(self.Nvertices2):
            self.mapping2[index2] = -1
            self.terminal2[index2] = 0
            
        # Set the initial mapping if provided
        if initialMapping is not None:
            assert len(initialMapping) <= self.Nvertices2
            for vertex1, vertex2 in initialMapping.items():
                index1 = PySequence_Index(graph1.vertices_csr, vertex1)     # graph1.vertices_csr.index(vertex1)
                index2 = PySequence_Index(graph2.vertices_csr, vertex2)     # graph2.vertices_csr.index(vertex2)
                self.addToMapping(index1, index2)
                callDepth -= 1

        self.match(callDepth)

    cdef bint match(self, int callDepth) except -2:
        """
        Recursively search for pairs of vertices to match, until all vertices
        are matched or the viable set of matches is exhausted. The `callDepth`
        parameter helps ensure we never enter an infinite loop.
        """

        cdef int index1, index2
        cdef bint hasTerminals
        
        # The call depth should never be negative!
        if callDepth < 0:
            raise VF2Error('Negative call depth encountered in VF2_match().')

        # Done if we have mapped to all vertices in graph
        if callDepth == 0:
            if self.findAll:
                mapping = {}
                for index2 in range(self.Nvertices2):
                    index1 = self.mapping2[index2]
                    assert index1 != -1
                    assert self.mapping1[index1] == index2
                    vertex1 = self.graph1.vertices_csr[index1]
                    vertex2 = self.graph2.vertices_csr[index2]
                    mapping[vertex1] = vertex2
                self.mappingList.append(mapping)
            self.isMatch = True
            return True

        # Create list of pairs of candidates for inclusion in mapping
        hasTerminals = False
        for index2 in range(self.Nvertices2):
            if self.terminal2[index2] != 0:
                # graph2 has terminals, so graph1 also must have terminals
                hasTerminals = True
                break
        else:
            index2 = 0
        
        for index1 in range(self.Nvertices1):
            # If terminals are available, then skip vertices in the first
            # graph that are not terminals
            if hasTerminals and self.terminal1[index1] == 0: continue
            
            # Propose a pairing
            if self.feasible(index1, index2):
                # Add proposed match to mapping
                self.addToMapping(index1, index2)
                # Recurse
                isMatch = self.match(callDepth-1)
                if isMatch and not self.findAll:
                    return True
                # Undo proposed match
                self.removeFromMapping(index1, index2)

        # None of the proposed matches led to a complete isomorphism, so return False
        return False     
 
    cdef bint feasible(self, int index1, int index2) except -2:
        """
        Return ``True`` if vertex `vertex1` from the first graph is a feasible
        match for vertex `vertex2` from the second graph, or ``False`` if not.
        The semantic and structural relationship of the vertices is evaluated,
        including several structural "look-aheads" that cheaply eliminate many
        otherwise feasible pairs.
        """

        cdef Vertex vertex1, vertex2
        cdef Edge edge1, edge2
        cdef int colA, indexA
        cdef int colB, indexB
        cdef int term1Count, term2Count, neither1Count, neither2Count
        cdef numpy.int32_t[::1] rows1, rows2
        
        if not self.subgraph:
            # To be feasible the connectivity values must be an exact match
            if self.graph1.connectivity[index1,0] != self.graph2.connectivity[index2,0]: return False
            if self.graph1.connectivity[index1,1] != self.graph2.connectivity[index2,1]: return False
            if self.graph1.connectivity[index1,2] != self.graph2.connectivity[index2,2]: return False
        
        vertex1 = self.graph1.vertices_csr[index1]
        vertex2 = self.graph2.vertices_csr[index2]
        
        # Semantic check #1: vertex1 and vertex2 must be equivalent
        if self.subgraph:
            if not vertex1.isSpecificCaseOf(vertex2): return False
        else:
            if not vertex1.equivalent(vertex2): return False
        
        # Semantic check #2: adjacent vertices to vertex1 and vertex2 that are
        # already mapped should be connected by equivalent edges
        for colB in range(self.graph2.rows_csr[index2], self.graph2.rows_csr[index2+1]):
            indexB = self.graph2.cols_csr[colB]
            indexA = self.mapping2[indexB]
            if indexA != -1:
                for colA in range(self.graph1.rows_csr[index1], self.graph1.rows_csr[index1+1]):
                    if self.graph1.cols_csr[colA] == indexA:
                        break
                else:
                    # The vertices are joined in graph2, but not in graph1
                    return False
                edge1 = self.graph1.edges_csr[colA]
                edge2 = self.graph2.edges_csr[colB]
                if self.subgraph:
                    if not edge1.isSpecificCaseOf(edge2): return False
                else:
                    if not edge1.equivalent(edge2): return False
        
        # There could still be edges in graph1 that aren't in graph2; this is okay
        # for subgraph matching, but not for exact matching
        if not self.subgraph:
            for colA in range(self.graph1.rows_csr[index1], self.graph1.rows_csr[index1+1]):
                indexA = self.graph1.cols_csr[colA]
                indexB = self.mapping1[indexA]
                if indexB != -1:
                    for colB in range(self.graph2.rows_csr[index2], self.graph2.rows_csr[index2+1]):
                        if self.graph2.cols_csr[colB] == indexB:
                            break
                    else:
                        # The vertices are joined in graph1, but not in graph2
                        return False
                    
        # Count number of terminals adjacent to vertex1 and vertex2
        term1Count = 0; term2Count = 0; neither1Count = 0; neither2Count = 0
        for colA in range(self.graph1.rows_csr[index1], self.graph1.rows_csr[index1+1]):
            indexA = self.graph1.cols_csr[colA]
            if self.terminal1[indexA] != 0: term1Count += 1
            elif self.mapping1[indexA] != -1: neither1Count += 1
        for colB in range(self.graph2.rows_csr[index2], self.graph2.rows_csr[index2+1]):
            indexB = self.graph2.cols_csr[colB]
            if self.terminal2[indexB] != 0: term2Count += 1
            elif self.mapping2[indexB] != -1: neither2Count += 1
        
        # Level 2 look-ahead: the number of adjacent vertices of vertex1 and
        # vertex2 that are non-terminals must be equal
        if self.subgraph:
            if neither1Count < neither2Count: return False
        else:
            if neither1Count != neither2Count: return False

        # Level 1 look-ahead: the number of adjacent vertices of vertex1 and
        # vertex2 that are terminals must be equal
        if self.subgraph:
            if term1Count < term2Count: return False
        else:
            if term1Count != term2Count: return False
        
        # Level 0 look-ahead: all adjacent vertices of vertex2 already in the
        # mapping must map to adjacent vertices of vertex1
        # Also, all adjacent vertices of vertex1 already in the mapping must map to
        # adjacent vertices of vertex2, unless we are subgraph matching
        # This is already done as part of semantic check #2 above, so we don't
        # need to repeat it heere

        # All of our tests have been passed, so the two vertices are a feasible pair
        return True
        
    cdef addToMapping(self, int index1, int index2):
        """
        Add as valid a mapping of vertex `vertex1` from the first graph to
        vertex `vertex2` from the second graph, and update the terminals
        status accordingly.        
        """
        
        cdef int index, col
        
        # Map the vertices to one another
        self.mapping1[index1] = index2
        self.mapping2[index2] = index1
        
        # Remove these vertices from the set of terminals
        self.terminal1[index1] = 0
        self.terminal2[index2] = 0

        # Add any neighboring vertices not already in mapping to terminals
        for col in range(self.graph1.rows_csr[index1], self.graph1.rows_csr[index1+1]):
            index = self.graph1.cols_csr[col]
            self.terminal1[index] = (1 if self.mapping1[index] == -1 else 0)
        for col in range(self.graph2.rows_csr[index2], self.graph2.rows_csr[index2+1]):
            index = self.graph2.cols_csr[col]
            self.terminal2[index] = (1 if self.mapping2[index] == -1 else 0)
        
    cdef removeFromMapping(self, int index1, int index2):
        """
        Remove as valid a mapping of vertex `vertex1` from the first graph to
        vertex `vertex2` from the second graph, and update the terminals
        status accordingly.        
        """
        
        cdef int index0, col0
        cdef int index, col
    
        # Unmap the vertices from one another
        self.mapping1[index1] = -1
        self.mapping2[index2] = -1
        
        # Restore these vertices to the set of terminals 
        # (only if they are adjacent to any other mapped vertices)
        for col in range(self.graph1.rows_csr[index1], self.graph1.rows_csr[index1+1]):
            index = self.graph1.cols_csr[col]
            if self.mapping1[index] != -1:
                self.terminal1[index1] = 1
                break
        else:
            self.terminal1[index1] = 0
        for col in range(self.graph2.rows_csr[index2], self.graph2.rows_csr[index2+1]):
            index = self.graph2.cols_csr[col]
            if self.mapping2[index] != -1:
                self.terminal2[index2] = 1
                break
        else:
            self.terminal2[index2] = 0
        
        # Recompute the terminal status of any neighboring atoms
        for col0 in range(self.graph1.rows_csr[index1], self.graph1.rows_csr[index1+1]):
            index0 = self.graph1.cols_csr[col0]
            for col in range(self.graph1.rows_csr[index0], self.graph1.rows_csr[index0+1]):
                index = self.graph1.cols_csr[col]
                if self.mapping1[index] != -1:
                    self.terminal1[index0] = (1 if self.mapping1[index0] == -1 else 0)
                    break
            else:
                self.terminal1[index0] = 0
        for col0 in range(self.graph2.rows_csr[index2], self.graph2.rows_csr[index2+1]):
            index0 = self.graph2.cols_csr[col0]
            for col in range(self.graph2.rows_csr[index0], self.graph2.rows_csr[index0+1]):
                index = self.graph2.cols_csr[col]
                if self.mapping2[index] != -1:
                    self.terminal2[index0] = (1 if self.mapping2[index0] == -1 else 0)
                    break
            else:
                self.terminal2[index0] = 0
