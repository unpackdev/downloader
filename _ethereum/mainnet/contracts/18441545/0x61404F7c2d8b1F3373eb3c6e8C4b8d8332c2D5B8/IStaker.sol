// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IStaker{
    function lock(uint256 _amount) external returns (bool);
    function freeze() external;
    function operator() external view returns (address);
    function setMinterOperator(address _minter, address _operator, bool _active) external;
    function execute(address _to, uint256 _value, bytes calldata _data) external returns (bool, bytes memory);
}