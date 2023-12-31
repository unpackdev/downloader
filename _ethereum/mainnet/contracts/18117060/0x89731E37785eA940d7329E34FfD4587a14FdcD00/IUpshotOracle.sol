// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

// ***************************************************************
// * ========================= STRUCTS ========================= *
// ***************************************************************
struct PriceData { 
    bytes signature;
    uint256 nonce;
    address nft; 
    uint96 timestamp;
    address token; 
    uint96 expiration;
    uint256 nftId;
    uint256 price; 
    bytes extraData;
}

/**
 * @title Upshot Oracle Interface
 */
interface IUpshotOracle {
    // ***************************************************************
    // * ========================= EVENTS ========================== *
    // ***************************************************************
    event UpshotOracleAdminSetAuthenticator(address authenticator);

    // ***************************************************************
    // * ========================= ERRORS ========================== *
    // ***************************************************************
    error UpshotOracleInvalidPriceTime();
    error UpshotOracleInvalidSigner();

    // ***************************************************************
    // * ========================== VIEW =========================== *
    // ***************************************************************

    /**
     * @notice Get the address of the authenticator
     */
    function authenticator() external view returns (address);

    /**
     * @notice Decode the token prices from the encoded upshot price data
     */
    function decodeTokenPrices(
        PriceData[] calldata priceData
    ) external returns (uint256[] memory tokenPrices);
}
