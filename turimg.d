import std.stdio;
import std.file;
import std.array;
import std.conv;
import std.algorithm;

extern(C) int kbhit();
extern(C) int getch(); //I know this is non-standard and bad and that it only works on windows

int main(string[] args) {
  if(args.length == 1) {
    writeln("Usage: " ~ args[0] ~ " <file> [flags]");
    writeln("Flags:");
    writeln("  -ascii: Interprets output as ascii characters instead of binary");
    writeln("  -bin: Interprets output as binary instead of ascii (default)");
    return 1;
  }
  string[] flags;
  for(int i = 2; i < args.length; i++) {
    flags ~= args[i];
  }
  bool ascii = false;
  if(flags.canFind("-ascii")) {
    ascii = true;
  }
  char[] asciibuf;
  string state;
  State[string] states;
  bool[0x10000] tape;
  int pos = 0;
  string file = readText(args[1]);
  file = file.replace("\r\n", "\n"); //windows :P
  string[] lines = file.split("\n");
  bool[] input;
  for(int i = 0; i < lines.length; i++) {
    if(lines[i].length == 0) continue;
    if(lines[i][0] == ';') continue;
    string[] tmp = lines[i].split("\t");
    if(tmp.length != 5 && tmp.length != 4) {
      writeln("Line "~to!string(i+1)~": Invalid line format");
      return 1;
    }
    string name = tmp[0];
    byte dir;
    switch(tmp[1]) {
      case "":
        dir = 0;
        break;
      case "<":
        dir = 1;
        break;
      case ">":
        dir = 2;
        break;
      default:
        writeln("Line "~to!string(i+1)~": Invalid direction");
        return 1;
    }
    byte set;
    switch(tmp[2]) {
      case "":
        set = 0;
        break;
      case "0":
        set = 1;
        break;
      case "1":
        set = 2;
        break;
      case ".":
        set = 3;
        break;
      case ",":
        set = 4;
        break;
      default:
        writeln("Line "~to!string(i+1)~": Invalid set");
        return 1;
    }
    string next0 = tmp[3];
    string next1;
    if(tmp.length == 4) next1 = tmp[3];
    else next1 = tmp[4];
    if(name in states) {
      writeln("Line "~to!string(i+1)~": State "~name~" already exists");
      return 1;
    } else {
      states[name] = State(dir, set, next0, next1);
    }
    if(state == "") state = name; //use the first state as the initial state
  }
  while(state != "halt") {
    if(!(state in states)) {
      writeln("State "~state~" not found");
      return 1;
    }
    State s = states[state];
    if(tape[pos]) state = s.next1;
    else state = s.next0;
    final switch(s.set) {
      case 0:
        break;
      case 1:
        tape[pos] = false;
        break;
      case 2:
        tape[pos] = true;
        break;
      case 3:
        if(ascii) {
          asciibuf ~= tape[pos];
          if(asciibuf.length == 8) {
            char c = to!char((asciibuf[0] << 7) | (asciibuf[1] << 6) | (asciibuf[2] << 5) | (asciibuf[3] << 4) | (asciibuf[4] << 3) | (asciibuf[5] << 2) | (asciibuf[6] << 1) | asciibuf[7]);
            write(c);
            asciibuf = [];
          }
        } else write(tape[pos] ? "1" : "0");
        break;
      case 4:
        if(input.length == 0) {
          while(!kbhit()) {
            //wait for a keypress
          }
          char c = to!char(getch);
          if(ascii) {
            for(int i = 7; i >= 0; i--) {
              input ~= ((c >> i) & 1) != 0;
            }
          } else {
            input ~= c == '1';
          }
        }
        tape[pos] = input[0];
        input = input.remove(0);
        break;
    }
    final switch(s.dir) {
      case 0:
        break;
      case 1:
        pos--;
        if(pos < 0) {
          writeln("Pointer out of bounds");
          return 1;
        }
        break;
      case 2:
        pos++;
        if(pos >= tape.length) {
          writeln("Pointer out of bounds");
          return 1;
        }
        break;
    }
  }
  return 0;
}

struct State {
  byte dir; //0 = none, 1 = left, 2 = right
  byte set; //0 = none, 1 = 0, 2 = 1, 3 = . 4 = ,
  string next0;
  string next1;
  this(byte dir, byte set, string next0, string next1) {
    this.dir = dir;
    this.set = set;
    this.next0 = next0;
    this.next1 = next1;
  }
}