// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface ITokenIdResolver {
  /**
   * @notice Returns the token id of a given set of traits
   * @param traits set of traits of the token
   * @return token id
   */
  function getTokenId(uint256[8] calldata traits) external view returns (uint256);
}
