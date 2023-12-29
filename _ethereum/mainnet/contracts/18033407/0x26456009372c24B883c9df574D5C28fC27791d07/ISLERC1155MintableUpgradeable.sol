// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./IERC1155Upgradeable.sol";

interface ISLERC1155MintableUpgradeable is IERC1155Upgradeable {
  /**
   * Mints `amount` token of type `tokenId` to address `receiver`.
   * @param receiver Account to mint to.
   * @param tokenId Token ID to mint.
   * @param amount Amount to mint.
   */
  function mintTo(address receiver, uint256 tokenId, uint256 amount) external;
}
