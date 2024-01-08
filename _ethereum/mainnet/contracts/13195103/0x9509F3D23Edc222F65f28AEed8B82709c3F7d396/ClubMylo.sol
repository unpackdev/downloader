// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

/**
 * @title ClubMylo ERC-721 token contract.
 * @author Josh Stow (https://github.com/jshstw)
 */
contract ClubMylo is ERC721Enumerable, Ownable {
  /** STORAGE */

  string private baseURI;

  /** FUNCTIONS */

  constructor(string memory __baseURI)
    ERC721("Club Mylo", "CM")
  {
    baseURI = __baseURI;
  }

  /**
   * @dev Mints token with specified tokenId to address.
   * @param to address Of new token owner
   * @param newTokenId uint256 Id of new token
   */
  function mintTo(address to, uint256 newTokenId) public onlyOwner {
    _mint(to, newTokenId);
  }

  /**
   * @dev Returns baseURI.
   */
  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  /**
   * @dev Returns contractURI.
   */
  function contractURI() public view returns (string memory) {
    return string(abi.encodePacked(_baseURI(), "contract"));
  }

  /**
   * @dev Returns tokenURI of token with given tokenId.
   * @param _tokenId uint256 Id of token
   * @return string Specific token URI */
  function tokenURI(uint256 _tokenId) override public view returns (string memory) {
    require(_exists(_tokenId), "ClubMylo: URI query for nonexistent token");
    return string(abi.encodePacked(_baseURI(), Strings.toString(_tokenId)));
  }
}