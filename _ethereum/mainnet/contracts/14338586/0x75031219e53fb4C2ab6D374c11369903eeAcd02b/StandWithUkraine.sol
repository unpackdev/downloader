// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract StandWithUkraine is ERC721A, Ownable {
    using Strings for uint256;
    using SafeMath for uint256;

    string private _rootURI;

    uint256 public cost = 0.02 ether;
    uint256 public maxSupply = 2720 * 500;
    bool public isSaleActive = true;
    
    constructor(string memory __baseUri) ERC721A("Stand With Ukraine TW", "SWUT") {
        _rootURI = __baseUri;
    }

    function mint(uint256 _mintAmount) public payable {
        require(isSaleActive, "Sale is not active");
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "must mint at least 1 NFT");
        require(_mintAmount <= 50, "pre mint limit exceeded");
        require(_mintAmount <= maxSupply, "mint limit exceeded");
        require(supply < maxSupply, "max NFT limit exceeded");        
        require(msg.value >= cost * _mintAmount, "insufficient funds");

        if (supply + _mintAmount > maxSupply)
        {
            _mintAmount = maxSupply - supply;
        }

        _safeMint(msg.sender, _mintAmount);
    }

    function inActiveSale() public onlyOwner {
        isSaleActive = false;
    }   

    function setBaseURI(string memory uri) external onlyOwner {
        _rootURI = uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _rootURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }    

    function withdraw() public payable onlyOwner returns (uint256[] memory){
        uint256 total = address(this).balance ;
        uint256 bt = SafeMath.div(total,uint256(2)) ;
        uint256 buk = SafeMath.sub(total , bt) ;
        (bool successbt, ) = payable(0x25722B2609bD5AFCEB0844F8DD5f8d7C6C12DaDe).call{value: bt}("");
        (bool successbuk, ) = payable(0x165CD37b4C644C2921454429E7F9358d18A45e14).call{value: buk}("");

        require(successbt, "Withdrawal of funds(bt) to failed");
        require(successbuk, "Withdrawal of funds(buk) failed");
        
        uint256[] memory numbers = new uint256[](2);
        numbers[0] = bt;
        numbers[1] = buk;
        return numbers;
  }
}