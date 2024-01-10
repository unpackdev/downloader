//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721URIStorage.sol";


contract IFFrog is ERC721URIStorage,  Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    string private baseURI = "https://funkyfilmfrogs.io/NFT/ICONIC/";

    constructor()  ERC721("Iconic Film Frogs", "IFFrog") {}

    function mintNFT(address recipient)
        public onlyOwner
        returns (uint256)
    {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _safeMint(recipient, newItemId);
        return newItemId;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory base_URI = _baseURI();
        return bytes(base_URI).length > 0 ? string(abi.encodePacked(base_URI, tokenId.toString(),".json")) : "";
    }

    function burn(uint256 tokenId) public onlyOwner {
    require(_exists(tokenId), "Nonexistent token");
    _burn(tokenId);
  }
}
