pragma solidity ^0.6.8;

contract TestContract {
    int256 public a = type(int256).min;
    int256 public b = type(int256).max;
    int224 public c = type(int224).min;
    int224 public d = type(int224).max;
    int200 public e = type(int200).min;
    int200 public f = type(int200).max;
    int128 public g = type(int128).min;
    int128 public h = type(int128).max;
    int64 public i = type(int64).min;
    int64 public j = type(int64).max;
    int8 public k = type(int8).min;
    int8 public l = type(int8).max;   
}