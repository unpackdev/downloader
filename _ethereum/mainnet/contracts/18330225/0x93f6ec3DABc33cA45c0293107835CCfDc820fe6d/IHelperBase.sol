// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface IHelperBase {
    function addLiquidityNative(uint256 tupAmount) external payable returns (bool);
    function checkAndPerformArbitrage() external returns (bool);
    function pairTupEth() external view returns (address);
    function queryRate() external view returns (uint256);
    function queryPoolAddress() external view returns (address);
    function setTup(address tupAddress) external;
}
