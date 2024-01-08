// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./ERC721Enumerable.sol";

/*
* @title ERC721 token for Dood, claimable for hodlers of Niftydudes
*
* @author Niftydude
*/
contract Dood is ERC721Enumerable, ERC721Burnable, Ownable {
    using Strings for uint256;
    
    string private baseTokenURI;

    string public ipfsDescs;

    address private dudesAddress;

    constructor (
        string memory _name, 
        string memory _symbol, 
        string memory _baseTokenURI,
        address _dudesAddress,
        string memory _ipfsDescs
    ) ERC721(_name, _symbol) {
        baseTokenURI = _baseTokenURI;    
        dudesAddress = _dudesAddress;
        ipfsDescs = _ipfsDescs;

        transferOwnership(0x061AF2b3B34bD14Ea9EEDf9388C7c04a77A4718a);
    }

    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;    
    }    

    function setIpfsDescs(string memory _ipfsDescs) external onlyOwner {
        ipfsDescs = _ipfsDescs;
    }               

    function getTraits(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Query for nonexistent token");
        
        return IDudeSista(dudesAddress).getTraits(tokenId);
    } 

    function getSkills(uint256 tokenId) public view returns (uint, uint, uint, uint, uint, uint) {
        require(_exists(tokenId), "Query for nonexistent token");
        
        return IDudeSista(dudesAddress).getSkills(tokenId);
    }     

    function claim(uint256 tokenId) public returns (bool) {
        require(IDudeSista(dudesAddress).ownerOf(tokenId) == msg.sender, "Sender is not the owner");
        require(!_exists(tokenId), "Claim: is already claimed");

        _mint(msg.sender, tokenId); 

        return true;
    }    

    function claimMany(uint256[] memory tokenIndices) public returns (bool) {

        for(uint256 i=0; i < tokenIndices.length; i++) {
            claim(tokenIndices[i]);
        }

        return true;
    }    

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }     

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }   

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }      
}

interface IDudeSista {
    function getSkills(uint256 tokenId) external view returns (uint, uint, uint, uint, uint, uint);
    function getTraits(uint256 tokenId) external view returns (uint);
    function ownerOf(uint256 tokenId) external view returns (address owner);

}

