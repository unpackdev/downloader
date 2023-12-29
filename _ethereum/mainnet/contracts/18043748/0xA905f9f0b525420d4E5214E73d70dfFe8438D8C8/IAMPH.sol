// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IAMPH {
  /// @notice Returns the prior votes from an account
  /// @param _account address of the account
  /// @param _blockNumber block number to get the votes from
  /// @return _votes amount of votes
  function getPriorVotes(address _account, uint256 _blockNumber) external view returns (uint96 _votes);

  /// @notice Mint a specified amount of tokens to a specified address
  function mint(address _dst, uint256 _rawAmount) external;
}
