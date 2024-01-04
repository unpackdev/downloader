pragma solidity ^0.6.7;

contract DSCompare {
    // Uint
    function lt(uint x, uint y) public pure returns (bool) {
      return x < y;
    }
    function le(uint x, uint y) public pure returns (bool) {
      return x <= y;
    }
    function gt(uint x, uint y) public pure returns (bool) {
      return x > y;
    }
    function ge(uint x, uint y) public pure returns (bool) {
      return x >= y;
    }

    // Int
    function lt(int x, int y) public pure returns (bool) {
      return x < y;
    }
    function le(int x, int y) public pure returns (bool) {
      return x <= y;
    }
    function gt(int x, int y) public pure returns (bool) {
      return x > y;
    }
    function ge(int x, int y) public pure returns (bool) {
      return x >= y;
    }

    // Uint & Int
    function lt(uint x, int y) public pure returns (bool) {
      return int(x) < y;
    }
    function le(uint x, int y) public pure returns (bool) {
      return int(x) <= y;
    }
    function gt(uint x, int y) public pure returns (bool) {
      return int(x) > y;
    }
    function ge(uint x, int y) public pure returns (bool) {
      return int(x) >= y;
    }
}