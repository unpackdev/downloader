// SPDX-License-Identifier: Unlicensed
pragma solidity 0.7.6;

interface IPool {
    function openSwap(uint256 _notional) external returns (bool);
    function closeSwap(uint256 _swapNumber) external returns (bool);
    function depositLiquidity(uint256 _liquidityAmount) external returns (bool);
    function withdrawLiquidity(uint256 _liquidityAmount) external returns (bool);
    function liquidate(address _user, uint256 _swapNumber) external returns (bool);
    function calculateVariableInterestAccrued(uint256 _notional, uint256 _protocol, uint256 _borrowIndex) external view returns (uint256);
}