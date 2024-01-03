// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;

interface IPoolWithdraw {
  function withdrawFees() external;
  function updateAndClaim() external;
  function getFees() external view returns(address);
  function rewards() external view returns(address[] memory);
  function withdrawFeesToToken(uint256 amount, address token, uint256 minA, uint256 minB, uint256 minOutA, uint256 minOutB) external;
}
