// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./IERC1155TokenCreator.sol";

/**
 * @title IERC1155CreatorRoyalty Token level royalty interface.
 */
interface INafterRoyaltyRegistry is IERC1155TokenCreator {
  /**
   * @dev Get the royalty fee percentage for a specific ERC1155 contract.
   * @param _tokenId uint256 token ID.
   * @return uint8 wei royalty fee.
   */
  function getTokenRoyaltyPercentage(uint256 _tokenId) external view returns (uint8);

  /**
   * @dev Utililty function to calculate the royalty fee for a token.
   * @param _tokenId uint256 token ID.
   * @param _amount uint256 wei amount.
   * @return uint256 wei fee.
   */
  function calculateRoyaltyFee(uint256 _tokenId, uint256 _amount) external view returns (uint256);

  /**
     * @dev Sets the royalty percentage set for an Nafter token
     * Requirements:

     * - `_percentage` must be <= 100.
     * - only the owner of this contract or the creator can call this method.
     * @param _tokenId uint256 token ID.
     * @param _percentage uint8 wei royalty fee.
     */
  function setPercentageForTokenRoyalty(uint256 _tokenId, uint8 _percentage) external returns (uint8);
}
