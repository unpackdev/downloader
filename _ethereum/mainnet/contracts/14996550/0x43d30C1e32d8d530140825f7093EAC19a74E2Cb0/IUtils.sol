// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IUtils {

    // To keep track of orders
    enum OrderStatus {
        COMPLETED,
        OPEN,
        CANCELED,
        EXPIRED,
        INVALID
    }
    struct Order {
        // Unique Order Id for each item.
        uint256 orderId;
        //this is to check in Ask function if _sender is the token Owner
        address sender;
        // Amount of the currency being asked
        uint256 askAmount;

        // Address to the ERC20 token being asked
        address currency;

        // Address to the ERC721 token being sold
        address nftContract;

        // Token Id of ERC721 for bieng sold.
        uint256 tokenId;

        // The Expiry Time of order
        uint256 expiryTime;

        // Address of the recipient
        address recipient;

        OrderStatus orderStatus;

        // created time
        uint256 createdAt;

        // created time
        uint256 updatedAt;
    }

    struct Bid {
        // Unique Bid Id for each item.
        uint256 bidId;

       //this is to check in Ask function if _sender is the token Owner
        address sender;

        // Amount of the currency being asked
        uint256 bidAmount;

        // Address to the ERC20 token being asked
        address currency;

        // Address to the ERC721 token being sold
        address nftContract;

        // Token Id of ERC721 for being sold.
        uint256 tokenId;

        // The Expiry Time of order
        uint256 expiryTime;

        // Address of the recipient
        address recipient;

        OrderStatus bidStatus;

        // created time
        uint256 createdAt;

        // created time
        uint256 updatedAt;
    }
}