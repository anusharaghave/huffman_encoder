import heapq
from collections import Counter
from heapq import heapify, heappush, heappop

# Define a class for the Huffman tree nodes
class Node:
    def __init__(self, char, freq, left=None, right=None):
        self.freq = freq
        self.char = char
        self.left = left
        self.right = right
    
    # Define comparison operators for the nodes
    def __lt__(self, other):
        if self.freq == other.freq:
            return self.char < other.char
        return self.freq < other.freq
    
    #def __le__(self, other):
    #    return self.freq >= other.freq
    
    #def __eq__(self, other):
    #    return self.freq == other.freq
    
    #def __ne__(self, other):
        return self.freq != other.freq
    
    #def __gt__(self, other):
    #    return self.freq < other.freq
    
    #def __ge__(self, other):
    #    return self.freq <= other.freq

# Define a function to generate Huffman codes for the given characters and their frequencies
def generate_huffman_codes(chars, freqs):
    # Count the frequency of each character in the input string
    #char_freqs = Counter(s)
    char_freqs = {}

    #print(char, freq)

    for c, f in zip(chars, freqs):
        char_freqs[c] = f
        

    print(char_freqs)

    # Create a max heap to store the nodes
    heap = []
    #for char, freq in char_freqs.items():
    for char, freq in char_freqs.items():
        heapq.heappush(heap, Node(freq, char))

    heapify(heap)

    #print(heap)- you cannot print like this
    
    # Build the Huffman tree by repeatedly merging the two nodes with the largest frequencies
    while len(heap) > 1:
        # Get the two nodes with the smallest frequencies
        node1 = heapq.heappop(heap)
        node2 = heapq.heappop(heap)
        
        # Create a new node by combining the two nodes and add it back to the max heap
        merged_node = Node(None ,node1.freq + node2.freq, node1, node2)
        merged_node.left = node1
        merged_node.right = node2
        heapq.heappush(heap, merged_node)
    
    # Traverse the Huffman tree to generate codes for each character
    #codes = {}

    encoding_table = {}
    root = heap[0]
    #stack = [(root, "")]
    

    def generate_encoding_table(node, encoding):
        if not node:
            return
        if node.char:
            encoding_table[node.char] = encoding
        generate_encoding_table(node.left, encoding + '0')
        generate_encoding_table(node.right, encoding + '1')
    
    generate_encoding_table(root, '')
    print(encoding_table)
    
    encoded_data = ''.join(encoding_table[char] for char in char_freqs)
    
    return encoding_table


    

# Test the function with an example input
string = "anm"  #read from a vector
chars = list(string)
freqs = [3,3,2] #read from a vector
encoding_table = generate_huffman_codes(chars,freqs)
print(encoding_table)
