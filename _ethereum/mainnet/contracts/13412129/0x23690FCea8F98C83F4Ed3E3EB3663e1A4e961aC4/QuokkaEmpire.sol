// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";

contract QuokkaEmpire is ERC721Enumerable, Ownable {
    
    using SafeMath for uint256;
    using Strings for uint256;
    using Address for address;

    string public baseUri;
    string public baseExtension;
    uint256 public price = 0.069 ether;
    uint256 public maxSupply = 9669 ;
    uint256 public maxPreSaleSupply = 969;
    uint256 public maxMint = 20;
    uint256 public reserved = 200;
    bool public preSaleOpen = false;
    bool public saleOpen = false;
    mapping(address => bool) public whitelist;
    address private dev = 0xD03B3bF49F6434cB2Cb18C5DD5475Ec8A4eDa4bE;
    
    constructor() ERC721("Quokka Empire", "QE") {
        
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }
    
    function setBaseUri(string memory _uri) public {
        baseUri = _uri;
    }
    
    function mint(uint256 quantity) public payable {
        require(quantity > 0, "Invalid quantity");
        require(quantity <= maxMint, "Mint limit exceeded");
        require(preSaleOpen || saleOpen, "Sale close");
        if(_msgSender() != owner()) {
            if(preSaleOpen && !saleOpen){
                require(totalSupply().add(quantity) <= maxPreSaleSupply, "Max supply exceeded");
                require(whitelist[_msgSender()], "Not whitelisted");
            }else if(saleOpen){
                require(totalSupply().add(quantity) <= maxSupply.sub(reserved), "Max supply exceeded");
            }
            require(price.mul(quantity) <= msg.value, "Incorrect ETH value");
        }
        
        for(uint256 i = 0; i < quantity; ++i) {
            _safeMint(_msgSender(), totalSupply().add(1));
        }
    }
    
    function reserve(address _to, uint256 _quantity) public onlyOwner {        
        require(_quantity > 0 && _quantity <= reserved, "Not enough reserves left");
        require(totalSupply().add(_quantity) <= maxSupply, "Max supply exceeded");
        
        for (uint256 i = 0; i < _quantity; i++) {
            _safeMint(_to, totalSupply().add(1));
        }
        reserved = reserved.sub(_quantity);
    }
    
    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
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
    
    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }
    
    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }
    
    function setWhitelist(address[] calldata newAddresses) public onlyOwner {
        for (uint256 i = 0; i < newAddresses.length; i++)
            whitelist[newAddresses[i]] = true;
    }

    function removeWhitelist(address[] calldata currentAddresses) public onlyOwner {
        for (uint256 i = 0; i < currentAddresses.length; i++)
            delete whitelist[currentAddresses[i]];
    }
    
    function setPreSaleOpen(bool _state) public onlyOwner {
        preSaleOpen = _state;
    }
    
    function setSaleOpen(bool _state) public onlyOwner {
        saleOpen = _state;
    }
    
    function withdraw() public payable onlyOwner {
        transfer(dev, address(this).balance.div(10));
        transfer(_msgSender(), address(this).balance);
    }
    
    function transfer(address _to, uint256 _value) private {
        (bool sent, ) = payable(_to).call{value: _value}("");
        require(sent, "Failed to send Ether");
    }
    
}