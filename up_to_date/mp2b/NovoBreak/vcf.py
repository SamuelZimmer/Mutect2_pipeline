import os
class Snp :

	def __init__ (self, ligne, grade=0) :
		
		self.grade=grade
		self.chr= ligne[0].replace('chr', '')
		self.rs= ligne[2]

		#snpSubID
		self.subID = self.chr + "_" + ligne[1] + "_" + ligne[3]

		#snpID		
		if "," in ligne[4] :
			alt= ligne[4].split(',')[self.grade]
		else :
			alt= ligne[4]
		self.ID= self.subID + "_" + alt

		#reste
		self.reste= "\t".join(ligne)

	def changeReste(self, newReste):
		self.reste=newReste

	def giveGene (self) :
		return self.gene

	def giveChr (self) :
		return self.chr

	def giveSubID (self) :
		return self.subID

	def giveID (self) :
		return self.ID

	def giveReste(self) :
		return self.reste

	def comparerID(self, ligne1) :
		return self.ID== ligne1.giveID()

	def __eq__ (self, autre):
		return self.ID== autre.giveID()

class Vcf :

	def __init__ (self, file, patient="") :

		self.fileName = file
		self.patientName = patient
		
		self.Snps= {}


	def lecture(self) :
		with open(self.fileName ,'r', encoding='latin1') as f:
			for line in f:
				if line.startswith('chr'):
					self.appendSnp(Snp(line.replace("\n", "").split('\t')))
		return self


	def appendSnp(self, snp) :
		self.Snps[snp.giveSubID()]=snp

	def removeSnp(self, snp) :
		if len(self.Snps)!= 0 :
			if (self.Snps[-1] == snp):
				self.Snps.pop()

	def givefileName(self):
		return self.fileName 

	def giveSnps(self):
		return (self.Snps)

	def write(self, prefix):
		lines=[]
		for snp in list(self.Snps.values()):
			lines.append(snp.giveReste())		
		with open(self.fileName, "a") as vcfFile:
			if (len(self.Snps) != 0):
				vcfFile.write(str(prefix)+"\t")
				s='\n'+str(prefix)+'\t'
				vcfFile.write(s.join(lines))
				vcfFile.write("\n")

	def clear(self):
		self.Snps.clear()

	def __eq__ (self, vcf2):

		if isinstance(vcf2, type(self)):
			return self.fileName == vcf2.givefileName ()
		elif isinstance(vcf2, type(str("str"))):
			return self.fileName == vcf2

	def __hash__ (self):
		return hash(self.fileName )

	def __add__(self, vcf2):
		if (self.fileName  != vcf2.fileName ) :
			print (self.fileName , " not matching with ", vcf2.fileName )
		self.Snps = self.Snps + vcf2.Snps
		return self