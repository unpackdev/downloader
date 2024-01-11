// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";

/**
 * @title IERC721Delegable
 * @dev Interface for a delegable ERC721 token contract
 * @author 0xAnimist (kanon.art)
 */
interface IERC721Delegable is IERC721 {
  /**
   * @dev Emitted when the delegate token is set for `tokenId` token.
   */
  event DelegateTokenSet(address indexed delegateContract, uint256 indexed delegateTokenId, uint256 indexed tokenId, address operator, bytes data);

  /**
   * @dev Sets the delegate NFT for `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   *
   * Emits a {DelegateTokenSet} event.
   */
  function setDelegateToken(address _delegateContract, uint256 _delegateTokenId, uint256 _tokenId) external;

  /**
   * @dev Sets the delegate NFT for `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   *
   * Emits a {DelegateTokenSet} event.
   */
  function setDelegateToken(address _delegateContract, uint256 _delegateTokenId, uint256 _tokenId, bytes calldata _data) external;

  /**
   * @dev Gets the delegate NFT for `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function getDelegateToken(uint256 _tokenId) external view returns (address contractAddress, uint256 tokenId);

  /**
   * @dev Gives permission to `to` to transfer `tokenId` token to another account.
   * The approval is cleared when the token is transferred.
   *
   * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
   *
   * Requirements:
   *
   * - The caller must own the delegate token.
   * - `tokenId` must exist.
   *
   * Emits an {Approval} event.
   */
  function approveByDelegate(address to, uint256 tokenId) external;
}
