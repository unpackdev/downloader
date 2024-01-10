// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract PHOWLERZ is ERC721A, Ownable {
  using Strings for uint256;
  
  uint256 public constant PRICE = 0.013 ether;
  uint256 public constant MAX_SUPPLY = 5000;
  bool public paused = true;
  string baseURI;

  constructor() ERC721A("PHOWLERZ", "PHOWL") {}

  /// PRIVATE
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  /// PUBLIC
  function mint(uint256 quantity) external payable {
    require (!paused, "Paused");
    require (quantity > 0 && quantity <= 20, "Max 20 per tx");
    require (totalSupply() + quantity <= MAX_SUPPLY, "Exceeded supply");
    require (msg.value >= (PRICE * quantity), "Not enough funds to cover fees");
    require (msg.sender == tx.origin, "No contracts");

    _safeMint(msg.sender, quantity);
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require (_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    string memory currentBaseURI = _baseURI();

    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"))
        : "ipfs://QmPqcyUNWPJ1cmFS7UiPPMdPNvusxh4XsRxMKQvuh5E4eA";
  }

  /// OWNABLE
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function flipPause() public onlyOwner {
    paused = !paused;
  }
 
  function withdraw() public payable onlyOwner {
    (bool success, ) = payable(owner()).call{value: address(this).balance}("");
    require (success);
  }
}