pragma solidity 0.7.5;

contract Counter {
    int private count = 0;
    
    function incrementCounter() public {
        count += 1;
    }
    function decrementCounter() public {
        count -= 1;
    }
    
    function getCount() public returns (int) {
        return count;
    }
}