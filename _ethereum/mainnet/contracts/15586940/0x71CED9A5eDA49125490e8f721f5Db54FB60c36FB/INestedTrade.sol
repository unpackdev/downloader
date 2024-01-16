// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

/**
 _  _  ____  ___  ____  ____  ____     ____  ____    __    ____  ____
( \( )( ___)/ __)(_  _)( ___)(  _ \   (_  _)(  _ \  /__\  (  _ \( ___)
 )  (  )__) \__ \  )(   )__)  )(_) )    )(   )   / /(__)\  )(_) ))__)
(_)\_)(____)(___/ (__) (____)(____/    (__) (_)\_)(__)(__)(____/(____)

**/

/// @author Montana Wong, Fabrice Cheng
interface INestedTrade {
    /// @notice The metadata for an ask
    /// @param seller The address of the seller placing the ask
    /// @param buyer The address of the buyer
    /// @param sellerFundsRecipient The address to send funds after the ask is filled
    /// @param askPrice The price to fill the ask
    struct Ask {
        address seller;
        address buyer;
        uint256 askPrice;
        uint256 royaltyFeeBps;
        bytes32 uid;
    }


    /// @notice Emitted when an ask is created
    /// @param tokenId The ERC-721 token ID of the created ask
    event AskCreated(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed buyer,
        uint256 askPrice,
        uint256 royaltyFeeBps,
        bytes32 uid
    );

    /// @notice Emitted when an ask price is updated
    /// @param tokenId The ERC-721 token ID of the updated ask
    event AskPriceUpdated(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed buyer,
        uint256 askPrice,
        uint256 royaltyFeeBps,
        bytes32 uid
    );

    /// @notice Emitted when an ask is canceled
    /// @param tokenId The ERC-721 token ID of the canceled ask
    event AskCanceled(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed buyer,
        uint256 askPrice,
        uint256 royaltyFeeBps,
        bytes32 uid
    );

    /// @notice Emitted when an ask is filled
    /// @param tokenId The ERC-721 token ID of the filled ask
    event AskFilled(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed buyer,
        uint256 askPrice,
        uint256 royaltyFeeBps,
        bytes32 uid
    );

    /// @notice Emitted when an bird is withdrawn without a sale by the original owner
    /// @param tokenId The ERC-721 token ID of the filled ask
    /// @param to The address the bird was withdrawn to
    event BirdWithdrawn(
        uint256 indexed tokenId,
        address indexed to
   );

}
