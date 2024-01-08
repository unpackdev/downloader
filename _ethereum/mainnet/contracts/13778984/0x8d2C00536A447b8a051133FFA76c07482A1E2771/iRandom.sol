pragma solidity ^0.8.0;

interface IRandom {
    function r(bytes32, bool, uint256) view external returns(uint256);
    function r2(bytes32, bool, uint256) view external returns(uint256);
}