// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

/// @title Commands
/// @notice Commands are used to specify how tokens are transferred in Data.buyTokenTransfers and Data.sellTokenTransfers
library Commands {
    bytes1 internal constant SIMPLE_TRANSFER = 0x00; // simple transfer with standard transferFrom
    bytes1 internal constant PERMIT2_TRANSFER = 0x01; // transfer using permit2.transfer
    bytes1 internal constant CALL_PERMIT_THEN_TRANSFER = 0x02; // call permit then simple transfer
    bytes1 internal constant CALL_PERMIT2_THEN_TRANSFER = 0x03; // call permit2.permit then permit2.transfer
    bytes1 internal constant NATIVE_TRANSFER = 0x04;
    bytes1 internal constant NFT_ERC721_TRANSFER = 0x05;
    bytes1 internal constant NFT_ERC1155_TRANSFER = 0x06;
}

/// @title JamOrder
library JamOrder {

    address internal constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev Data representing a Jam Order.
    struct Data {
        address taker;
        address receiver;
        uint256 expiry;
        uint256 nonce;
        address executor; // only msg.sender=executor is allowed to execute (if executor=address(0), then order can be executed by anyone)
        uint16 minFillPercent; // 100% = 10000, if taker allows partial fills, then it could be less than 100%
        bytes32 hooksHash; // keccak256(pre interactions + post interactions)
        address[] sellTokens;
        address[] buyTokens;
        uint256[] sellAmounts;
        uint256[] buyAmounts;
        uint256[] sellNFTIds;
        uint256[] buyNFTIds;
        bytes sellTokenTransfers; // Commands sequence of sellToken transfer types
        bytes buyTokenTransfers; // Commands sequence of buyToken transfer types
    }
}
