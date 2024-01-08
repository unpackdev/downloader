// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

/**
 * @title Depressed Og Club ERC-721 token contract.
 * @author Josh Stow (https://github.com/jshstw)
 */
contract DepressedOGClub is ERC721Enumerable, Ownable {
  /** STORAGE */

  using SafeMath for uint256;

  /** 
   * @dev Store baseURI of token contract.
   */
  string private baseURI;

  /**
   * @dev Track current token Id.
   */
  uint256 private _currentTokenId;

  /** FUNCTIONS */

  constructor(string memory __baseURI)
    ERC721("Depressed OG Club", "DOC")
  {
    baseURI = __baseURI;
  }

  /**
   * @dev Mints token with specified tokenId to address.
   * @param to address Of new token owner
   */
  function mintTo(address to) public onlyOwner {
    uint256 newTokenId = _getNextTokenId();
    _mint(to, newTokenId);
    _incrementTokenId();
  }

  /**
   * @dev Returns tokenURI of token with given tokenId.
   * @param _tokenId uint256 Id of token
   * @return string Specific token URI */
  function tokenURI(uint256 _tokenId) override public view returns (string memory) {
    require(_exists(_tokenId), "ERC721: URI query for nonexistent token");
    return string(abi.encodePacked(_baseURI(), Strings.toString(_tokenId)));
  }

  /**
   * @dev Returns baseURI.
   */
  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  /**
   * @dev calculates the next token ID based on value of _currentTokenId
   * @return uint256 for the next token ID
   */
  function _getNextTokenId() private view returns (uint256) {
    return _currentTokenId.add(1);
  }

  /**
   * @dev increments the value of _currentTokenId
   */
  function _incrementTokenId() private {
    _currentTokenId++;
  }
}