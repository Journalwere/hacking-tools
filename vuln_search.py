from pyExploitDb import PyExploitDb 

pEdb = PyExploitDb() 
pEdb.debug = False 
pEdb.openFile() 
results = pEdb.searchCve("{cve-0000-0000}") 
print(results) 