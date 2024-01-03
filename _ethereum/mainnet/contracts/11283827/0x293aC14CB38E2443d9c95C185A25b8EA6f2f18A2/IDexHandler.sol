// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.8;

interface IDexHandler {
    function isDexHandler() external view returns(bool);
    function swap(bytes calldata _data, uint256 _amount) external returns(uint256 _amountOut);
    function swapData() external pure returns(bytes memory);
    function getAmountOut(bytes calldata _data, uint256 _amount) external view returns(uint256 _amountOut);
}