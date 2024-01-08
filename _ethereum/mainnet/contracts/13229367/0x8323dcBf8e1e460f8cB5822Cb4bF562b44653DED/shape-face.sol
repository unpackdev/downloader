// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";


contract ShapeFaces is ERC721, Ownable  {

    
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    
    uint[]  seeds = new uint[](0);
    
    uint256 public tokenPrice = 29000000000000000; // 0.029 ETH
    uint256 public maxTokens = 7777;
    uint256 public preSaleTokens = 777+200;
    bool public mainSaleActive = false; // if false means pre-sale only active

    string public baseURI = "https://api.shapefaces.com/";
    
    bool public reserved = false;

    event ShapeFacesPriceChanged(uint256 price);
    event MaxTokenAmountChanged(uint256 value);
    event MaxPurchaseChanged(uint256 value);
    event ShapeFacesReserved();
    event RolledOver(bool status);
    
    
    function totalSupply() public view returns (uint256){
        return _tokenIdCounter.current() ;
    }
    
    function reserveShapeFaces() public onlyOwner onReserve {
        uint supply = totalSupply();
        uint i;
        for (i; i < 200; i++) {
            _safeMint(_msgSender(), supply + i);
            seeds.push(uint(keccak256(abi.encodePacked(block.difficulty, blockhash(block.number),block.timestamp, _tokenIdCounter.current()))));
            _tokenIdCounter.increment();

        }
    }
    
    modifier onReserve() {
        require(!reserved, "Tokens reserved");
        _;
        reserved = true;
        emit ShapeFacesReserved();
    }
    
    function setPrice(uint256 _amt) public onlyOwner {
        tokenPrice = _amt;
    }
    
    function setMaxTokens(uint256 _amt) public onlyOwner {
        maxTokens = _amt;
    }



    function setPreSaleAmount(uint256 _amt) public onlyOwner {
        preSaleTokens = _amt;
    }
    
    function setURI(string memory url) public onlyOwner {
        baseURI = url;
    }


   function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        address payable sender = payable(msg.sender); // Correct since Solidity >= 0.6.0
        sender.transfer(balance);
    }
    
     function sale(bool value) public onlyOwner {
        mainSaleActive=value;
    }


    constructor() ERC721("Shape Faces", "SHAPE") {
        baseURI = string(abi.encodePacked(baseURI,"0x", toAsciiString(address(this)),"/"));
    }

    function getSeed(uint token_id) public view returns (uint){
        return seeds[token_id];
    }

    function getMintCount() public view returns (uint){
        return _tokenIdCounter.current();
    }
    
    function mint(uint amount) public payable{
        require(amount > 0);
        require(amount < 11);
        require(_tokenIdCounter.current() + amount <= maxTokens, "Purchase would exceed max supply of ShapeFaces");
        require(tokenPrice * amount == msg.value, "Ether value sent is not correct");
        if(!mainSaleActive){
            require(_tokenIdCounter.current() + amount <= preSaleTokens, "Purchase would exceed max pre-sale supply of ShapeFaces");
        }

        for(uint index=0;index < amount; index++){
            _safeMint(msg.sender, _tokenIdCounter.current());
            seeds.push(uint(keccak256(abi.encodePacked(block.difficulty, blockhash(block.number),block.timestamp, _tokenIdCounter.current()))));
            _tokenIdCounter.increment();
            
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    
    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }
    
    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

}


