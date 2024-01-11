pragma solidity ^0.8.0;

interface IExitQueue {

    function addQueue(uint256 value)  external;
    function  executeQueue() external;
    function  withDraw() external;
    function  cancelQueue() external;
    function nextValue() view external returns(uint256 value);
}
