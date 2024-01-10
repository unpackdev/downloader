// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

/****************************************
 * @author: squeebo_nft                 *
 * @team:   GoldenX                     *
 ****************************************
 *        ERC721B provides low-gas      *
 *           mints + transfers          *
 ****************************************/

import "./ERC721B.sol";
import "./IBatch.sol";
import "./IERC721Enumerable.sol";

abstract contract ERC721EnumerableLite is ERC721B, IBatch, IERC721Enumerable {
  function isOwnerOf(address account, uint256[] calldata tokenIds)
    external
    view
    override
    returns (bool)
  {
    for (uint256 i; i < tokenIds.length; ++i) {
      if (_owners[tokenIds[i]] != account) return false;
    }

    return true;
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(IERC165, ERC721B)
    returns (bool)
  {
    return
      interfaceId == type(IERC721Enumerable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function tokenOfOwnerByIndex(address owner, uint256 index)
    public
    view
    override
    returns (uint256 tokenId)
  {
    uint256 count;
    for (uint256 i; i < _owners.length; ++i) {
      if (owner == _owners[i]) {
        if (count == index) return i;
        else ++count;
      }
    }

    require(false, "ERC721Enumerable: owner index out of bounds");
  }

  function tokenByIndex(uint256 index)
    external
    view
    virtual
    override
    returns (uint256)
  {
    require(
      index < totalSupply(),
      "ERC721Enumerable: global index out of bounds"
    );
    return index;
  }

  function totalSupply() public view virtual override returns (uint256) {
    return _owners.length;
  }

  function transferBatch(
    address from,
    address to,
    uint256[] calldata tokenIds,
    bytes calldata data
  ) external override {
    for (uint256 i; i < tokenIds.length; ++i) {
      safeTransferFrom(from, to, tokenIds[i], data);
    }
  }

  function walletOfOwner(address account)
    external
    view
    override
    returns (uint256[] memory)
  {
    uint256 quantity = balanceOf(account);
    uint256[] memory wallet = new uint256[](quantity);
    for (uint256 i; i < quantity; ++i) {
      wallet[i] = tokenOfOwnerByIndex(account, i);
    }
    return wallet;
  }
}
