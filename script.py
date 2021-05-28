import os

tables = []

def create_Files():
	global tables
	with open("databaseContents", "r") as read:
		line = read.readline()
		line = line.replace("Tables: ", "")
		line = [table.strip(",") for table in line.split()]

		tables = line.copy()

		for table in line:
			with open(table, "w") as f:
				pass





with open("input.txt", "r") as r:


	line = r.readline()

	line1 = line

	cnt = 0
	while line != "":
		cnt += 1

		if cnt == 2:
			print(ord(line[0]))

		# print(line == "")
		if line != line1 and line != "\n":
			break
		line = r.readline()
	print(cnt)