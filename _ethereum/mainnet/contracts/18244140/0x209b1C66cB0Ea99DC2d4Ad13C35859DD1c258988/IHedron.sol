// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./IERC20.sol";

interface IHedron is IERC20 {
  event Claim(uint256 data, address indexed claimant, uint40 indexed stakeId);
  event LoanEnd(
      uint256 data,
      address indexed borrower,
      uint40 indexed stakeId
  );
  event LoanLiquidateBid(
      uint256 data,
      address indexed bidder,
      uint40 indexed stakeId,
      uint40 indexed liquidationId
  );
  event LoanLiquidateExit(
      uint256 data,
      address indexed liquidator,
      uint40 indexed stakeId,
      uint40 indexed liquidationId
  );
  event LoanLiquidateStart(
      uint256 data,
      address indexed borrower,
      uint40 indexed stakeId,
      uint40 indexed liquidationId
  );
  event LoanPayment(
      uint256 data,
      address indexed borrower,
      uint40 indexed stakeId
  );
  event LoanStart(
      uint256 data,
      address indexed borrower,
      uint40 indexed stakeId
  );
  event Mint(uint256 data, address indexed minter, uint40 indexed stakeId);

  function hsim() external view returns(address);
  function mintInstanced(uint256 hsiIndex, address hsiAddress) external returns (uint256);
  function mintNative(uint256 stakeIndex, uint40 stakeId) external returns (uint256);
}
