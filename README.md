# ServerParameterUpdateScript
This Powershell script creates ARM template for multiple server parameter updates from the list of input server parameters. 
# How to run it? 
1. Execute TemplateGenerator.ps1 (e.g, ./TemplateGenerator.ps1)
2. Type input list file name (e.g, server_parameters.txt)
3. Type output json file name 
# Requirement 
Input text file should include only one parameter at one line. 
(Please see example server_parameters.txt file). 