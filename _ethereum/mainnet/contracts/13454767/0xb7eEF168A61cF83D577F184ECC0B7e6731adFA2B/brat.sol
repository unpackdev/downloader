// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
▄▄▄▄· ▄▄▄   ▄▄▄· ▄▄▄▄▄ ▄▄▄· ▄▄▄·  ▄▄· ▄ •▄ 
▐█ ▀█▪▀▄ █·▐█ ▀█ •██  ▐█ ▄█▐█ ▀█ ▐█ ▌▪█▌▄▌▪
▐█▀▀█▄▐▀▀▄ ▄█▀▀█  ▐█.▪ ██▀·▄█▀▀█ ██ ▄▄▐▀▀▄·
██▄▪▐█▐█•█▌▐█ ▪▐▌ ▐█▌·▐█▪·•▐█ ▪▐▌▐███▌▐█.█▌
·▀▀▀▀ .▀  ▀ ▀  ▀  ▀▀▀ .▀    ▀  ▀ ·▀▀▀ ·▀  ▀ 2021.

*/
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";



contract BratPackNFT is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public constant bratPackMax = 11111;
    uint256 public constant purchaseLimit = 20;

    uint256 private bratPrice = 0.03 ether;

    uint256 public amountMinted;
    bool public saleLive;
    
    string private _contractURI = '';
    string private _tokenBaseURI = '';
    string private _tokenRevealedBaseURI = '';
    
    address bpc = 0xFCD07e7a9e74c5042c49A1238Bc97550FaEf6F9C;
    address bpdev = 0x91e0540Ff3BFEE048857A4B7CdD5dFc64A765b2D;
    

    constructor() ERC721("BratPack", "BRAT") { 
        
    }
    

    
 function mint(uint256 numberOfTokens) external payable {
    require(!saleLive, 'Contract is not active');
    require(totalSupply() < bratPackMax, 'No Tokens Left');
    require(numberOfTokens <= purchaseLimit, 'You are over the minting max');
    require(amountMinted + numberOfTokens <= bratPackMax, 'No Tokens Left');
    require(bratPrice * numberOfTokens <= msg.value, 'ETH amount is not enough');

    for (uint256 i = 0; i < numberOfTokens; i++) {
      if (amountMinted < bratPackMax) {
        uint256 tokenId = amountMinted + 1;
        amountMinted += 1;
        _safeMint(msg.sender, tokenId);
      }
    }
  }



  function gift(address[] calldata to) external onlyOwner {
    require(totalSupply() < bratPackMax, 'No Tokens Left');
    require(amountMinted + to.length <= bratPackMax, 'No tokens left');

    for(uint256 i = 0; i < to.length; i++) {
      uint256 tokenId = amountMinted + 1;

      amountMinted += 1;
      _safeMint(to[i], tokenId);
    }
  }
   
        function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance / 2;
        require(payable(bpc).send(balance));
        require(payable(bpdev).send(balance));
    }
    
    function toggleSaleStatus() external onlyOwner {
        saleLive = !saleLive;
    }
    

  function setContractURI(string calldata URI) external onlyOwner {
    _contractURI = URI;
  }

  function setBaseURI(string calldata URI) external onlyOwner {
    _tokenBaseURI = URI;
  }

  function setRevealedBaseURI(string calldata revealedBaseURI) external onlyOwner {
    _tokenRevealedBaseURI = revealedBaseURI;
  }

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }   
    function setPrice(uint256 _newPrice) public onlyOwner() {
        bratPrice = _newPrice;
    }
    
    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
    require(_exists(tokenId), 'Token does not exist');

    string memory revealedBaseURI = _tokenRevealedBaseURI;
    return bytes(revealedBaseURI).length > 0 ?
      string(abi.encodePacked(revealedBaseURI, tokenId.toString())) :
      _tokenBaseURI;
  }

    
    
 
}