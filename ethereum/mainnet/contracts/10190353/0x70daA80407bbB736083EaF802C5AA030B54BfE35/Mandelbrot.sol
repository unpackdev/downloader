pragma solidity ^0.6.0;

contract Mandelbrot {
  int xMin = -8601;
  int xMax = 2867;
  int yMin = -4915;
  int yMax = 4915;
  int maxI = 30;
  int dx = (xMax - xMin) / 24;
  int dy = (yMax - yMin) / 10;
  string ascii = '$ ,-~@*?&()%#+=';
  string[] mandel;

  function generateMandelbrot() public returns (bool) {
    uint lines = 0;
    for (int cy = yMax; lines<=10; cy-=dy) {
      int byteChar = 0;
      string memory sL = new string(25);
      bytes memory scanLine = bytes(sL);
      int cx = xMin;
      for (cx; cx<=xMax; cx+=dx) {
        int x = 0; int y = 0; int x2 = 0; int y2 = 0;
        int i = 0;
        for (i; i < maxI && x2 + y2 <= 16384; i++) {
            y = ((x * y) / 2**11) + cy;
            x = x2 - y2 + cx;
            x2 = (x * x) / 2**12;
            y2= (y * y) / 2**12;
        }

        bytes memory char = bytes(ascii);
        scanLine[uint(byteChar)] = char[uint(i%15)];
        byteChar++;
      }
      mandel.push(string(abi.encodePacked(string(scanLine), '\n')));
      lines++;
    }
    return true;
  }

  function viewMandelbrot() public view returns (string memory) {
    string memory mandelbro = string(abi.encodePacked(mandel[0]));
    for (uint iter = 1; iter < mandel.length; iter++) {
      mandelbro = string(abi.encodePacked(mandelbro, mandel[iter]));
    }
    return mandelbro;
  }
}