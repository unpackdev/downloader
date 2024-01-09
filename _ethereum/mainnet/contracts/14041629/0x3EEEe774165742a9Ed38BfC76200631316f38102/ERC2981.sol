// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC165Storage.sol";

import "./IERC2981.sol";

// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
abstract contract ERC2981 is IERC2981, ERC165Storage {
  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

  mapping(uint256 => address) internal _royalties;

  constructor() {
    _registerInterface(_INTERFACE_ID_ERC2981);
  }

  // @inheritdoc	ERC165
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165Storage, IERC2981)
    returns (bool)
  {
    return ERC165Storage.supportsInterface(interfaceId);
  }

  /**
   * @dev Sets token royalties
   * @param id the token id fir which we register the royalties
   * @param receiver receiver of the royalties
   */
  function _setTokenRoyalty(uint256 id, address receiver) internal {
    _royalties[id] = receiver;
  }

  // @inheritdoc	IERC2981
  function royaltyInfo(uint256 tokenId, uint256 salePrice)
    external
    view
    override
    returns (address, uint256)
  {
    address receiver = _royalties[tokenId];
    return (receiver, salePrice / 10);
  }
}
