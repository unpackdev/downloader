// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "./ERC721M.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enum is ERC721M, IERC721Enumerable {
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(IERC165, ERC721M)
    returns (bool)
  {
    return
      interfaceId == type(IERC721Enumerable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
   */
  function tokenOfOwnerByIndex(address owner, uint256 index)
    public
    view
    virtual
    override
    returns (uint256)
  {
    require(
      index < ERC721M.balanceOf(owner),
      'ERC721Enum: owner index out of bounds'
    );
    uint256 counter = 0;
    for (uint256 i = 0; i < _owners.length; ++i) {
      if (owner == _owners[i]) {
        if (counter == index) {
          return i;
        } else {
          ++counter;
        }
      }
    }
    require(false, 'ERC721Enum: owner index out of bounds');
  }

  /**
   * @dev See {IERC721Enumerable-totalSupply}.
   */
  function totalSupply() public view virtual override returns (uint256) {
    return _owners.length;
  }

  /**
   * @dev See {IERC721Enumerable-tokenByIndex}.
   */
  function tokenByIndex(uint256 index)
    public
    view
    virtual
    override
    returns (uint256)
  {
    require(_exists(index), 'ERC721Enumerable: global index out of bounds');
    return index;
  }

  function tokensOfOwner(address owner) public view returns (uint256[] memory) {
    require(
      ERC721M.balanceOf(owner) > 0,
      'ERC721Enum: owner index out of bounds'
    );
    uint256 b = balanceOf(owner);
    uint256[] memory ids = new uint256[](b);
    for (uint256 i = 0; i < b; ++i) {
      ids[i] = tokenOfOwnerByIndex(owner, i);
    }
    return ids;
  }
}
