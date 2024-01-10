// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721Enumerable.sol";
import "./UniqMeta.sol";
import "./Mintable.sol";

contract CryptoCossacks is ERC721Enumerable, UniqMeta, Mintable {

  string private _baseTokenURI;

  constructor(
    address[] memory founders,
    string memory baseTokenURI
  )
    ERC721("CryptoCossacks", "CCS")
    Mintable(founders)
  {
    _baseTokenURI = baseTokenURI;
  }

  /**
   * @dev Base metadata URI
   */
  function baseURI()
    public
    view
    returns (string memory output)
  {
    return _baseURI();
  }

  /**
   * @dev tokenURI override
   */
  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721)
    returns (string memory output)
  {
    return super.tokenURI(tokenId);
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {ERC721-_baseURI}.
   */
  function _baseURI()
    internal
    view
    override(ERC721)
    returns (string memory)
  {
    return _baseTokenURI;
  }

  /**
   * @dev _beforeTokenTransfer override
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  )
    internal
    override(ERC721, ERC721Enumerable)
  {
    super._beforeTokenTransfer(from, to, tokenId);
  }
}
