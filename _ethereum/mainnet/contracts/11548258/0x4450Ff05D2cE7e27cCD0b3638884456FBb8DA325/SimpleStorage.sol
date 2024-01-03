pragma solidity 0.5.16;

contract SimpleStorage {

    uint public storedData ;

    function set (uint x) public
    {
        storedData = x;
    }

}