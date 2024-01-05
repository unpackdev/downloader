// SPDX-License-Identifier: MIT
pragma solidity =0.7.4;
pragma experimental ABIEncoderV2;

interface IContractsRegistry {    
    function getUniswapBMIToETHPairContract() external view returns (address);

    function getBMIContract() external view returns (address);

    function getBMIStakingContract() external view returns (address);

    function getSTKBMIContract() external view returns (address);

    function getLiquidityMiningStakingContract() external view returns (address);
}