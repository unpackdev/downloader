// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

interface ILiquidityPoolManager {
    function owner() external view returns (address);

    function getRouter() external view returns (address);

    function getPair() external view returns (address);

    function getLeftSide() external view returns (address);

    function getRightSide() external view returns (address);

    function isPair(address _pair) external view returns (bool);

    function isRouter(address _router) external view returns (bool);

    function isFeeReceiver(address _receiver) external view returns (bool);

    function isLiquidityIntact() external view returns (bool);

    function isLiquidityAdded() external view returns (bool);

    function afterTokenTransfer(address sender) external returns (bool);
}