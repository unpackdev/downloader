/*
 __    __     ______     ______     ______     ______     ______     __
/\ "-./  \   /\  ___\   /\  ___\   /\  ___\   /\  __ \   /\  == \   /\ \
\ \ \-./\ \  \ \  __\   \ \___  \  \ \___  \  \ \  __ \  \ \  __<   \ \ \
 \ \_\ \ \_\  \ \_____\  \/\_____\  \/\_____\  \ \_\ \_\  \ \_\ \_\  \ \_\
  \/_/  \/_/   \/_____/   \/_____/   \/_____/   \/_/\/_/   \/_/ /_/   \/_/
*/

// 🧑‍🚀 Messari Subgraph NFT
// https://github.com/messari/subgraphs

// 👋 We are hiring
// https://messari.io/careers

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract SubgraphNFT is ERC721URIStorage, Ownable {
    string public baseURI;
    Counters.Counter private _tokenIds;
    mapping(uint256 => uint256) public subgraphsBuilt; // tokenId -> subgraphsBuilt

    using Strings for uint256;
    using Counters for Counters.Counter;
    event SubgraphsBuilt(uint256 tokenId, uint256 subgraphsBuilt);

    constructor(string memory URI) ERC721("Messari Subgraph NFT", "SUBGRAPH")
    {
        baseURI = URI;
    }

    function supply() external view returns (uint256)
    {
        return _tokenIds.current();
    }

    function mint(address receiver, uint256 _subgraphsBuilt) external onlyOwner returns (uint256)
    {
        uint256 newItemId = _tokenIds.current();
        _mint(receiver, newItemId);
        _tokenIds.increment();
        subgraphsBuilt[newItemId] = _subgraphsBuilt;
        return newItemId;
    }

    function levelUp(uint256 tokenId) external onlyOwner
    {
        require(subgraphsBuilt[tokenId] > 0);
        subgraphsBuilt[tokenId] += 1;
        emit SubgraphsBuilt(tokenId, subgraphsBuilt[tokenId]);
    }

    function setBaseURI(string memory URI) external onlyOwner
    {
        baseURI = URI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        uint256 level = 1;
        if (subgraphsBuilt[tokenId] >= 16) {
            level = 5;
        } else if (subgraphsBuilt[tokenId] >= 8) {
            level = 4;
        } else if (subgraphsBuilt[tokenId] >= 4) {
            level = 3;
        } else if (subgraphsBuilt[tokenId] >= 2) {
            level = 2;
        } else {
            level = 1;
        }
        return string(abi.encodePacked(baseURI, "/level", level.toString(), ".json"));
    }

    function sweepEth() external onlyOwner
    {
        uint256 _balance = address(this).balance;
        payable(owner()).transfer(_balance);
    }

    receive() external payable {}
}
