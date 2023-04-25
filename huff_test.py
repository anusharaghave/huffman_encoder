# A Huffman Tree Node
import heapq


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
	#node_values = {}

	# if node is not an edge node
	# then traverse inside it
	if(node.left):
		printNodes(node.left, newVal)
	if(node.right):
		printNodes(node.right, newVal)

		# if node is edge node then
		# display its huffman code
	#print(chars)
	if(not node.left and not node.right):
		#print(f"{node.symbol} -> {newVal}")

		char_b = bin(ord(node.symbol))
		char_b = '00010'+char_b[2:]
		#print(char_b, file=output_file)

		mask_length = len(newVal)
		mask = bin((1<<mask_length) - 1)
		mask = mask[2:]
		char_len = 3
		char_len1 = '{'+'0:0{}b'.format(char_len)+'}' 
		final_mask = char_len1.format(int(mask,2))
		final_val = char_len1.format(int(newVal,2))

		val = '000100'+final_mask+final_val
		#print(val, file=output_file)
		#print("\n")
		node_values.setdefault(node.symbol, []).append(char_b)
		node_values[node.symbol].extend([val])
		#print(node_values)
		#return char_b, val
	#return '',''

node_values= {}
#node_values.setdefault(key, [])
output_file = open('expected_out.txt', 'w')

vector_num = 0
#can only input characters between a and 0 (hex61 to hex6F)
#string = "anm"  #read from a input vector
with open('input_vector.txt', 'r') as f:
	for line in f:
		node_values.clear()
		vector_num +=1
		#print(line)
		#print("//Vector =", vector_num, file=output_file)
		freq = line.strip().split(',')
		freq = [int(value) for value in freq]
		string = next(f).strip()
		chars = list(string)
		#print(string,file=input_file)
		

# list containing unused nodes
		nodes = []

# converting characters and frequencies
# into huffman tree nodes
		for x in range(len(chars)):
			heapq.heappush(nodes, node(freq[x], chars[x]))

		while len(nodes) > 1:

	# sort all the nodes in ascending order
	# based on their frequency and in case of tie, ascii value
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
	
		#doesn't work
		#print(nodes[0])
		#printNodes(nodes[0])

		printNodes(nodes[0])
		for c in chars:
			if c in node_values:
				print(node_values[c][0], file=output_file)
				print(node_values[c][1], file=output_file)
		
		print("\n", file=output_file)
	
		#use for loop to print to output 

		

		#print(char_b, val)
		#if (char_b != '' and val != ''):
		#	print("I am here\n")
		#	node_values[char_b].append(val)
		#	print(node_values)
		#	print("\n")
		
