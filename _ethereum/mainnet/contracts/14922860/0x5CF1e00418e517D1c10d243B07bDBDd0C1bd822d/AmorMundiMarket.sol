// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./AmorMundi.sol";

contract AmorMundiMarket is Ownable, ReentrancyGuard {
    AmorMundi public immutable amor;

    bool marketplaceEnabled = true;

    mapping(uint256 => uint256) public salePrices; // [tokenId] => price
    mapping(uint256 => bool) public sold; // [tokenId] => sold

    event Bought(address indexed owner, uint256 tokenId, uint256 price);

    constructor(
        AmorMundi _amor,
        uint256[] memory _tokens,
        uint256[] memory _prices
    ) {
        amor = _amor;

        setPrices(_tokens, _prices);
    }

    function withdrawFunds() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "ETH TRANSFER FAILED");
    }

    function setPrices(uint256[] memory _tokens, uint256[] memory _prices)
        public
        onlyOwner
    {
        require(_tokens.length == _prices.length, "!same size");
        for (uint256 index = 0; index < _tokens.length; index++) {
            salePrices[_tokens[index]] = _prices[index];
        }
    }

    function toggleSale(bool enabled) external onlyOwner {
        marketplaceEnabled = enabled;
    }

    function buy(uint256 tokenId) external payable nonReentrant {
        require(marketplaceEnabled, "sale closed");
        require(!sold[tokenId], "sold");

        uint256 price = salePrices[tokenId];
        require(price > 0, "token not for sale");
        require(msg.value == price, "invalid price");

        sold[tokenId] = true;
        address owner = amor.ownerOf(tokenId);
        amor.transferFrom(owner, msg.sender, tokenId);

        emit Bought(msg.sender, tokenId, price);
    }
}
