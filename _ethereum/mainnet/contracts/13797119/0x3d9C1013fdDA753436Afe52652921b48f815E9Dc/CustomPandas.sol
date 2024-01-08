// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./ERC721Enumerable.sol";

contract CustomPandas is ERC721Enumerable, ERC721Burnable, Ownable {
    using Strings for uint256;

    string public ipfsLink;

    constructor (
        string memory _name, 
        string memory _symbol, 
        string memory _ipfsLink
    ) ERC721(_name, _symbol) {
        ipfsLink = _ipfsLink;
    }   

    function setMetadata(string calldata _ipfsLink) external onlyOwner {
        ipfsLink = _ipfsLink;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        for(uint256 i; i < amount; i++) {
            _mint(to, totalSupply() + 1);      
        }
    }        

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(
            _exists(tokenId), 
            "ERC721Metadata: URI query for nonexistent token"
        );

        return bytes(ipfsLink).length > 0 ? 
            string(abi.encodePacked(ipfsLink, tokenId.toString())) : 
            "";
    }    

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }     

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }   
}