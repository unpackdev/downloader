pragma solidity 0.6.2;

interface IDelegateRegistry {
    function setDelegate(bytes32 id, address delegate) external;
}