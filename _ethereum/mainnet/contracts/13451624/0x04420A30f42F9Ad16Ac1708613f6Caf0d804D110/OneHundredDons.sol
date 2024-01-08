// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";

// AUTHOR: DONS
// 𝗔𝗜 𝗔𝗥𝗧 𝗖𝗢𝗟𝗟𝗘𝗖𝗧𝗜𝗩𝗘 ⥀

contract OneHundredDons is ERC721, ERC721Enumerable, Ownable {
  using Address for address;

  uint256 public DONS = 100;
  uint256 public mintPrice;
  string internal baseTokenURI;

  constructor(
    uint256 _mintPrice,
    string memory _baseTokenURI
  )
    ERC721("100DONS", "DONS")
  {
    mintPrice = _mintPrice;
    baseTokenURI = _baseTokenURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  function setBaseTokenURI(string memory URI) public onlyOwner {
    baseTokenURI = URI;
  }

  function setMintPrice(uint256 _mintPrice) public onlyOwner {
    mintPrice = _mintPrice;
  }

  function mint(uint256 tokenId) public payable {
    require(tokenId < DONS,         "Token ID out of range");
    require(msg.value == mintPrice, "Invalid Ether amount sent");

    _safeMint(msg.sender, tokenId);
  }

  function withdraw() public onlyOwner {
    Address.sendValue(
      payable(address(_msgSender())),
      address(this).balance
    );
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}