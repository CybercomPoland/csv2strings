# **strings file format to csv file format**

### **strings file structure:**

`"text.identifier" = "Here goes text you want to show"; //and here is comment - use double slash `

`//comments can be only "value" in line, and yes quotation marks are allowed`

### WARNING:
`/*this type of comment is not supported - remove it from converted file*/`


# **csv file format to strings file format**

### **csv file struceture:**

`identiferCell,textCell,commentCell`

`identiferCell,"textCell, with comma",commentCell`

`identiferCell,"textCell with ""quotation""",commentCell`

`identiferCell,"textCell with , comma and ""quotation""",commentCell`

`,,only comment cell`

`,,"only comment cell with ""quotation"""`

`,,"only comment cell with , comma"`

`,,"only comment cell with , comma and ""quotation"""`
