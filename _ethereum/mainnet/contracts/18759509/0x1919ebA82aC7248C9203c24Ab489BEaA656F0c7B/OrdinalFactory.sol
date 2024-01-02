// SPDX-License-Identifier: MIT
// Adapting the Bitcoin ordinal concept to Ethereum with utilizing the flexibility of ERC-1155 to create unique tokens.
// https://t.me/erc1155ordinals
// https://t.me/erc1155ordinalsbot

pragma solidity ^0.8.20;

import "./ERC1155.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract ERC1155OrdinalFactory is ERC1155, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    struct TokenInfo {
        string name;
        uint256 maxTotalSupply;
        uint256 mintedSupply;
        uint256 mintLimit;
    }
    
    
    uint256[] private _allTokenIds;

    mapping(uint256 => TokenInfo) public tokenInfo;
    
    event TokenCreated(uint256 indexed tokenId, string name, uint256 maxTotalSupply, uint256 mintLimit);
    
    constructor() ERC1155("") Ownable(msg.sender) {}

    function createToken(string memory name, uint256 maxTotalSupply, uint256 mintLimit, string memory uri) public onlyOwner returns (uint256) {
        require(maxTotalSupply > 0, "Max total supply must be greater than zero");
        require(mintLimit > 0 && mintLimit <= maxTotalSupply, "Invalid mint limit");
        
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        
        tokenInfo[newTokenId] = TokenInfo({
            name: name,
            maxTotalSupply: maxTotalSupply,
            mintedSupply: 0,
            mintLimit: mintLimit
        });
        
        _allTokenIds.push(newTokenId); 
        
        _setURI(newTokenId, uri);
        emit TokenCreated(newTokenId, name, maxTotalSupply, mintLimit);
        
        return newTokenId;
    }
    
    function mintToken(uint256 tokenId, uint256 amount) public {
        require(tokenInfo[tokenId].mintedSupply + amount <= tokenInfo[tokenId].maxTotalSupply, "Exceeds max total supply");
        require(amount <= tokenInfo[tokenId].mintLimit, "Exceeds mint limit");
        
        _mint(msg.sender, tokenId, amount, "");
        tokenInfo[tokenId].mintedSupply += amount;
    }

    function getAllTokenIds() public view returns (uint256[] memory) {
        return _allTokenIds;
    }

    function _setURI(uint256 tokenId, string memory newuri) internal {
        emit URI(newuri, tokenId);
    }
}