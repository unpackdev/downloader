// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IConfig {
    function dexInterfacerAddress() external view returns (address);
    function banansAddress() external view returns (address);
    function bananChefAddress() external view returns (address);
    function bananStolenPoolAddress() external view returns (address);
    function bananFullProtecAddress() external view returns (address);
    function banansPoolAddress() external view returns (address);
    function monkeyAddress() external view returns (address);
    function randomizerAddress() external view returns (address);
    function uniswapRouterAddress() external view returns (address);
    function uniswapFactoryAddress() external view returns (address);
    function treasuryAddress() external view returns (address);
    function treasuryBAddress() external view returns (address);
    function teamSplitterAddress() external view returns (address);
    function presaleDistributorAddress() external view returns (address);
    function airdropDistributorAddress() external view returns (address);
    function attackRewardCalculatorAddress() external view returns (address);
    function lpOwnerAddress() external view returns (address);
}