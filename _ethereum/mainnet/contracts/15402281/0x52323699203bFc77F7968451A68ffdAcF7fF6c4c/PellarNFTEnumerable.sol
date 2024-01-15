// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "./ERC721.sol";
import "./IERC721Enumerable.sol";
import "./BitMaps.sol";

// Pellar + LightLink 2022

abstract contract PellarNFTEnumerable is ERC721, IERC721Enumerable {
  using BitMaps for BitMaps.BitMap;

  // Mapping from owner to list of owned token IDs
  mapping(address => BitMaps.BitMap) internal _ownedTokens;

  // all token ids, used for enumeration
  BitMaps.BitMap internal _allTokens;
  uint256 internal totalCount;

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
    return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
  }

  function tokenByIndex(uint256 _index) public view virtual override returns (uint256) {
    require(_index < PellarNFTEnumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
    uint16 tokenId;
    uint16 currentIdx;
    for (uint16 i = 0; i < 10000; i++) {
      if (!_allTokens.get(i)) continue;
      if (currentIdx == _index) {
        tokenId = i;
        break;
      }
      currentIdx++;
    }
    return tokenId;
  }

  function tokenOfOwnerByIndex(address _owner, uint256 _index) public view virtual override returns (uint256) {
    require(_index < ERC721.balanceOf(_owner), "ERC721Enumerable: owner index out of bounds");
    uint16 tokenId;
    uint16 currentIdx;
    for (uint16 i = 0; i < 10000; i++) {
      if (!_ownedTokens[_owner].get(i)) continue;
      if (currentIdx == _index) {
        tokenId = i;
        break;
      }
      currentIdx++;
    }
    return tokenId;
  }

  function totalSupply() public view virtual override returns (uint256) {
    return totalCount;
  }

  function _beforeTokenTransfer(
    address _from,
    address _to,
    uint256 _tokenId
  ) internal virtual override {
    super._beforeTokenTransfer(_from, _to, _tokenId);

    if (_from == address(0)) {
      _addTokenToAllTokensEnumeration(_tokenId);
    } else if (_from != _to) {
      _removeTokenFromOwnerEnumeration(_from, _tokenId);
    }
    if (_to == address(0)) {
      _removeTokenFromAllTokensEnumeration(_tokenId);
    } else if (_to != _from) {
      _addTokenToOwnerEnumeration(_to, _tokenId);
    }
  }

  function _addTokenToOwnerEnumeration(address _to, uint256 _tokenId) private {
    _ownedTokens[_to].set(_tokenId);
  }

  function _addTokenToAllTokensEnumeration(uint256 _tokenId) private {
    _allTokens.set(_tokenId);
    totalCount++;
  }

  function _removeTokenFromOwnerEnumeration(address _from, uint256 _tokenId) private {
    _ownedTokens[_from].unset(_tokenId);
  }

  function _removeTokenFromAllTokensEnumeration(uint256 _tokenId) private {
    _allTokens.unset(_tokenId);
    if (totalCount > 0) totalCount--;
  }
}
