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

cdef extern from "dictobject.h":
	ctypedef class __builtin__.dict [object PyDictObject]:
		pass

################################################################################

cdef class Dictionary(dict):
	
	cpdef load(Dictionary self, str path)
		
	cpdef toStructure(Dictionary self, bint addH=?)

################################################################################

cdef class Tree:
	
	cdef public list top
	cdef public dict parent
	cdef public dict children
	
	cpdef ancestors(Tree self, node)
	
	cpdef descendants(Tree self, node)

	cpdef add(Tree self, node, parent)
			
	cpdef remove(Tree self, node)
		
	cpdef load(Tree self, path)

	cpdef write(Tree self, children)

################################################################################

cdef class Library(dict):
	
	cpdef add(Library self, index, labels, data)
		
	cpdef remove(Library self, labels)
	
	cpdef hashLabels(Library self, labels)
	
	cpdef getData(Library self, key)
	
	cpdef load(Library self, path)

	cpdef parse(Library self, lines, numLabels=?)
		
	cpdef removeLinks(Library self)
			
################################################################################

cdef class Database:
	
	cdef public Dictionary dictionary
	cdef public Tree tree
	cdef public Library library

	cpdef load(Database self, str dictstr, str treestr, str libstr)

	cpdef save(Database self, str dictstr, str treestr, str libstr)

	cpdef isWellFormed(Database self)

	cpdef matchNodeToStructure(Database self, node, structure, atoms)

	cpdef descendTree(Databaseself, structure, atoms, root=?)
		
################################################################################

cdef class LogicNode:

	cdef public str symbol
	cdef public list components
	cdef public bint invert

cdef class LogicOr(LogicNode):

	cpdef matchToStructure(LogicOr self, Database database, structure, atoms)

	cpdef getPossibleStructures(LogicOr self, Dictionary dictionary)

cdef class LogicAnd(LogicNode):

	cpdef matchToStructure(LogicAnd self, Database database, structure, atoms)

cpdef LogicNode makeLogicNode(str string)

################################################################################

cpdef getAllCombinations(nodeLists)

cpdef str removeCommentFromLine(str line)









