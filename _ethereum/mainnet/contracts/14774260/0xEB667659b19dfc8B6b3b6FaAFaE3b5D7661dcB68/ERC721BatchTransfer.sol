// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.9;

import "./ERC721Upgradeable.sol";
import "./IERC721BatchTransfer.sol";

contract ERC721BatchTransfer is IERC721BatchTransfer, ERC721Upgradeable {
  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(IERC165Upgradeable, ERC721Upgradeable)
    returns (bool)
  {
    return interfaceId == type(IERC721BatchTransfer).interfaceId || super.supportsInterface(interfaceId);
  }

  /**
   * @inheritdoc IERC721BatchTransfer
   */
  function batchTransferFrom(
    address _from,
    address _to,
    uint256[] memory _tokenIds
  ) public virtual override {
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      transferFrom(_from, _to, _tokenIds[i]);
    }
  }

  /**
   * @inheritdoc IERC721BatchTransfer
   */
  function batchSafeTransferFrom(
    address _from,
    address _to,
    uint256[] memory _tokenIds,
    bytes memory data_
  ) public virtual override {
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      safeTransferFrom(_from, _to, _tokenIds[i], data_);
    }
  }
}
