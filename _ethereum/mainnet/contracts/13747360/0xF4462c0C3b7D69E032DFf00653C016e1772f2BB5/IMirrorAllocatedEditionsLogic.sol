// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

interface IMirrorAllocatedEditionsLogic {
    event RoyaltyChange(
        address indexed oldRoyaltyRecipient,
        uint256 oldRoyaltyPercentage,
        address indexed newRoyaltyRecipient,
        uint256 newRoyaltyPercentage
    );

    struct NFTMetadata {
        string name;
        string symbol;
        string baseURI;
        bytes32 contentHash;
        uint256 quantity;
    }

    function initialize(
        NFTMetadata memory metadata,
        address operator_,
        address payable fundingRecipient_,
        address payable royaltyRecipient_,
        uint256 royaltyPercentage_,
        uint256 price,
        bool list,
        bool open,
        uint256 feePercentage
    ) external;

    function setRoyaltyInfo(
        address payable royaltyRecipient_,
        uint256 royaltyPercentage_
    ) external;
}
