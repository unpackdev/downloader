pragma solidity ^0.6.8;


contract TestContract {
    uint256 public a = type(uint256).min;
    uint256 public b = type(uint256).max;
    uint224 public c = type(uint224).min;
    uint224 public d = type(uint224).max;
    uint200 public e = type(uint200).min;
    uint200 public f = type(uint200).max;
    uint128 public g = type(uint128).min;
    uint128 public h = type(uint128).max;
    uint64 public i = type(uint64).min;
    uint64 public j = type(uint64).max;
    uint8 public k = type(uint8).min;
    uint8 public l = type(uint8).max;   
}