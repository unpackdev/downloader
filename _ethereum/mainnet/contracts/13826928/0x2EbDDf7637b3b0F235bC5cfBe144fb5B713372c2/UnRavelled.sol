// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Strings.sol";
import "./Ownable.sol";


contract UnRavelled is ERC721, Ownable{
   
    bool public saleActive = false;
    uint256 public currentSupply;
    uint256 public maxSupply = 151;
    uint256 public price = 0.1 ether;
    

    string private baseURI;

    address addwal = 0x3E0C2d6B354A32635E4f511aFC42E651163b6fa9;

    constructor() ERC721("UnRavelled", "Stitches") { 
        
    }
    
    function totalSupply() external view returns (uint) {
        return currentSupply;
    }


    function mint(uint256 numberOfMints) public payable {
        uint256 supply = currentSupply + 1;
        require(saleActive, "Sale must be active to mint");
        require(numberOfMints <= 1, "Invalid purchase amount");
        require(supply + numberOfMints <= maxSupply, "Mint would exceed max supply of nft");
        require(numberOfMints * price <= msg.value, "Amount of ether is not enough");

        currentSupply += numberOfMints;

        for(uint256 i; i < numberOfMints; i++) {
            _mint(msg.sender, supply + i);
        }
    }

    function airdrop(address[] calldata addresses) external onlyOwner {
        uint256 supply = currentSupply + 1;
        require(supply+ addresses.length <= maxSupply,  "This would exceed the max number of allowed nft");
        currentSupply += addresses.length;
        for (uint256 i; i < addresses.length ; i++) {
            _mint(addresses[i], supply + i);
        }
    }
    

    function toggleSale() external onlyOwner {
        saleActive = !saleActive;
    }


    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }
    
    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(payable(addwal).send(balance));
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    function tokensOfOwner(address _owner, uint startId, uint endId) external view returns(uint256[] memory ) {
      uint256 tokenCount = balanceOf(_owner);
      if (tokenCount == 0) {
        return new uint256[](0);
      } else {
        uint256[] memory result = new uint256[](tokenCount);
        uint256 index = 0;
        for (uint256 tokenId = startId; tokenId < endId; tokenId++) {
            if (index == tokenCount) break;

            if (ownerOf(tokenId) == _owner) {
                result[index] = tokenId;
                index++;
            }
        }

        return result;
      }
    }

    function walletOfOwner(address _owner) external view returns(uint256[] memory ) {
      return this.tokensOfOwner(_owner, 0, currentSupply);
    }
    
 
  
}