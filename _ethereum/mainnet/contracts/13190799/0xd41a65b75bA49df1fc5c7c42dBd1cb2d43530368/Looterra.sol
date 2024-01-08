// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721Metadata.sol";
import "./Strings.sol";
import "./ERC721.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

interface LootInterface {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}
/// @title A ERC721 contract to mint random planets with random on-chain resources.
/// @author Brandon Mercado looterra.nft@gmail.com 
/// @notice Big shout out to Jenna and Devon for putting up with me while working on Looterra.
/// @notice Looterra was inspired by Dom Hofmann's Loot project and Sam Mason de Caires's Maps Project. Special thanks to Deep-Fold.

contract Looterra is ERC721, ERC721Enumerable, ReentrancyGuard, Ownable{
    
    uint256 public lootOwnerPrice = 25000000000000000; //0.025 ETH
    uint256 public publicPrice =    50000000000000000; //0.05 ETH
    address public lootAddress = 0xFF9C1b15B16263C61d017ee9F65C50e4AE0113D7; 
    uint256[2] private resourceRange = [3, 10];

    LootInterface lootContract = LootInterface(lootAddress);
    using Strings for uint256;
    string private baseURI;
    
    constructor(string memory baseUri) ERC721("Looterra", "Terra") { 
        baseURI = baseUri;
    }
    
    string[] private resource = [
        "Hydrogen Node",
        "Helium Node",
        "Oxygen Node",
        "Nitrogen Node",
        "Aluminium Node",
        "Carbon Node",
        "Silicon Node",
        "Magnesium Node",
        "Iron Node",
        "Sulphur Node"
    ];
    
    //randomize functions
    function _random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function randomFromRange(uint256 tokenId, uint256[2] memory rangeTuple)internal pure returns (uint256){
        uint256 rand = _random(string(abi.encodePacked(Strings.toString(tokenId))));
        return (rand % (rangeTuple[1] - rangeTuple[0])) + rangeTuple[0];
    }
    
    // functions to check planet resource nodes 
    function getResourceCount(uint256 tokenId) public view returns (uint256){
        require(_exists(tokenId), "Token ID is invalid");
        return randomFromRange(tokenId, resourceRange);
    }

    function getResourceNode(uint256 tokenId, uint256 resourceIndex) public view returns (string memory){
        require(_exists(tokenId), "Token ID is invalid");
        uint256 resourceCount = getResourceCount(tokenId);
        require(resourceIndex >= 0 && resourceIndex < resourceCount,"Resource Index is invalid");
        uint256 rand = _random(string(abi.encodePacked(Strings.toString(tokenId),Strings.toString(resourceIndex))));
        string memory output;
        string memory resourceName;
        uint256 roll = rand % 100;
        resourceName = resource[rand % resource.length];
        output = string(abi.encodePacked(" ", resourceName, output));
        
        if (roll <= 5) {
            output = string(abi.encodePacked("Rich ", output));
        }

        if (roll > 5 && roll <= 15) {
            output = string(abi.encodePacked("Abundant ", output)); 
        }

        if (roll > 60) {
            output = string(abi.encodePacked("Common ", output)); 
        }
        
        if (roll > 30 && roll <= 60) {
            output = string(abi.encodePacked("Poor ", output)); 
        }

        if (roll > 15 && roll <= 30) {
            output = string(abi.encodePacked("Scarce ", output)); 
        }
        
        return output;
    }

    function getAllResourceNodes(uint256 tokenId) public view returns (string[] memory){
        require(_exists(tokenId), "Token ID is invalid");
        uint256 resourceCount = getResourceCount(tokenId);
        string[] memory arr = new string[](resourceCount);
        for (uint256 index = 0; index < resourceCount; index++) {
            string memory name = getResourceNode(tokenId, index);
            arr[index] = name;
        }
        return arr;
    }
    
    function setBaseURI(string memory baseURI_) external onlyOwner() {
        baseURI = baseURI_;
    }

    function tokenURI(uint256 tokenId) override view public returns (string memory) {
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : ""; 
    }
    
    function lootOwnerMint(uint256 tokenId) public payable nonReentrant {
        require(msg.value >= lootOwnerPrice, "Ether value sent is not correct");
        require(lootContract.ownerOf(tokenId) == msg.sender, "Not Loot owner");
        require(tokenId > 0 && tokenId < 8001, "Token ID invalid");
        _safeMint(msg.sender, tokenId);
    }
    
    function lootOwnerMultiMint(uint[] memory lootIds) public payable nonReentrant {
        require(msg.value >= (lootOwnerPrice * lootIds.length), "Ether value sent is not correct");
        
        for (uint i=0; i<lootIds.length; i++) {
            require(lootContract.ownerOf(lootIds[i]) == msg.sender, "Not the owner of this loot");
            require(!_exists(lootIds[i]), "One of these tokens has already been minted");
            _safeMint(msg.sender, lootIds[i]);
        }
    }
    
    function publicMint(uint256 tokenId) public payable nonReentrant { 
        require(msg.value >= publicPrice, "Ether value sent is not correct");
        require(tokenId > 8000 && tokenId < 9901, "Token ID invalid");
        _safeMint(msg.sender, tokenId);       
        }
    
    function ownerClaim(uint256 tokenId) public nonReentrant onlyOwner {
        require(tokenId > 9900 && tokenId < 10002, "Token ID invalid");
        _safeMint(owner(), tokenId);
    }

    function sendEther(address payable recipient) external onlyOwner {
        recipient.transfer(address(this).balance);
        }
    
    function setPublicPrice(uint256 newPrice) public onlyOwner { 
        publicPrice = newPrice;
        }
    function setlootOwnerPrice(uint256 newPrice) public onlyOwner {
        lootOwnerPrice = newPrice;
        }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable){
            super._beforeTokenTransfer(from, to, tokenId);
        }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
        }
}
