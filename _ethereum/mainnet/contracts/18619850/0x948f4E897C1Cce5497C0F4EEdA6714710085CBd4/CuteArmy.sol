// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./Ownable.sol";
import "./ERC721.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";

contract CUTEARMY is ERC721, Ownable, ERC721Enumerable, ERC721URIStorage {
    using Strings for uint256;
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    
    Counters.Counter private _tokenIds;
    
    mapping(address => bool) private whitelist;
    string public baseTokenURI;
    string public baseExtension = ".json";

    uint256 public constant maxSupply = 2222;
    uint256 public cost =  0.02 ether;
    uint256 public maxPerMint = 2;
    bool public publicsale = false;

    mapping(address => uint256) private mintCounts;
    uint256 private maxMintPerUser = 2;


    bool public isSaleActive = false;
    mapping(address => bool) public whitelisted;

    constructor() ERC721("CuteArmy", "CUTE") {
        string memory FirstbaseURI = "https://nftstorage.link/ipfs/bafybeie7lrz2jjgcwo2eyl6vg6qvzs6r3g5uo37h7mucjwk6ntsyfjv2ry/";
        setBaseURI(FirstbaseURI);
    } 

    function mintNFTs(uint256 _count ) public payable {
        
        if(!publicsale){
            require(isWhitelisted(msg.sender), "Not in WL");
            require(mintCounts[msg.sender] < maxMintPerUser, "Maximum mint");
        }
        if(publicsale){
            if(!whitelist[msg.sender])
                require(mintCounts[msg.sender] < 1, "Maximum mint");
            else
                require(mintCounts[msg.sender] < maxMintPerUser, "Maximum mint");
        }

        if(whitelist[msg.sender]){
            require(_count <= 2 - mintCounts[msg.sender], "Max 2 NFT");
        }
        else{
            require(_count <= 1,"Max 1 NFT");
        }
        
        mintCounts[msg.sender] += _count;

        uint totalMinted = _tokenIds.current();
        
        require(totalMinted.add(_count) <= maxSupply, "Not enough NFTs left!");
        require(_count > 0 && _count <= maxPerMint, "Cannot mint specified number of NFTs.");
        require(msg.value >= cost.mul(_count), "Not enough ether to purchase NFTs.");
        
        (bool transferSuccess, ) = owner().call{value: msg.value}("");
        require(transferSuccess, "Failed to Invest");
      
        if (msg.sender != owner()) {
                require(msg.value >= cost * _count);
        }

        for(uint256 i = 0; i < _count; i++) {
            uint newTokenID = _tokenIds.current();
            _safeMint(msg.sender, newTokenID);
            _tokenIds.increment();
                
        }     
              
    }
    function mintNFTsCount( uint256 _count ) public onlyOwner payable {
        

        uint totalMinted = _tokenIds.current();
        if (msg.sender != owner()) {
                require(msg.value >= cost * _count);
        }
        require(totalMinted.add(_count) <= maxSupply, "Not enough NFTs left!");
        require(_count > 0 && _count <= maxPerMint, "Cannot mint specified number of NFTs.");
        
        (bool transferSuccess, ) = owner().call{value: msg.value}("");
        require(transferSuccess, "Failed to Invest");
      


        for(uint256 i = 0; i < _count; i++) {
            uint newTokenID = _tokenIds.current();
            _safeMint(owner(), newTokenID);
            _tokenIds.increment();
                
        }     
              
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;

    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }


    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
 
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setmaxMintAmount(uint256 _newmaxPerMint) public onlyOwner {
        maxPerMint = _newmaxPerMint;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function flipSaleState() external onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable){
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool){
        return super.supportsInterface(interfaceId);
    }

    function addToWhitelist(address _address) external onlyOwner {
        whitelist[_address] = true;
    }
    function removeFromWhitelist(address _address) external onlyOwner {
        whitelist[_address] = false;
    }

    function flipWLsale() external onlyOwner {
        publicsale = !publicsale;
    }
    function addManyToWhitelist(address[] calldata _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = true;
        }
    }

    function isWhitelisted(address _address) public view returns (bool) {
        if(publicsale){
            return true;
        }
        else
        return whitelist[_address];
    }
    
}