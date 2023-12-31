// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IIncentivizationHandler {
  function incentivizePool(
    address poolAddress, 
    address gaugeAddress,
    address incentivePoolAdderss, 
    address incentiveTokenAddress,
    uint256 indexId, 
    uint256 amount) external;
}