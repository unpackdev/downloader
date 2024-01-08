// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

interface IContractsRegistry {

    function getUniswapBrightToETHPairContract() external view returns (address);

    function getBrightContract() external view returns (address);

    function getBrightStakingContract() external view returns (address);

    function getSTKBrightContract() external view returns (address);

    function getLiquidityMiningStakingContract() external view returns (address);

}
