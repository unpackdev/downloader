//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./NFT721.sol";

contract Sales is Ownable{
    NFT721 public nft;
    address payable royaltyAddress;
    address payable cashierAddress;
    uint96 percentage = 500; // 5%
    mapping (uint256 => uint256) prices;

    event BuyToken(address to, uint256 tokenId);
    event BatchSales( uint256[] ids, uint256[] amounts);


    constructor(address nftAddress, address payable _cashierAddress) {
        require(nftAddress != address(0) && nftAddress != address(this), "Invalid address");
        nft = NFT721(nftAddress);
        cashierAddress = _cashierAddress;
        royaltyAddress = _cashierAddress;
    }

    function buyToken(uint256 tokenId, string memory tokenURI) external payable {
        uint256 price = prices[tokenId];
        require(price > 0, "Price is not set yet");
        require(price == msg.value, "Invalid tag price");
        
        (bool sent, ) = cashierAddress.call{value: msg.value}("");
        require(sent, "Failed to send price");
        nft.mint(msg.sender, tokenId, tokenURI, royaltyAddress, percentage);
        emit BuyToken(msg.sender, tokenId);
    }

    function setPrice(uint256[] memory ids,uint256[] memory amounts) external onlyOwner{
        require(ids.length == amounts.length, "Sales: ids and amounts length mismatch");
        for (uint256 i = 0; i < ids.length; i++) {
            prices[ids[i]] = amounts[i];
        }
        emit BatchSales(ids, amounts);
    }

    function updateCashier(address payable newCashier) external onlyOwner{
        require(newCashier != address(0) && newCashier != address(this), "Invalid address");
        cashierAddress = newCashier;
    }

    function updateRoyalty(address payable newRoyaltyAddress, uint96 newPercentage) external onlyOwner{
        require(newRoyaltyAddress != address(0) && newRoyaltyAddress != address(this), "Invalid address");
        require(newPercentage >= 100 && newPercentage <= 10000, "Percentage between 100 and 10000");
        royaltyAddress = newRoyaltyAddress;
        percentage = newPercentage;
    }
}