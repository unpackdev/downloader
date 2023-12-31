pragma solidity ^0.6.0;

interface IMission  {
    function sendSpores(address recipient, uint256 amount) external;
    function approvePool(address pool) external;
    function revokePool(address pool) external;
}