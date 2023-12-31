// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";

/**
 * @title MintableERC721
 * @dev ERC721 minting logic
 */
contract MintableERC721 is ERC721Enumerable {
  string public baseURI;
  mapping(address => uint256) public mintCounts;

  constructor(string memory name, string memory symbol) ERC721(name, symbol) {
    baseURI = "https://MintableERC721/";
  }

  /**
   * @dev Function to mint tokens
   * @param tokenId The id of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(uint256 tokenId) public returns (bool) {
    require(tokenId < 10000, "exceed mint limit");

    mintCounts[_msgSender()] += 1;
    require(mintCounts[_msgSender()] <= 10, "exceed mint limit");

    _mint(_msgSender(), tokenId);
    return true;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string memory baseURI_) public {
    baseURI = baseURI_;
  }
}
