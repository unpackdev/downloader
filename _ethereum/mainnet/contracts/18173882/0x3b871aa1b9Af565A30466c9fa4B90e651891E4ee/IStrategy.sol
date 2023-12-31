// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IStrategy {

  /// @notice Mint both fToken and xToken with all Lido rewards by staking vault contract.
  /// @return fTokenMinted The amount of fToken should be send to staking vault contract.
  /// @return xTokenMinted The amount of xToken should be send to staking vault contract.
  function mintByStaking() external returns (uint256 fTokenMinted, uint256 xTokenMinted);

  /// @notice Mint both fToken and xToken with some Lido rewards by staking vault contract.
  /// @param baseIn The amount of base token supplied.
  /// @return fTokenMinted The amount of fToken should be send to staking vault contract.
  /// @return xTokenMinted The amount of xToken should be send to staking vault contract.
  function mintByStaking(uint256 baseIn) external returns (uint256 fTokenMinted, uint256 xTokenMinted);

  /// @notice Mint both fToken and xToken with all mint/redeem fee by revenue vault contract.
  /// @return fTokenMinted The amount of fToken should be send to revenue vault contract.
  /// @return xTokenMinted The amount of xToken should be send to revenue vault contract.
  function mintByRevenue() external returns (uint256 fTokenMinted, uint256 xTokenMinted);

  /// @notice Mint both fToken and xToken with some mint/redeem fee by revenue vault contract.
  /// @param baseIn The amount of base token supplied.
  /// @return fTokenMinted The amount of fToken should be send to revenue vault contract.
  /// @return xTokenMinted The amount of xToken should be send to revenue vault contract.
  function mintByRevenue(uint256 baseIn) external returns (uint256 fTokenMinted, uint256 xTokenMinted);
}
