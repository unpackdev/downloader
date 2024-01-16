// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1155.sol";

interface IERC1155Mintable {

  // ============ Write Methods ============

  /**
   * @dev Allows minter role to mint (this is good for integrations)
   */
  function mint(
    address to, 
    uint256 itemId, 
    uint256 amount,
    bytes memory data
  ) external;

  /**
   * @dev Allows minter role to mint (this is good for integrations)
   */
  function mint(
    address to, 
    uint256[] memory itemIds, 
    uint256[] memory amounts,
    bytes memory data
  ) external;
}

interface IERC1155Supply {

  // ============ Read Methods ============

  /**
   * @dev Returns the max supply of `itemId`
   */
  function maxSupply(uint256 itemId) external view returns(uint256);

  /**
   * @dev Returns the overall amount of tokens generated for `itemId`
   */
  function totalSupply(uint256 itemId) external view returns(uint256);
}

interface IERC1155MintableSupply is IERC1155Mintable, IERC1155Supply, IERC1155 {}