import std.stdio;
import std.conv;
import std.file;

int main(string[] args) {
  if(args.length < 3) {
    writeln("Usage: "~args[0]~" <output file> <text>");
    return 1;
  }
  string text = "";
  for(int i = 2; i < args.length; i++) text ~= args[i]~" ";
  bool[] bin;
  for(int i = 0; i < text.length; i++) {
    char c = text[i];
    for(int j = 7; j >= 0; j--) {
      bin ~= (c & (1 << j)) != 0;
    }
  }
  string output = "";
  output ~= "set0\t>\t0\tset1\n";
  output ~= "set1\t<\t1\tc0\n";
  for(int i = 0; i < bin.length; i++) {
    write(bin[i] ? "1" : "0");
    bool next;
    bool curr = bin[i];
    if(i == bin.length - 1) next = false;
    else next = bin[i + 1];
    output ~= "c"~to!string(i)~"\t";
    if(next == curr) output ~= "\t";
    else if(next) output ~= ">\t";
    else output ~= "<\t";
    output ~= ".\t"~(i == bin.length-1 ? "halt" : "c"~to!string(i+1))~"\n";
  }
  std.file.write(args[1], output);
  return 0;
}