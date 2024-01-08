pragma solidity ^0.5;

interface IImplementation {
    function transactionExecuted(uint256 transactionId) external;
    function transactionFailed(uint256 transactionId) external;
}