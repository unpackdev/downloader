
// SPDX-License-Identifier: BSD-3
pragma solidity ^0.8.17;

import "./IERC721Enumerable.sol";
import "./ERC721BUpgradeable.sol";

import "./ERC721BStorage.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableBUpgradeable is ERC721BUpgradeable, IERC721Enumerable {
  using ERC721BStorage for bytes32;

  //function balanceOf(address) public returns(uint256);

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721BUpgradeable, IERC165) returns(bool) {
    return interfaceId == type(IERC721Enumerable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
   */
  function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
    require(index < ERC721BUpgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");

    uint256 count;
    uint256 tokenId;
    TokenRange memory _range = range();
    TokenContainer storage container = TokenSlot.getTokenStorage();
    for(tokenId = _range.lower; tokenId < _range.upper; ++tokenId){
      if(owner != container._tokens[tokenId].owner)
        continue;

      if( index == count++ )
        break;
    }
    return tokenId;
  }

  /**
   * @dev See {IERC721Enumerable-totalSupply}.
   */
  function totalSupply() public view virtual override(ERC721BUpgradeable, IERC721Enumerable) returns(uint256) {
    return ERC721BUpgradeable.totalSupply();
  }

  /**
   * @dev See {IERC721Enumerable-tokenByIndex}.
   */
  function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
    require(index < ERC721EnumerableBUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
    return range().lower + index;
  }
}
