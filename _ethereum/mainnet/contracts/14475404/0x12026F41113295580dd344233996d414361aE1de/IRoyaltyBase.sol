// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface IRoyaltyBase {
  struct RoyaltyDistribution {
    address payable receiver;
    uint256 percentage;
  }

  function setRoyaltyPercentageForCreator(uint256) external;

  function setRoyaltyPercentageForAdmin(uint256) external;

  function royaltyInfo(uint256, uint256) external view returns (address, uint256);

  function royaltyInfoAdmin(uint256) external view returns (uint256);

  function totalRoyaltyFee(uint256) external view returns (uint256);

  event RoyaltyFeePaid(address indexed, uint256);
  event RoyaltyFeePaidForAdmin(address indexed, uint256);
}
