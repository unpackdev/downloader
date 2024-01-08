// SPDX-License-Identifier: MIT

/*
 __________ _____  / /____  _______ ____  ___  ___ _______
/ __/ __/ // / _ \/ __/ _ \/ __/ _ `/ _ \/ _ \/ -_) __(_-<
\__/_/  \_, / .__/\__/\___/_/  \_,_/ .__/ .__/\__/_/ /___/
       /___/_/                    /_/  /_/
*/

pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract CryptoRappers is ERC721, ERC721Enumerable, Ownable {
    string public PROVENANCE;
    bool public saleIsActive = false;
    string private _baseURIextended;
    uint constant MAX_TOKENS = 10000;
    uint constant NUM_RESERVED_TOKENS = 350;
    uint constant MAX_PUBLIC_MINT = 20;
    uint constant PRICE_PER_TOKEN = 0.05 ether;

    constructor() ERC721("CryptoRappers", "RAP") {
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
      super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
      return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
      _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
      return _baseURIextended;
    }

    function setProvenance(string memory provenance) public onlyOwner {
      PROVENANCE = provenance;
    }

    function reserve(uint256 n) public onlyOwner {
      uint supply = totalSupply();
      uint i;
      for (i = 0; i < n; i++) {
          _safeMint(msg.sender, supply + i);
      }
    }

    function setSaleState(bool newState) public onlyOwner {
      saleIsActive = newState;
    }

    function mint(uint numberOfTokens) public payable {
      uint256 ts = totalSupply();
      require(saleIsActive, "Sale must be active to mint Tokens");
      require(numberOfTokens <= MAX_PUBLIC_MINT, "Exceeded max token purchase");
      require(ts + numberOfTokens <= MAX_TOKENS, "Purchase would exceed max tokens");
      require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");

      for (uint256 i = 0; i < numberOfTokens; i++) {
          _safeMint(msg.sender, ts + i);
      }
    }

    function withdraw() public onlyOwner {
      uint balance = address(this).balance;
      payable(msg.sender).transfer(balance);
    }
}
