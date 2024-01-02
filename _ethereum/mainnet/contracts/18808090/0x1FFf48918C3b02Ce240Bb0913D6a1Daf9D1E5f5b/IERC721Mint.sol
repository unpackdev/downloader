// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @author SuperRare Labs Inc.
/// @title IERC721Mint
/// @notice Interface for Minting ERC721
interface IERC721Mint {
  /**
   * @notice Mint a new token to the specified receiver.
   * @param _receiver The address of the token receiver.
   * @return uint256 Token Id of the new token.
   */
  function mintTo(address _receiver) external returns (uint256);
}
