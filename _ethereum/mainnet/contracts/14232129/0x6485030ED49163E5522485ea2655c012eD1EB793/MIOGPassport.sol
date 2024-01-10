// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract MIOGPassport is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string public baseURI;

    mapping(address => uint256) public tokensPerWallet;

    constructor(
        string memory _initBaseURI
    ) ERC721("MetaIsland OG Passport", "MIOGP") {
        setBaseURI(_initBaseURI);
    }

    function airdrop(address[] calldata addresses) external onlyOwner {
      uint256 supply = totalSupply();
      for (uint256 i = 0; i < addresses.length; i++) {
        address thisAddress = addresses[i];
        if(tokensPerWallet[thisAddress] < 1) {
          _safeMint(thisAddress, supply + i);
          tokensPerWallet[thisAddress] = 1;
        }
      }
    }

    function revokePassport(uint256 _tokenId) external onlyOwner {
        _transfer(ownerOf(_tokenId), msg.sender, _tokenId);
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        if (tokenId < 500000) {
            return baseURI;
        }
        return tokenId.toString();
    }

}
