// SPDX-License-Identifier: GPL-3.0

/*
    ________            __  __      ____      ______           __ 
  /_  __/ /_  ___      \ \/ /___  / / /__   / ____/________ _/ /_
   / / / __ \/ _ \      \  / __ \/ / //_/  / /_  / ___/ __ `/ __/
  / / / / / /  __/      / / /_/ / / ,<    / __/ / /  / /_/ / /_  
 /_/ /_/ /_/\___/      /_/\____/_/_/|_|  /_/   /_/   \__,_/\__/  
 
*/

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract TheYolkFrat is ERC721Enumerable, Ownable {
    
    using SafeMath for uint256;
    using Strings for uint256;
    using Address for address;

    string public baseUri;
    string public baseExtension;
    uint256 public publicPrice;
    uint256 public preSalePrice;
    uint256 public maxSupply;
    uint256 public maxMintPerTx;
    uint256 public reserved;
    bool public preSaleOpen;
    bool public publicSaleOpen;
    mapping(address => bool) public whitelist;
    
    constructor(
        uint256 _publicPrice,
        uint256 _preSalePrice, 
        uint256 _maxSupply, 
        uint256 _maxMintPerTx, 
        uint256 _reserved,
        string memory _baseUri
    ) ERC721("The Yolk Frat", "YOLK") {
        publicPrice = _publicPrice;
        preSalePrice = _preSalePrice;
        maxSupply = _maxSupply;
        maxMintPerTx = _maxMintPerTx;
        reserved = _reserved;
        baseUri = _baseUri;
        preSaleOpen = false;
        publicSaleOpen = false;   
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }
    
    function saleState() external view returns (uint256, uint256, uint256, uint256, bool, bool) {
        return (
            publicPrice,
            preSalePrice,
            maxSupply,
            totalSupply(), 
            publicSaleOpen,
            preSaleOpen
            );
    }

    function saleState(address addr) external view returns (uint256, uint256, uint256, uint256, bool, bool, bool) {
        return (
            publicPrice,
            preSalePrice,
            maxSupply,
            totalSupply(), 
            publicSaleOpen,
            preSaleOpen,
            whitelist[addr]
            );
    }
    
    function mint(uint256 quantity) external payable {
        require(quantity > 0, "Invalid quantity");
        require(totalSupply().add(quantity) <= maxSupply.sub(reserved), "Max supply exceeded");
        if(_msgSender() != owner()) {
            require(preSaleOpen || publicSaleOpen, "Sale close");
            uint256 price = publicPrice;
            if(preSaleOpen && !publicSaleOpen){
                price = preSalePrice;
                require(whitelist[_msgSender()], "Not whitelisted");
            }
            require(quantity <= maxMintPerTx, "Mint limit exceeded");
            require(price.mul(quantity) <= msg.value, "Incorrect ETH value");
        }
        for(uint256 i = 0; i < quantity; ++i) {
            _safeMint(_msgSender(), totalSupply().add(1));
        }
    }
    
    function gift(address _to, uint256 _quantity) public onlyOwner {  
        require(_to != address(0), "Invalid address");
        require(_quantity > 0 && _quantity <= reserved, "Not enough reserves left");
        require(totalSupply().add(_quantity) <= maxSupply, "Max supply exceeded");
        for (uint256 i = 0; i < _quantity; i++) {
            _safeMint(_to, totalSupply().add(1));
        }
        reserved = reserved.sub(_quantity);
    }
    
    function bulkGift(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++){
            gift(addresses[i], 1);
        }
    }
    
    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for(uint256 i; i < ownerTokenCount; ++i) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata : URI query for nonexistent token");
        return bytes(baseUri).length > 0 ? string(abi.encodePacked(baseUri, tokenId.toString(), baseExtension)) : "";
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }
    
    function setMaxMintPerTx(uint256 _maxMintPerTx) external onlyOwner {
        maxMintPerTx = _maxMintPerTx;
    }
    
    function setPublicPrice(uint256 _publicPrice) external onlyOwner {
        publicPrice = _publicPrice;
    }
    
    function setPreSalePrice(uint256 _preSalePrice) external onlyOwner {
        preSalePrice = _preSalePrice;
    }
    
    function setReserved(uint256 _reserved) external onlyOwner {
        reserved = _reserved;
    }
    
    function setBaseUri(string memory _uri) external onlyOwner {
        baseUri = _uri;
    }
    
    function setBaseExtension(string memory _newBaseExtension) external onlyOwner {
        baseExtension = _newBaseExtension;
    }
    
    function setWhitelist(address[] calldata newAddresses) external onlyOwner {
        for (uint256 i = 0; i < newAddresses.length; i++)
            whitelist[newAddresses[i]] = true;
    }

    function removeWhitelist(address[] calldata currentAddresses) external onlyOwner {
        for (uint256 i = 0; i < currentAddresses.length; i++)
            delete whitelist[currentAddresses[i]];
    }
    
    function setPreSaleOpen(bool _state) external onlyOwner {
        preSaleOpen = _state;
    }
    
    function setPublicSaleOpen(bool _state) external onlyOwner {
        publicSaleOpen = _state;
    }
    
    function withdraw() external onlyOwner {
        transfer(_msgSender(), address(this).balance);
    }
    
    function transfer(address _to, uint256 _value) private {
        (bool sent, ) = payable(_to).call{value: _value}("");
        require(sent, "Failed to send Ether");
    }
}