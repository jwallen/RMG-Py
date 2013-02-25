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
This module contains an implementation of a graph data structure (the 
:class:`Graph` class) and functions for manipulating that graph, including 
efficient isomorphism functions. This module also contains base classes for
the vertices and edges (:class:`Vertex` and :class:`Edge`, respectively) that
are the components of a graph.
"""

import logging

import numpy

from .vf2 cimport VF2

################################################################################

cdef class Vertex(object):
    """
    A base class for vertices in a graph.
    """

    def __reduce__(self):
        """
        A helper function used when pickling an object.
        """
        return (Vertex, ())

    cpdef Vertex copy(self):
        """
        Return a copy of the vertex. The default implementation assumes that no
        semantic information is associated with each vertex, and therefore
        simply returns a new :class:`Vertex` object.
        """
        new = Vertex()
        return new

    cpdef bint equivalent(self, Vertex other) except -2:
        """
        Return ``True`` if vertices `self` and `other` are semantically
        equivalent, or ``False`` if not. You should reimplement this function
        in a derived class if your vertices have semantic information.
        """
        return True

    cpdef bint isSpecificCaseOf(self, Vertex other) except -2:
        """
        Return ``True`` if vertex `self` is semantically a subtype of vertex 
        `other`, or ``False`` if not. You should reimplement this function in a
        derived class if your edges have semantic information.
        """
        return True

################################################################################

cdef class Edge(object):
    """
    A base class for edges in a graph. This class does *not* store the vertex
    pair that comprises the edge; that functionality would need to be included
    in the derived class.
    """

    def __reduce__(self):
        """
        A helper function used when pickling an object.
        """
        return (Edge, ())

    cpdef Edge copy(self):
        """
        Return a copy of the edge. The default implementation assumes that no
        semantic information is associated with each edge, and therefore
        simply returns a new :class:`Edge` object.
        """
        new = Edge()
        return new

    cpdef bint equivalent(self, Edge other) except -2:
        """
        Return ``True`` if two edges `self` and `other` are semantically
        equivalent, or ``False`` if not. You should reimplement this
        function in a derived class if your edges have semantic information.
        """
        return True

    cpdef bint isSpecificCaseOf(self, Edge other) except -2:
        """
        Return ``True`` if edge `self` is semantically a subtype of edge 
        `other`, or ``False`` if not. You should reimplement this function in a
        derived class if your edges have semantic information.
        """
        return True

################################################################################

cdef VF2 vf2 = VF2()

cdef class Graph:

    def __init__(self, vertices=None, edges=None):
        # Dict-of-dicts representation (fast editing)
        self.vertices_dod = vertices or []
        self.edges_dod = edges or {}
        # Compressed sparse row representation (fast iterating)
        self.vertices_csr = None
        self.edges_csr = None
        self.rows_csr = None
        self.cols_csr = None
        self.connectivity = None

    def __reduce__(self):
        """
        A helper function used when pickling an object.
        """
        return (Graph, (self.vertices, self.edges))
    
    property vertices:
        def __get__(self):
            cdef int i
            if self.vertices_dod is not None:
                return self.vertices_dod
            elif self.vertices_csr is not None:
                vertices_dod = []
                for i in range(self.vertices_csr.shape[0]):
                    vertices_dod.append(self.vertices_csr[i])
                return vertices_dod
            else:
                return []

    property edges:
        def __get__(self):
            cdef int row, col
            if self.edges_dod is not None:
                return self.edges_dod
            elif self.edges_csr is not None:
                edges_dod = {}
                for row in range(self.vertices_csr.shape[0]):
                    vertex1 = self.vertices_csr[row]
                    edges = {}
                    edges_dod[vertex1] = edges
                    for col in range(self.rows_csr[row], self.rows_csr[row+1]):
                        edge = self.edges_csr[col]
                        vertex2 = self.vertices_csr[self.cols_csr[col]]
                        edges[vertex2] = edge
                return edges_dod
            else:
                return {}
            
    cpdef bint isEditable(self) except -2:
        """
        Return ``True`` if the graph is currently stored in a format suitable
        for quick editing, or ``False`` otherwise.
        """
        return self.vertices_dod is not None
    
    cpdef bint isTraversable(self) except -2:
        """
        Return ``True`` if the graph is currently stored in a format suitable
        for quick traversal, or ``False`` otherwise.
        """
        return self.vertices_csr is not None
    
    cpdef setEditable(self):
        """
        Convert the internal representation of the graph to a format suitable
        for quick editing.
        """
        if self.vertices_dod is not None: return
        # Set to dict-of-dicts format (fast editing)
        self.toDictOfDictsFormat()
            
    cpdef setTraversable(self):
        """
        Convert the internal representation of the graph to a format suitable
        for quick traversal.
        """
        if self.vertices_csr is not None: return
        # Set to compressed sparse row format (fast iterating)
        self.toCompressedSparseRowFormat()
            
    cpdef toDictOfDictsFormat(self):
        """
        Convert the internal representation of the graph to use dict-of-dicts
        (DoD) format. This format provides very efficient editing of the items
        in the graph, but very slow traversal.
        """
        cdef int Nvertices, Nedges, row, col, index
        cdef dict edges
        
        Nvertices = self.vertices_csr.shape[0]
        Nedges = self.edges_csr.shape[0]
        
        self.vertices_dod = []
        self.edges_dod = {}
        
        for row in range(Nvertices):
            vertex1 = self.vertices_csr[row]
            self.vertices_dod.append(vertex1)
            edges = {}
            self.edges_dod[vertex1] = edges
            for col in range(self.rows_csr[row], self.rows_csr[row+1]):
                edge = self.edges_csr[col]
                vertex2 = self.vertices_csr[self.cols_csr[col]]
                edges[vertex2] = edge
                
        # Clear compressed sparse row format data
        self.vertices_csr = None
        self.edges_csr = None
        self.rows_csr = None
        self.cols_csr = None
   
    cpdef toCompressedSparseRowFormat(self):
        """
        Convert the internal representation of the graph to use compressed
        sparse row (CSR) format. This format provides very efficient traversal
        of the items in the graph, but very slow editing.
        """
        cdef int Nvertices, Nedges, i, j, index
        cdef Vertex vertex, vertex2
        cdef Edge edge
    
        # First sort the vertices
        self.updateConnectivityValues()
        self.sortVertices()

        # Count the numbers of vertices and edges
        Nvertices = len(self.vertices_dod)
        Nedges = 0
        for i in range(Nvertices):
            Nedges += len(self.edges_dod[self.vertices_dod[i]])
        
        # Allocate memory for the CSR format
        # This should require quite a bit less memory than the DoD format
        self.vertices_csr = numpy.empty(Nvertices, object)  #array(shape=(Nvertices,), itemsize=sizeof(Vertex))
        self.edges_csr = numpy.empty(Nedges, object)  #array(shape=(Nedges,), itemsize=sizeof(Edge))
        self.rows_csr = numpy.empty(Nvertices+1, numpy.int32)
        self.cols_csr = numpy.empty(Nedges, numpy.int32)
        
        # Copy the vertices and edges from the DoD format to the CSR format
        index = 0
        for i in range(Nvertices):
            vertex = self.vertices_dod[i]
            self.vertices_csr[i] = vertex
            self.rows_csr[i] = index
            for vertex2, edge in self.edges_dod[vertex].items():
                j = self.vertices_dod.index(vertex2)
                self.edges_csr[index] = edge
                self.cols_csr[index] = j
                index += 1
        self.rows_csr[Nvertices] = Nedges
        
        # Clear dict of dicts (DoD) format data
        self.vertices_dod = None
        self.edges_dod = None

    cpdef Vertex addVertex(self, Vertex vertex):
        """
        Add a `vertex` to the graph. The vertex is initialized with no edges.
        """
        assert self.isEditable()
        self.vertices_dod.append(vertex)
        self.edges_dod[vertex] = dict()
        return vertex

    cpdef Edge addEdge(self, Vertex vertex1, Vertex vertex2, Edge edge):
        """
        Add an `edge` to the graph. The two vertices in the edge must already
        exist in the graph, or a :class:`ValueError` is raised.
        """
        assert vertex1 is not vertex2
        assert self.isEditable()
        if vertex1 not in self.vertices_dod or vertex2 not in self.vertices_dod:
            raise ValueError('Attempted to add edge between vertices not in the graph.')
        self.edges_dod[vertex1][vertex2] = edge
        self.edges_dod[vertex2][vertex1] = edge
        return edge

    cpdef dict getEdges(self, Vertex vertex):
        """
        Return a list of the edges involving the specified `vertex`.
        """
        cdef int row, col, index
        cdef dict edges
        if self.isEditable():
            try:
                return self.edges_dod[vertex]
            except KeyError:
                raise ValueError('The specified vertex is not in this graph.')
        else:
            for row in range(self.vertices_csr.shape[0]):
                if self.vertices_csr[row] is vertex:
                    edges = {}
                    for col in range(self.rows_csr[row], self.rows_csr[row+1]):
                        index = self.cols_csr[col]
                        edges[self.vertices_csr[index]] = self.edges_csr[col]
                    return edges
            raise ValueError('The specified vertex is not in this graph.')

    cpdef Edge getEdge(self, Vertex vertex1, Vertex vertex2):
        """
        Returns the edge connecting vertices `vertex1` and `vertex2`.
        """
        cdef int row, col, index
        if self.isEditable():
            try:
                return self.edges_dod[vertex1][vertex2]
            except KeyError:
                raise ValueError('The specified vertices are not connected by an edge in this graph.')
        else:
            for row in range(self.vertices_csr.shape[0]):
                if self.vertices_csr[row] is vertex1:
                    for col in range(self.rows_csr[row], self.rows_csr[row+1]):
                        index = self.cols_csr[col]
                        if self.vertices_csr[index] is vertex2:
                            return self.edges_csr[col]
            raise ValueError('The specified vertices are not connected by an edge in this graph.')

    cpdef bint hasVertex(self, Vertex vertex) except -2:
        """
        Returns ``True`` if `vertex` is a vertex in the graph, or ``False`` if
        not.
        """
        if self.isEditable():
            return vertex in self.vertices_dod
        else:
            return vertex in self.vertices_csr

    cpdef bint hasEdge(self, Vertex vertex1, Vertex vertex2) except -2:
        """
        Returns ``True`` if vertices `vertex1` and `vertex2` are connected
        by an edge, or ``False`` if not.
        """
        cdef int i, row, col
        if self.isEditable():
            return vertex1 in self.vertices_dod and vertex2 in self.edges_dod[vertex1]
        else:
            for i in range(self.vertices_csr.shape[0]):
                if self.vertices_csr[i] is vertex1:
                    for row in range(self.rows_csr[i], self.rows_csr[i+1]):
                        col = self.cols_csr[row]
                        if self.vertices_csr[col] is vertex2:
                            return True
            return False

    cpdef removeVertex(self, Vertex vertex):
        """
        Remove `vertex` and all edges associated with it from the graph. Does
        not remove vertices that no longer have any edges as a result of this
        removal.
        """
        assert self.isEditable()
        cdef Vertex vertex2
        for vertex2 in self.edges_dod[vertex]:
            assert vertex2 is not vertex
            del self.edges_dod[vertex2][vertex]
        del self.edges_dod[vertex]
        self.vertices_dod.remove(vertex)

    cpdef removeEdge(self, Vertex vertex1, Vertex vertex2):
        """
        Remove the specified `edge` from the graph.
        Does not remove vertices that no longer have any edges as a result of
        this removal.
        """
        assert self.isEditable()
        del self.edges_dod[vertex1][vertex2]
        del self.edges_dod[vertex2][vertex1]

    cpdef Graph copy(self, bint deep=False):
        """
        Create a copy of the current graph. If `deep` is ``True``, a deep copy
        is made: copies of the vertices and edges are used in the new graph.
        If `deep` is ``False`` or not specified, a shallow copy is made: the
        original vertices and edges are used in the new graph.
        """
        cdef Graph other
        cdef Vertex vertex1, vertex2
        cdef Edge edge
        cdef int Nvertices, row, col, index
        cdef dict mapping
        
        other = Graph()
        mapping = {}
        
        if self.isEditable():
            for vertex1 in self.vertices_dod:
                if deep:
                    mapping[vertex1] = vertex1.copy()
                    other.addVertex(mapping[vertex1])
                else:    
                    other.addVertex(vertex1)
            for vertex1 in self.vertices_dod:
                for vertex2, edge in self.edges_dod[vertex1].items():
                    if deep:
                        other.addEdge(mapping[vertex1], mapping[vertex2], edge.copy())
                    else:
                        other.addEdge(vertex1, vertex2, edge)
        else:
            Nvertices = self.vertices_csr.shape[0]
            for row in range(Nvertices):
                vertex1 = self.vertices_csr[row]
                if deep:
                    mapping[vertex1] = vertex1.copy()
                    other.addVertex(mapping[vertex1])
                else:    
                    other.addVertex(vertex1)
        
            for row in range(Nvertices):
                vertex1 = self.vertices_csr[row]
                for col in range(self.rows_csr[row], self.rows_csr[row+1]):
                    index = self.cols_csr[col]
                    vertex2 = self.vertices_csr[index]
                    edge = self.edges_csr[col]
                    if deep:
                        other.addEdge(mapping[vertex1], mapping[vertex2], edge.copy())
                    else:
                        other.addEdge(vertex1, vertex2, edge)

        return other

    cpdef Graph merge(self, Graph other):
        """
        Merge two graphs so as to store them in a single Graph object.
        """
        cdef Graph graph, new
        cdef Vertex vertex, vertex1, vertex2
        
        assert self.isEditable()
        assert other.isEditable()
        
        # Create output graph
        new = Graph()

        # Add self to output graph
        for vertex1 in self.vertices_dod:
            new.addVertex(vertex1)
        for vertex1 in self.vertices_dod:
            for vertex2, edge in self.edges_dod[vertex1].items():
                new.addEdge(vertex1, vertex2, edge)

        # Add other to output graph
        for vertex1 in other.vertices:
            new.addVertex(vertex1)
        for vertex1 in other.vertices:
            for vertex2, edge in other.edges_dod[vertex1].items():
                new.addEdge(vertex1, vertex2, edge)

        return new

    cpdef list split(self):
        """
        Convert a single Graph object containing two or more unconnected graphs
        into separate graphs.
        """
        cdef Graph new1, new2
        cdef Vertex vertex, vertex1, vertex2
        cdef list verticesToMove
        cdef int index
        
        assert self.isEditable()

        # Create potential output graphs
        new1 = self.copy()
        new2 = Graph()

        if len(self.vertices_dod) == 0:
            return [new1]

        # Arbitrarily choose last atom as starting point
        verticesToMove = [ self.vertices_dod[-1] ]

        # Iterate until there are no more atoms to move
        index = 0
        while index < len(verticesToMove):
            for v2 in self.edges_dod[verticesToMove[index]]:
                if v2 not in verticesToMove:
                    verticesToMove.append(v2)
            index += 1
        
        # If all atoms are to be moved, simply return new1
        if len(new1.vertices) == len(verticesToMove):
            return [new1]

        # Copy to new graph and remove from old graph
        for vertex in verticesToMove:
            new2.addVertex(vertex)
        for vertex1 in verticesToMove:
            for vertex2, edge in new1.edges_dod[vertex1].items():
                new2.addEdge(vertex1, vertex2, edge)
        for vertex in verticesToMove:
            new1.removeVertex(vertex)
        
        new = [new2]
        new.extend(new1.split())
        return new
    
    cpdef resetConnectivityValues(self):
        """
        Reset the connectivity values for each vertex in the graph. This will
        force them to be recalculated.
        """
        self.connectivity = None

    cpdef updateConnectivityValues(self):
        """
        Update the connectivity values for each vertex in the graph. These are
        used to accelerate the isomorphism checking.
        """
        cdef Vertex vertex1, vertex2
        cdef int Nvertices, index1, index2, count, k
        
        assert self.isEditable()
        
        Nvertices = len(self.vertices_dod)
        self.connectivity = numpy.zeros((Nvertices,3), numpy.int32)

        for index1 in range(Nvertices):
            vertex1 = self.vertices_dod[index1]
            count = len(self.edges_dod[vertex1])
            self.connectivity[index1,0] = count
        
        for index1 in range(Nvertices):
            vertex1 = self.vertices_dod[index1]
            count = 0
            for vertex2 in self.edges_dod[vertex1]: 
                index2 = self.vertices_dod.index(vertex2)
                count += self.connectivity[index2,0]
            self.connectivity[index1,1] = count

        for index1 in range(Nvertices):
            vertex1 = self.vertices_dod[index1]
            count = 0
            for vertex2 in self.edges_dod[vertex1]: 
                index2 = self.vertices_dod.index(vertex2)
                count += self.connectivity[index2,1]
            self.connectivity[index1,2] = count
    
    cpdef sortVertices(self):
        """
        Sort the vertices in the graph. This can make certain operations, e.g.
        the isomorphism functions, much more efficient.
        """
        cdef int Nvertices, i, j, index, value
        cdef list vertices
        cdef numpy.int32_t[:,::1] connectivity
        
        # If we need to sort then let's also update the connecitivities so
        # we're sure they are right, since the sorting labels depend on them
        self.updateConnectivityValues()
        
        Nvertices = len(self.vertices_dod)
        
        vertices = []
        for i, vertex in enumerate(self.vertices_dod):
            value = ( -65536*self.connectivity[i,0] - 256*self.connectivity[i,1] - self.connectivity[i,2] )
            vertices.append((value, i, vertex))

        vertices = sorted(vertices)
        connectivity = numpy.zeros((Nvertices,3), numpy.int32)
        
        for i in range(Nvertices):
            value, index, vertex = vertices[i]
            for j in range(3):
                connectivity[i,j] = self.connectivity[index,j]
        
        self.vertices_dod = [vertex for value, index, vertex in vertices]
        self.connectivity = connectivity
        
    cpdef bint isIsomorphic(self, Graph other, dict initialMap=None) except -2:
        """
        Returns :data:`True` if two graphs are isomorphic and :data:`False`
        otherwise. Uses the VF2 algorithm of Vento and Foggia.
        """
        return vf2.isIsomorphic(self, other, initialMap)

    cpdef list findIsomorphism(self, Graph other, dict initialMap=None):
        """
        Returns :data:`True` if `other` is subgraph isomorphic and :data:`False`
        otherwise, and the matching mapping.
        Uses the VF2 algorithm of Vento and Foggia.
        """
        return vf2.findIsomorphism(self, other, initialMap)

    cpdef bint isSubgraphIsomorphic(self, Graph other, dict initialMap=None) except -2:
        """
        Returns :data:`True` if `other` is subgraph isomorphic and :data:`False`
        otherwise. Uses the VF2 algorithm of Vento and Foggia.
        """
        return vf2.isSubgraphIsomorphic(self, other, initialMap)

    cpdef list findSubgraphIsomorphisms(self, Graph other, dict initialMap=None):
        """
        Returns :data:`True` if `other` is subgraph isomorphic and :data:`False`
        otherwise. Also returns the lists all of valid mappings.

        Uses the VF2 algorithm of Vento and Foggia.
        """
        return vf2.findSubgraphIsomorphisms(self, other, initialMap)

    cpdef bint isMappingValid(self, Graph other, dict mapping) except -2:
        """
        Check that a proposed `mapping` of vertices from `self` to `other`
        is valid by checking that the vertices and edges involved in the
        mapping are mutually equivalent.
        """
        cdef Vertex vertex1, vertex2
        cdef list vertices1, vert
        cdef bint selfHasEdge, otherHasEdge
        cdef int i, j
        
        # Check that the mapped pairs of vertices are equivalent
        for vertex1, vertex2 in mapping.items():
            if not vertex1.equivalent(vertex2):
                return False
        
        # Check that any edges connected mapped vertices are equivalent
        vertices1 = mapping.keys()
        vertices2 = mapping.values()
        for i in range(len(vertices1)):
            for j in range(i+1, len(vertices1)):
                selfHasEdge = self.hasEdge(vertices1[i], vertices1[j])
                otherHasEdge = other.hasEdge(vertices2[i], vertices2[j])
                if selfHasEdge and otherHasEdge:
                    # Both graphs have the edge, so we must check it for equivalence
                    edge1 = self.getEdge(vertices1[i], vertices1[j])
                    edge2 = other.getEdge(vertices2[i], vertices2[j])
                    if not edge1.equivalent(edge2):
                        return False
                elif selfHasEdge or otherHasEdge:
                    # Only one of the graphs has the edge, so the mapping must be invalid
                    return False
        
        # If we're here then the vertices and edges are equivalent, so the
        # mapping is valid
        return True

    cpdef bint isCyclic(self) except -2:
        """
        Return ``True`` if one or more cycles are present in the graph or
        ``False`` otherwise.
        """
        cdef Vertex vertex
        for vertex in self.vertices:
            if self.isVertexInCycle(vertex):
                return True
        return False

    cpdef bint isVertexInCycle(self, Vertex vertex) except -2:
        """
        Return ``True`` if the given `vertex` is contained in one or more
        cycles in the graph, or ``False`` if not.
        """
        return self.__isChainInCycle([vertex])

    cpdef bint isEdgeInCycle(self, Vertex vertex1, Vertex vertex2) except -2:
        """
        Return :data:`True` if the edge between vertices `vertex1` and `vertex2`
        is in one or more cycles in the graph, or :data:`False` if not.
        """
        cdef list cycles
        cycles = self.getAllCycles(vertex1)
        for cycle in cycles:
            if vertex2 in cycle:
                return True
        return False

    cpdef bint __isChainInCycle(self, list chain) except -2:
        """
        Return ``True`` if the given `chain` of vertices is contained in one
        or more cycles or ``False`` otherwise. This function recursively calls
        itself.
        """
        cdef Vertex vertex1, vertex2
        cdef Edge edge

        self.setEditable()

        vertex1 = chain[-1]
        for vertex2 in self.edges_dod[vertex1]:
            if vertex2 is chain[0] and len(chain) > 2:
                return True
            elif vertex2 not in chain:
                # Make the chain a little longer and explore again
                chain.append(vertex2)
                if self.__isChainInCycle(chain):
                    # We found a cycle, so the return value must be True
                    return True
                else:
                    # We did not find a cycle down this path, so remove the vertex from the chain
                    chain.remove(vertex2)
        # If we reach this point then we did not find any cycles involving this chain
        return False
    
    cpdef list getAllCyclicVertices(self):
        """ 
        Returns all vertices belonging to one or more cycles.        
        """
        cdef list cyclicVertices
        # Loop through all vertices and check whether they are cyclic
        cyclicVertices = []
        for vertex in self.vertices:
            if self.isVertexInCycle(vertex):
                cyclicVertices.append(vertex)                
        return cyclicVertices
    
    cpdef list getAllPolycyclicVertices(self):
        """
        Return all vertices belonging to two or more cycles, fused or spirocyclic.
        """
        cdef list SSSR, vertices, polycyclicVertices
        SSSR = self.getSmallestSetOfSmallestRings()
        polycyclicVertices = []
        if SSSR:            
            vertices = []
            for cycle in SSSR:
                for vertex in cycle:
                    if vertex not in vertices:
                        vertices.append(vertex)
                    else:
                        if vertex not in polycyclicVertices:
                            polycyclicVertices.append(vertex)     
        return polycyclicVertices                                    

    cpdef list getAllCycles(self, Vertex startingVertex):
        """
        Given a starting vertex, returns a list of all the cycles containing
        that vertex.
        """
        assert self.isEditable()
        return self.__exploreCyclesRecursively([startingVertex], [])

    cpdef list __exploreCyclesRecursively(self, list chain, list cycles):
        """
        Search the graph for cycles by recursive spidering. Given a `chain`
        (list) of connected atoms and a list of `cycles` found so far, find any
        cycles involving the chain of atoms and append them to the list of
        cycles. This function recursively calls itself.
        """
        cdef Vertex vertex1, vertex2
        
        vertex1 = chain[-1]
        # Loop over each of the atoms neighboring the last atom in the chain
        for vertex2 in self.edges_dod[vertex1]:
            if vertex2 is chain[0] and len(chain) > 2:
                # It is the first atom in the chain, so the chain is a cycle!
                cycles.append(chain[:])
            elif vertex2 not in chain:
                # Make the chain a little longer and explore again
                chain.append(vertex2)
                cycles = self.__exploreCyclesRecursively(chain, cycles)
                # Any cycles down this path have now been found, so remove vertex2 from the chain
                chain.pop(-1)
        # At this point we should have discovered all of the cycles involving the current chain
        return cycles

    cpdef list getSmallestSetOfSmallestRings(self):
        """
        Return a list of the smallest set of smallest rings in the graph. The
        algorithm implements was adapted from a description by Fan, Panaye,
        Doucet, and Barbu (doi: 10.1021/ci00015a002)

        B. T. Fan, A. Panaye, J. P. Doucet, and A. Barbu. "Ring Perception: A
        New Algorithm for Directly Finding the Smallest Set of Smallest Rings
        from a Connection Table." *J. Chem. Inf. Comput. Sci.* **33**,
        p. 657-662 (1993).
        """
        cdef Graph graph
        cdef bint done, found
        cdef list cycleList, cycles, cycle, graphs, neighbors, verticesToRemove, vertices
        cdef Vertex vertex, rootVertex

        # Make a copy of the graph so we don't modify the original
        graph = self.copy(deep=True)
        vertices = graph.vertices[:]
        
        # Step 1: Remove all terminal vertices
        done = False
        while not done:
            verticesToRemove = []
            for vertex in graph.vertices:
                if len(graph.edges_dod[vertex]) == 1: verticesToRemove.append(vertex)
            done = len(verticesToRemove) == 0
            # Remove identified vertices from graph
            for vertex in verticesToRemove:
                graph.removeVertex(vertex)

        # Step 2: Remove all other vertices that are not part of cycles
        verticesToRemove = []
        for vertex in graph.vertices:
            found = graph.isVertexInCycle(vertex)
            if not found:
                verticesToRemove.append(vertex)
        # Remove identified vertices from graph
        for vertex in verticesToRemove:
            graph.removeVertex(vertex)

        # Step 3: Split graph into remaining subgraphs
        graphs = graph.split()

        # Step 4: Find ring sets in each subgraph
        cycleList = []
        for graph in graphs:

            while len(graph.vertices) > 0:

                # Choose root vertex as vertex with smallest number of edges
                rootVertex = None
                for vertex in graph.vertices:
                    if rootVertex is None:
                        rootVertex = vertex
                    elif len(graph.edges_dod[vertex]) < len(graph.edges_dod[rootVertex]):
                        rootVertex = vertex

                # Get all cycles involving the root vertex
                cycles = graph.getAllCycles(rootVertex)
                if len(cycles) == 0:
                    # This vertex is no longer in a ring, so remove it
                    graph.removeVertex(rootVertex)
                    continue

                # Keep the smallest of the cycles found above
                cycle = cycles[0]
                for c in cycles[1:]:
                    if len(c) < len(cycle):
                        cycle = c
                cycleList.append(cycle)

                # Remove from the graph all vertices in the cycle that have only two edges
                verticesToRemove = []
                for vertex in cycle:
                    if len(graph.edges_dod[vertex]) <= 2:
                        verticesToRemove.append(vertex)
                if len(verticesToRemove) == 0:
                    # there are no vertices in this cycle that with only two edges
                    # Remove edge between root vertex and any one vertex it is connected to
                    vertex = graph.edges_dod[rootVertex].keys()[0]
                    graph.removeEdge(rootVertex, vertex)
                else:
                    for vertex in verticesToRemove:
                        graph.removeVertex(vertex)

        # Map atoms in cycles back to atoms in original graph
        for i in range(len(cycleList)):
            cycleList[i] = [self.vertices[vertices.index(v)] for v in cycleList[i]]

        return cycleList
