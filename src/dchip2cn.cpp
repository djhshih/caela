#include <cstdio>
#include <vector>
#include <string>
#include <fstream>

using namespace std;

const int maxLineSize = 100000;
const int maxStrSize = 10000;

int getNCols(string line, char delimiter)
{
	int i = 0, cols = 0;
	int lineLength = line.length();
	bool notIgnoring = false;
	// Start reading from end and begin by ignoring trailing whitespaces and delimiters
	for (int i = lineLength-1; i >= 0; --i) {
		// Increment for each delimiter
		if (notIgnoring) {
			if (line[i] == delimiter) ++cols;
		} else {
			if (line[i] != delimiter && line[i] != '\t' && line[i] != ' ' && line[i] != '\n' && line[i] != '\r') notIgnoring = true;	
		}
	}
	// Add one more for the first column
	return cols+1;
}

int main(int argc, char* argv[])
{

	if (argc < 3) {
		printf("Convert dChip output file to GenePattern CN file.\n");
		printf("Usage: %s <infile> <outfile>\n", argv[0]);
		return 1;
	}

	const char delimiter = '\t';

	char* line = new char[maxLineSize];
	char elem[maxStrSize];

	// Conversion process:
	// delete row 0
	// delete columns 1, 4, 5 
	// Note: dChip puts an extra '\t' at the end of the line

	const short delColsArray[] = {1, 4, 5};
	vector<int> delCols(delColsArray, delColsArray + sizeof(delColsArray)/sizeof(short));

	char* inFilename = argv[1];
	char* outFilename = argv[2];

	ifstream in(inFilename, fstream::in);
	ofstream out(outFilename, fstream::out);

	bool noError = true;

	if (!in.is_open()) {
		printf("Error: cannot open input file %s\n", inFilename);
		noError = false;
	}	
	if (!out.is_open()) {
		printf("Error: cannot open output file %s\n", outFilename);
		noError = false;
	}
	

	if (noError) {

		// discard first row
		in.getline(line, maxLineSize);	

		//printf("Deleting line: %s\n", line);

		int i = 0, cols;
		while (!in.eof()) {
			in.getline(line, maxLineSize);
			string sLine = line;
			if (sLine == "") break;
			//printf("row %d: %s\n", i, line);
			if (i == 0) {
				cols = getNCols(sLine, delimiter);
			}
			
			string newLine = "";
			int pos, prevPos = 0;
			for (int j = 0; j < cols; ++j) {
				pos = sLine.find(delimiter, prevPos);
				if (pos == -1) pos = sLine.length();
				bool delCol = false;
				for (int k = 0; k < delCols.size(); ++k) {
					if (j == delCols[k]) {
						delCol = true;
						break;
					}
				}
				if (!delCol) {
					newLine += sLine.substr(prevPos, pos-prevPos);
					if (j < cols-1) {
						newLine += delimiter;
					}
				}
				prevPos = pos + 1;
			}
			out << newLine << '\n';
			//printf("%s\n", newLine.c_str());
			++i;
		}

		printf("Input file %s processed.\n", inFilename);
		printf("nrow: %d,  ncol: %d\n", i, cols);
	
	}

	
			
	in.close();
	out.close();

	delete [] line;

	return 0;
}
