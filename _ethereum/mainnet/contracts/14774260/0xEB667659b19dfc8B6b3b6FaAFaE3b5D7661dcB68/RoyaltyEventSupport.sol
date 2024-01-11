// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.9;

import "./ERC2981Upgradeable.sol";

abstract contract RoyaltyEventSupport is ERC2981Upgradeable {
  /**
   * @dev Emitted when the default royalty is updated.
   */
  event DefaultRoyaltyChanged(address indexed receiver, uint96 indexed feeNumerator);

  /**
   * @dev Emitted when a token royalty is updated.
   */
  event TokenRoyaltyChanged(uint256 indexed tokenId, address indexed receiver, uint96 indexed feeNumerator);

  /**
   * @inheritdoc ERC2981Upgradeable
   */
  function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual override {
    super._setDefaultRoyalty(receiver, feeNumerator);
    emit DefaultRoyaltyChanged(receiver, feeNumerator);
  }

  /**
   * @inheritdoc ERC2981Upgradeable
   */
  function _deleteDefaultRoyalty() internal virtual override {
    super._deleteDefaultRoyalty();
    emit DefaultRoyaltyChanged(address(0), 0);
  }

  /**
   * @inheritdoc ERC2981Upgradeable
   */
  function _setTokenRoyalty(
    uint256 tokenId,
    address receiver,
    uint96 feeNumerator
  ) internal virtual override {
    super._setTokenRoyalty(tokenId, receiver, feeNumerator);
    emit TokenRoyaltyChanged(tokenId, receiver, feeNumerator);
  }

  /**
   * @inheritdoc ERC2981Upgradeable
   */
  function _resetTokenRoyalty(uint256 tokenId) internal virtual override {
    super._resetTokenRoyalty(tokenId);
    emit TokenRoyaltyChanged(tokenId, address(0), 0);
  }
}
