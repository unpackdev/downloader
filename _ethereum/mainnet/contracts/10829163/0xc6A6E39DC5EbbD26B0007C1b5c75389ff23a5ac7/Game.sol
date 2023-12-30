pragma solidity ^0.5.0;

contract CounterLibrary {function add(uint x) public pure returns (uint) {return x+2;}}

contract CounterLibr {function add(uint x) public pure returns (uint) {return x+3;}}

contract Game{
    function play(CounterLibrary c) public pure returns(uint) {

        return c.add(1);
    }
}