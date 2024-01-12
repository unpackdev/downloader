// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155.sol";
import "./Ownable.sol";

/*
* @title ERC1155 token for Eralor founders circle
*/


contract FoundersCircle is ERC1155, Ownable  {
    uint256 public maxSupply = 250;
    uint256 public maxPerWallet = 1;
    uint256 public totalSupply;
    uint256 public price = 0.25 ether; 
    bool public isPublicSaleActive;
    string metaData = "ipfs://QmfEusbVJSzi7SJJd6M6iCFnEX27mFX1aeFUbNBuLiUZWw"; 

    constructor() ERC1155("") {  

    }


    /**
    * @notice mint token
    */
    function mint() external payable {
        require(isPublicSaleActive, "Mint is on hold for now");
        require(totalSupply < maxSupply, "Max supply reached");
        require(balanceOf(msg.sender, 0) < maxPerWallet, "Max amount per wallet reached");
        require(msg.value == price);
        _mint(msg.sender, 0, 1, "");
        totalSupply += 1;
    }
 
    /**
    * @notice owner mint token
    */
    function ownerMint(address to, uint256 amount) external onlyOwner {
        require(totalSupply + amount <= maxSupply, "Max supply reached");
        _mint(to, 0, amount, "");
        totalSupply += amount;
    }
 

    /**
    * @notice returns the metadata uri for a given id
    * @param _id the pass id to return metadata for, will always be 0 though
    */
    function uri(uint256 _id) public view override returns (string memory) {
            return metaData;
    }

        //owner functions
    function toggleIsActive() external onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    }

    function withdraw() external onlyOwner { 
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    

     function setPrice(uint256 newPrice) public onlyOwner {
          price = newPrice;
      }

       function setMaxPerWallet(uint256 newMaxPerWallet) public onlyOwner {
          maxPerWallet = newMaxPerWallet;
      }

       function setMetaData(string calldata newMetaData) public onlyOwner {
          metaData = newMetaData;
      }
}
