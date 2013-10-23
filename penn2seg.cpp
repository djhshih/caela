#include <iostream>
#include <fstream>
#include <string>

using namespace std;

const char out_delim = '\t';

template<class In, class Out>
void process(In& in, Out& out) {

	// print output header
	out << "name" << out_delim
		<< "chromosome" << out_delim
		<< "start" << out_delim
		<< "end" << out_delim
		<< "count" << out_delim
		<< "state" << endl;

	//int line = 1;
	while (!in.eof()) {
		string s;
		size_t start, end;  // end = one position past last position

		//cout << line++ << endl;
		
		// coordinates
		in >> s;
		if (s == "") break;
		string token = "chr";
		start = s.find(token) + token.length();
		end = s.find(':', start);
		string chr = s.substr(start, end - start);
		
		start = end + 1;
		end = s.find('-', start);
		string coord_start = s.substr(start, end - start);

		start = end + 1;
		end = s.length();
		string coord_end = s.substr(start, end - start);

		// number of markers
		in >> s;
		start = s.find('=') + 1;
		end = s.length();
		string count = s.substr(start, end - start);

		// segment length: ignore
		in >> s;

		// copy number state
		in >> s;
		start = s.find('=') + 1;
		end = s.length();
		string state = s.substr(start, end - start);

		// sample name
		in >> s;
		start = s.find('.') + 1;
		end = s.length();
		string name = s.substr(start, end - start);

		// start SNP and end SNP: ignore
		in >> s >> s;
		
		// output line
		out << name << out_delim
			<< chr << out_delim
			<< coord_start << out_delim
			<< coord_end << out_delim
			<< count << out_delim
			<< state << endl;
	}

}

int main(int argc, char *argv[])
{

	istream* pin;
	ostream* pout;

	fstream fin, fout;

	if (argc < 3) {
		//cout <<  "Usage: penn2seg <input file> <output file>" << endl;
		//return -1;
		
		// use input and output
		pin = &cin;	
		pout = &cout;
	} else {
		char *in_fname = argv[1], *out_fname = argv[2];

		fin.open(in_fname);
		if (!fin.is_open()) {
			cerr << "Error: cannot open input file: " << in_fname << endl;
			return -1;
		}

		fout.open(out_fname, fstream::out);
		if (!fout.is_open()) {
			cerr << "Error: cannot open output file: " << out_fname << endl;
			return -1;
		}

		pin = &fin;
		pout = &fout;
	}

	process(*pin, *pout);

	if (fin.is_open()) fin.close();
	if (fout.is_open()) fout.close();

}
