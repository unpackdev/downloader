/*

  << Static Atomicizer Base >>

*/

pragma solidity 0.7.5;

contract StaticAtomicizerBase {
    address public atomicizer;
    address public owner;

    function setAtomicizer(address addr) external {
        require(msg.sender == owner, "Atomicizer can only be set by owner");
        atomicizer = addr;
    }
}
