pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";

contract OwnableDelegateProxy {}


contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract HappyBearIsland is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    address proxyRegistryAddress;

    string public baseURI = "https://api.happybearisland.com/bear/";
    
    bool public saleIsActive = false;

    uint public maxTokenSupply = 10000;
    uint maxBearPurchase = 10;
    uint256 bearPrice;
    uint256 airdropSupply;

    constructor(uint _bearPrice, address _proxyRegistryAddress) ERC721("Happy Bear Island", "HBI") { 
        setBearPrice(_bearPrice);
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    function setBaseURI(string calldata _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function buyBears(uint _numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint a Bear");
        require(_numberOfTokens <= maxBearPurchase, "You cannot purchase these many Bear at a time");
        require(totalSupply().add(_numberOfTokens) < maxTokenSupply, "Purchase would exceed max supply");
        require(bearPrice.mul(_numberOfTokens) <= msg.value, "Ether value sent is not correct");

        for (uint i = 0; i < _numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < maxTokenSupply) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function airdropBears(address _to,uint _numberOfTokens) public onlyOwner {
        require(totalSupply().add(_numberOfTokens) < maxTokenSupply, "Purchase would exceed max supply");

        for (uint i = 0; i < _numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < maxTokenSupply) {
                _safeMint(_to, mintIndex);
            }
        }
    }

    function resumeSale() public onlyOwner {
        saleIsActive = true;
    }

    function pauseSale() public onlyOwner {
        saleIsActive = false;
    }

    function setBearPrice(uint256 _bearPrice) public onlyOwner {
        require(_bearPrice > 0, "sale price cannot be null");
        bearPrice = 1 ether / 1000 * _bearPrice;
    }

    function withdrawAll() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setMaxBearPurchase(uint _maxBearPurchase) public onlyOwner {
        maxBearPurchase = _maxBearPurchase;
    }

    function transferOwnership(address newOwner) override public onlyOwner {
        return super.transferOwnership(newOwner);
    }

     function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }
}
