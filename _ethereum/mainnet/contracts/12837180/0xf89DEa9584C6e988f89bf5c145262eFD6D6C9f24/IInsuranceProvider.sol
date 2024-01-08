// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IInsuranceProvider {
  function fileClaim(uint256 amount) external;
  function processClaim(address iv, uint256 amountIn, uint256 minAmountOut) external;
  function onGoingClaim() view external returns(bool haveClaim);

  function removeInsuranceClient(address iv) external;
  function addInsuranceClient(address iv) external;
}