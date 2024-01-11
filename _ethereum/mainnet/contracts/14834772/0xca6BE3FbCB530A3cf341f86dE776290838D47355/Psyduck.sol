// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
contract Psyduck is ERC721A, Ownable {
  constructor() ERC721A("Meta Psyduck ", "MP") {
    _defaultTokenURI = "ipfs://QmdSoV7qBkDQoPDkZpMRH3u11R14JEUHmoXoaHGA965ESP";
  }
  using Strings for uint256;
  uint256 public constant MAX_SUPPLY = 5000;
  uint256 public constant MINT_PRICE = 0.0005 ether;
  string private _baseTokenURI;
  string private _defaultTokenURI;

  function mint(uint256 quantity) external payable {
    require(msg.value == MINT_PRICE * quantity, "Ether not match");
    require(totalSupply() + quantity <= MAX_SUPPLY, "Exceed alloc");
    _safeMint(msg.sender, quantity);
  }

  function setBaseURI(string calldata URI) external onlyOwner {
    _baseTokenURI = URI;
  }

  function setDefaultTokenURI(string calldata URI) external onlyOwner {
    _defaultTokenURI = URI;
  }

  function baseURI() public view returns (string memory) {
    return _baseTokenURI;
  }

  function tokenURI(uint256 tokenId) public override view returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    string memory _baseURI = baseURI();
    return bytes(_baseURI).length > 0 ? string(abi.encodePacked(_baseURI, tokenId.toString())) : _defaultTokenURI;
  }

  function withdraw() external onlyOwner {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }
}