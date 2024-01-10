// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721NameChangeUpgradeable is IERC721Upgradeable {
  function nameChangeToken() external view returns (address);

  function nameChangePrice() external view returns (uint256);

  /**
   * @dev Returns if the name has been reserved.
   */
  function isNameReserved(string memory nameString) external view returns (bool);

  /**
   * @dev Changes the name for tokenId
   */
  function changeName(uint256 tokenId, string memory newName) external;
}
