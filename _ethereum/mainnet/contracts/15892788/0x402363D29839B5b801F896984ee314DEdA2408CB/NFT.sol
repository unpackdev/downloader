// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";

contract NFT is ERC721, Ownable {
    bool[1001] private stockList;
    string public baseTokenURI;
    constructor() ERC721("CryptoHills for Everyone", "CHfE") {
        stockList[0] = true;
        baseTokenURI = "https://bafybeigrztgr6dcs7naxwbeemnjzkmtsmitzqqhvdxgrvro7apfal5i5ue.ipfs.nftstorage.link/";
    }
    function mintTo(uint256 itemId) 
        public 
        payable 
        returns (uint256) 
    {
        require(stockList[itemId] == false, "The item is sold out");
        uint256 stockCnt = 0;
        for (uint256 i = 0; i < stockList.length; i++) {
            if (!stockList[i]) {
                stockCnt++;
            }
        }
        uint256 salePrice = 0.01 ether;
        if (stockCnt < 900) {
            salePrice = 0.02 ether;
        }
        require(salePrice == msg.value, "The price is different");
        _safeMint(msg.sender, itemId);
        stockList[itemId] = true;
        return itemId;
    }

    function airDropTo(address recipient, uint256 itemId)
        public
        onlyOwner
        returns (uint256)
    {
        if(itemId < 1001){
            stockList[itemId] = true;
        }
        _safeMint(recipient, itemId);     
        return itemId;
    }

    function getStocks() external view returns (bool[1001] memory) {
        return stockList;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
