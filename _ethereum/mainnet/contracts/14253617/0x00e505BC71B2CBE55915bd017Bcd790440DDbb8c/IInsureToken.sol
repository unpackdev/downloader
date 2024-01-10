// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IInsureToken {
    function mint(address _to, uint256 _value)external returns(bool);
    function emergency_mint(uint256 _amountOut, address _to)external;
    function approve(address _spender, uint256 _value)external;
    function rate()external view returns(uint256);
    function future_epoch_time_write() external returns(uint256);
}