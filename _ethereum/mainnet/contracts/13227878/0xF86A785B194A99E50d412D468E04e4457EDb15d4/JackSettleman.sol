// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";

contract JackSettleman is ERC721Enumerable, ERC721URIStorage, ERC721Burnable, Ownable {
    string private baseURI;
    address private storeOwner;
    bool public locked;

    constructor(string memory _name, string memory _symbol, address _storeOwner) ERC721(_name, _symbol) {
        storeOwner = _storeOwner;
        setBaseURI('https://arweave.net/');
    }

    function mint(string memory _tokenURI) public onlyOwners {
        uint256 tokenId = totalSupply() + 1;
            
        _safeMint(msg.sender, tokenId);
        setTokenURI(tokenId, _tokenURI);
    }
    
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
    
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
    
    function setTokenURI(uint256 _tokenId, string memory _tokenURI) public onlyOwners notLocked {
        _setTokenURI(_tokenId, _tokenURI);
    }
    
    function setBaseURI(string memory baseURI_) public onlyOwners notLocked {
        baseURI = baseURI_;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
         return baseURI;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }     

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function lockMetadata() external onlyOwners {
        locked = true;
    }
    
    modifier onlyOwners() {
        require(owner() == _msgSender() || storeOwner == _msgSender(), "caller is not the contract or store owner");
        _;
    }

    modifier notLocked {
        require(!locked, "Contract metadata methods are locked");
        _;
    }
}
