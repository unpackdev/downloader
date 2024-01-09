// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC721A.sol";

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract LarryDavids is ERC721A, Ownable {
    using Strings for uint256;

    //Utility
    uint256 public maxSupply = 10000;
    uint256 public freeAmount = 1000;
    uint256 public maxPerMint = 10;

    uint256 public _price = 0.03 ether;
    bool public _paused = false;
    string public _baseTokenURI;
    string public _baseTokenEXT;



    constructor(string memory _initBaseURI,string memory _initBaseExt) ERC721A("Larry Davids", "Larry") {
       changeURLParams(_initBaseURI,_initBaseExt);

    }

    function mint(address _to, uint256 _mintAmount) public payable {
        require(_mintAmount > 0, ": Amount should be greater than 0.");
        require(_mintAmount <= maxPerMint, ": Maximum minting amount = 20/transaction.");
        require(!_paused, ": Contract paused.");
        uint256 supply = totalSupply();
        if(supply >=freeAmount){
            require(msg.value >= _price * _mintAmount, ": Insufficient funds.");
        }   
        else{
            require(supply + _mintAmount <= freeAmount , ": No more Free NFTs to mint, decrease the quantity.");
        }
        require(supply + _mintAmount <= maxSupply , ": No more NFTs to mint, decrease the quantity or check out OpenSea.");
        
        
        _safeMint(msg.sender, _mintAmount);

    }


    function _baseURI() internal view virtual override returns (string memory) {
            return _baseTokenURI;
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(),_baseTokenEXT)) : "";
        
    }
    function changeURLParams(string memory _nURL, string memory _nBaseExt) public onlyOwner {
        _baseTokenURI = _nURL;
        _baseTokenEXT = _nBaseExt;
    }


    function setPrice(uint256 newPrice) public onlyOwner() {
        _price = newPrice;
    }
    

    function pause(bool val) public onlyOwner() {
        _paused = val;
    }


    function withdrawAll() public onlyOwner() {
        require(payable(msg.sender).send(address(this).balance));
    }
    
    
}