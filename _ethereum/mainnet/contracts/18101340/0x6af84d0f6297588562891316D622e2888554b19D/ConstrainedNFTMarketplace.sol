// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./IERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IConstrainedNFT.sol";
import "./console.sol";

contract ConstrainedNFTMarketplace is Ownable, ReentrancyGuard {

    IConstrainedNFT public nftContract;
    uint256 public tokenId;
    uint256 public price;

    bool public isPriceSet;
    bool public forSale;
    address payable public seller;

    event TokenListed(uint256 price);
    event TokenDelisted();
    event TokenSold(address buyer, address seller, uint256 price);

    error ListTokenWithNoPriceSet();
    error MessageSenderIsNotTokenOwner();
    error PriceAlreadySet();
    error PriceTooHigh();
    error YouDidntPayEnough();
    error TokenIsNotForSale();
    error TooMuchPaid();
    error TransferFailed();

    constructor(IConstrainedNFT _nftContract) {
        nftContract = _nftContract;
        tokenId = 1;
    }

    function listToken(uint256 _price) external {

        if (nftContract.ownerOf(tokenId) != msg.sender) {
            revert MessageSenderIsNotTokenOwner();
        }

        if (_price > price && isPriceSet) {
            revert PriceTooHigh();
        }

        price = _price;
        isPriceSet = true;
    
        seller = payable(msg.sender);

        forSale = true;

        emit TokenListed(price);
    }

    function buyToken() external payable nonReentrant {

        // CHECK
        if(!forSale) {
            revert TokenIsNotForSale();
        }

        if (msg.value > price) {
            revert TooMuchPaid();
        }

        if (msg.value < price) {
            revert YouDidntPayEnough();
        }

        // EFFECT
        // Modify state before the external call to avoid reentrancy
        forSale = false;

        // INTERACTION
        nftContract.safeTransferFrom(seller, msg.sender, tokenId);

        // Send the fixed price
        (bool success, ) = seller.call{value: msg.value}("");

        // Make sure the payment went through
        if (!success) {
            revert TransferFailed();
        }

        emit TokenSold(msg.sender, seller, msg.value);
    }
}
