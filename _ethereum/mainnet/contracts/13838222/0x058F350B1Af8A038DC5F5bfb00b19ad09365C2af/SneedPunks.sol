//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721URIStorage.sol";

contract SneedPunks is ERC721URIStorage, Ownable {
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    function mint(uint256 tokenId, string memory tokenURI)
        public onlyOwner
        returns (uint256)
    {
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenURI);

        return tokenId;
    }

    function mintMany(uint256[] memory tokenIds, string[] memory tokenURIs)
        public onlyOwner
        returns (uint256[] memory)
    {
        require(tokenIds.length == tokenURIs.length, "Mismatched ids and uris");

        for (uint i = 0; i < tokenIds.length; i++) {
            mint(tokenIds[i], tokenURIs[i]);
        }

        return tokenIds;
    }
}
