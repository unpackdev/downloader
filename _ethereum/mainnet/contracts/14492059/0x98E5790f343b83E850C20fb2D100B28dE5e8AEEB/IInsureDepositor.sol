pragma solidity 0.8.13;

interface IInsureDepositor {
    function deposit(uint256 _amount, bool _lock, bool _stake) external;
}