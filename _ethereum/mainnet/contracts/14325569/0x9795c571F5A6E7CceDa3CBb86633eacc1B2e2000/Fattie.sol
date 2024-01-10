// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract Fattie is ERC721, Ownable {
    uint256 public totalSupply;
    mapping (uint256 => string) private _tokenURIs;

    event MintFattie(address to, uint256 totalSupply);
    
    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {}                                                                                 

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOwner{
        require(_exists(tokenId), "URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[_tokenId];
        
        return _tokenURI;
    }

    function mint(address _to, string memory _tokenURI) public onlyOwner {
        _mint(_to, totalSupply);
        setTokenURI(totalSupply, _tokenURI);
        emit MintFattie(_to, totalSupply);
        totalSupply += 1;
    }
}