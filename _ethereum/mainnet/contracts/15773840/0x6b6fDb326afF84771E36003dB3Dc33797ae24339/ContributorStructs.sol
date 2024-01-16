// contracts/Structs.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

contract ContributorStructs {
    struct Sale {
        /// sale ID
        uint256 saleID;
        /// address of the token - left-zero-padded if shorter than 32 bytes
        bytes32 tokenAddress;
        /// chain ID of the token
        uint16 tokenChain;
        /// token decimals
        uint8 tokenDecimals;
        /// timestamp raise start
        uint256 saleStart;
        /// timestamp raise end
        uint256 saleEnd;
        /// unlock timestamp (when tokens can be claimed)
        uint256 unlockTimestamp;        
        /// accepted Tokens
        uint16[] acceptedTokensChains;
        bytes32[] acceptedTokensAddresses;
        uint128[] acceptedTokensConversionRates;

        /// recipient of proceeds
        bytes32 recipient;

        /// KYC authority public key
        address authority;

        bool isSealed;
        bool isAborted;

        uint256[] allocations;
        uint256[] excessContributions;
    }
}
