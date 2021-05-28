from random import seed
from random import randint

seed(1)

inventoryCount = 21
deffItems = 26
offItems = 11

#randint(a,b)
def gen_InvDef():

	with open("Defensive_item", "r") as r:
		r.readline()

		items = []

		for _ in range(deffItems):
			line = r.readline()

			idx = 1
			while line[idx] != "'" or line[idx + 1] != " ":
				idx += 1

			name = line[0 : idx + 1]
			items.append(name)

	with open("Inventory_DefItem", "w") as w:
		w.write("Id Item_name\n")

		for inv in range(1, inventoryCount + 1):
			count = randint(4, deffItems)
			cpyitems = items.copy()
			for _ in range(count):

				chosenItem = items[randint(0, len(items) - 1)]

				while chosenItem not in items:
					chosenItem = items[randint(0, len(items) - 1)]

				w.write(str(inv) + " " + str(chosenItem))
				w.write("\n")
				items.remove(chosenItem)

			items = cpyitems.copy()

def gen_InvOff():

	with open("Offensive_item", "r") as r:
		r.readline()

		items = []

		for _ in range(offItems):
			line = r.readline()

			idx = 1
			while line[idx] != "'" or line[idx + 1] != " ":
				idx += 1

			name = line[0 : idx + 1]
			items.append(name)

	with open("Inventory_OffItem", "w") as w:
		w.write("Id Item_name\n")

		for inv in range(1, inventoryCount + 1):
			count = randint(4, offItems)
			cpyitems = items.copy()
			for _ in range(count):

				chosenItem = items[randint(0, len(items) - 1)]

				while chosenItem not in items:
					chosenItem = items[randint(0, len(items) - 1)]

				w.write(str(inv) + " " + str(chosenItem))
				w.write("\n")
				items.remove(chosenItem)

			items = cpyitems.copy()

def checkNextChar(string, idx):
	if idx + 1 == len(string):
		return True
	if ord(string[idx + 1]) == 10:
		return True
	if string[idx + 1] == " ":
		return True
	return False


def next_varchar(string, idx):

	while 1:
		if string[idx] == "'" and checkNextChar(string, idx):
			return idx
		idx += 1

def next_int(string, idx):
	while 1:
		if string[idx].isdigit() and checkNextChar(string, idx):
			return idx
		idx += 1


def Integer(string):
	return string.find("Id") != -1 or string.find("Bonus") != -1 or string.find("id") != -1 or string.find("Lvl") != -1


def build_Insert_Statement(table, attributes, values):
	attributes = ", ".join(attributes)
	values = ", ".join(values)

	sql = "INSERT INTO " + table + " (" + attributes + ")\n" + "VALUES (" + values + ");\n"
	return sql


def gen_SQL():

	with open("databaseContents", "r") as r:
		line = r.readline()
		line = line.replace("Tables: ", "")
		tables = [table.strip(",") for table in line.split()]

	with open("sqlInsert.txt", "w") as w:
		for table in tables:
			with open(table, "r") as r:
				attributes = r.readline()
				attributes = attributes.split()

				line = r.readline()

				while line != "":

					last = 0
					values = []

					for attr in attributes:
						if Integer(attr):
							idx = next_int(line, last)
							string = line[last : idx + 1]
							string = string.strip(" ")
							# w.write(string)
							values.append(string)
							last = idx + 1
						else:
							idx = next_varchar(line, last)
							string = line[last : idx + 1]
							string = string.strip(" ")
							# w.write(string)
							values.append(string)
							last = idx + 1

					sql = build_Insert_Statement(table, attributes, values)
					w.write(sql)

					w.write("\n")
					line = r.readline()


gen_InvDef()
gen_InvOff()
gen_SQL()