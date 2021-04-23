
# Create a "send-function" function for vis
# use ?^def to go to start of func
# use "V" followed by / {4}return to go to end in visual mode
# use the vis api and vis:command for this
def add_one(a, b):

    c = a + b

    def two():
        print("hello")
    
    return c
