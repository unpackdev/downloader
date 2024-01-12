// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract ERC721Metadata is ERC721, Ownable {
  using Strings for uint256;

  // Base URI
  string private baseURI;

  constructor(
    string memory name_,
    string memory symbol_,
    string memory baseURI_
  ) ERC721(name_, symbol_) {
    baseURI = baseURI_;
  }

  function setBaseURI(string memory baseURI_) external onlyOwner {
    require(
      keccak256(abi.encodePacked((baseURI))) != keccak256(abi.encodePacked((baseURI_))),
      "ERC721Metadata: existing baseURI"
    );
    baseURI = baseURI_;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
        : "";
  }

  function burn(uint256 tokenId) public virtual {
    //solhint-disable-next-line max-line-length
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      "ERC721Burnable: caller is not owner nor approved"
    );
    _burn(tokenId);
  }
}
