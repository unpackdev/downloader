// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";

contract TheDelphiCollection is ERC721Enumerable, Ownable {
    
    using Strings for uint256;

      string public baseURI;
      string public baseExtension = ".json";
      uint256 public cost = 0.00 ether;      
      bool public paused = false;
    
      constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
      ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
      }
    
      // internal
      function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
      }
    
      //only owner
      function mint(uint256 _mintAmount) public payable onlyOwner() {
        uint256 supply = totalSupply();
        require(!paused);
        require(_mintAmount > 0);   
    
        for (uint256 i = 1; i <= _mintAmount; i++) {
          _safeMint(_msgSender(), supply + i);
        }
      }
    
      function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
      {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
          tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
      }
    
      function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
      {
        require(
          _exists(tokenId),
          "ERC721Metadata: URI query for nonexistent token"
        );
    
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
      }
    
      //only owner
      function setCost(uint256 _newCost) public onlyOwner() {
        cost = _newCost;
      }      
    
      function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
      }
    
      function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
      }
    
      function pause(bool _state) public onlyOwner {
        paused = _state;
      }
      
      function withdraw(uint amount) public payable onlyOwner {
        payable(msg.sender).transfer(amount);
    }        
}