# A Huffman Tree Node
import heapq
import binascii

class node:
	def __init__(self, freq, symbol, left=None, right=None):
		# frequency of symbol
		self.freq = freq

		# symbol name (character)
		self.symbol = symbol

		# node left of current node
		self.left = left

		# node right of current node
		self.right = right

		# tree direction (0/1)
		self.huff = ''

	def __lt__(self, nxt):
		if self.freq == nxt.freq:
			return self.symbol < nxt.symbol
		return self.freq < nxt.freq



# utility function to print huffman
# codes for all symbols in the newly
# created Huffman tree
def printNodes(node, val=''):

	# huffman code for current node
	newVal = val + str(node.huff)

	# if node is not an edge node
	# then traverse inside it
	if(node.left):
		printNodes(node.left, newVal)
	if(node.right):
		printNodes(node.right, newVal)

		# if node is edge node then
		# display its huffman code
	if(not node.left and not node.right):
		print(f"{node.symbol} -> {newVal}")
		char_b = bin(ord(node.symbol))
		print(char_b)
		mask_length = len(newVal)
		mask = bin((1<<mask_length) - 1)
		mask = mask[2:]
		blen = 3
		blen1 = '{'+'0:0{}b'.format(blen)+'}'
		print(mask, blen1) 
		print(blen1.format(int(mask,2)))
	#	print(mask+newVal)

string = "anm"  #read from a vector
chars = list(string)

# characters for huffman tree
#chars = ['a', 'n', 'm']

# frequency of characters
freq = [4, 2, 3]

# list containing unused nodes
nodes = []

# converting characters and frequencies
# into huffman tree nodes
for x in range(len(chars)):
	heapq.heappush(nodes, node(freq[x], chars[x]))

while len(nodes) > 1:

	# sort all the nodes in ascending order
	# based on their frequency
	left = heapq.heappop(nodes)
	right = heapq.heappop(nodes)

	# assign directional value to these nodes
	left.huff = 0
	right.huff = 1

	# combine the 2 smallest nodes to create
	# new node as their parent
	newNode = node(left.freq+right.freq, left.symbol+right.symbol, left, right)

	heapq.heappush(nodes, newNode)

# Huffman Tree is ready!
printNodes(nodes[0])
