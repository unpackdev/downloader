// contracts/Structs.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import "./BytesLib.sol";

library ICCOStructs {
    using BytesLib for bytes;

    struct Token {
        uint16 tokenChain;
        bytes32 tokenAddress;
        uint128 conversionRate;
    }

    struct SolanaToken {
        uint8 tokenIndex;
        bytes32 tokenAddress;
    }

    struct Contribution {
        /// index in acceptedTokens array
        uint8 tokenIndex;
        uint256 contributed;
    }

    struct Allocation {
        /// index in acceptedTokens array
        uint8 tokenIndex;
        /// amount of sold tokens allocated to contributors on this chain
        uint256 allocation;
        /// excess contributions refunded to contributors on this chain
        uint256 excessContribution;
    }

    struct Raise {
        /// fixed-price sale boolean
        bool isFixedPrice;
        /// sale token address
        bytes32 token;
        /// sale token chainId
        uint16 tokenChain;
        /// token amount being sold
        uint256 tokenAmount;
        /// min raise amount
        uint256 minRaise;
        /// max token amount
        uint256 maxRaise;
        /// timestamp raise start
        uint256 saleStart;
        /// timestamp raise end
        uint256 saleEnd;
        /// unlock timestamp (when tokens can be claimed)
        uint256 unlockTimestamp;
        /// recipient of proceeds
        address recipient;
        /// refund recipient in cse the sale is aborted
        address refundRecipient;
        /// sale token ATA for Solana
        bytes32 solanaTokenAccount;
        /// public key of kyc authority 
        address authority; 
    }

    struct SaleInit {
        /// payloadID uint8 = 1
        uint8 payloadID;
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
        /// accepted Tokens
        Token[] acceptedTokens;
        /// recipient of proceeds
        bytes32 recipient;
        /// public key of kyc authority 
        address authority;
        /// unlock timestamp (when tokens can be claimed)
        uint256 unlockTimestamp;
    }

    struct SolanaSaleInit {
        /// payloadID uint8 = 5
        uint8 payloadID;
        /// sale ID
        uint256 saleID;
        /// sale token ATA for solana
        bytes32 solanaTokenAccount;
        /// chain ID of the token
        uint16 tokenChain;
        /// token decimals 
        uint8 tokenDecimals;
        /// timestamp raise start
        uint256 saleStart;
        /// timestamp raise end
        uint256 saleEnd;
        /// accepted Tokens
        SolanaToken[] acceptedTokens;  
        /// recipient of proceeds
        bytes32 recipient;
        /// public key of kyc authority 
        address authority;
        /// unlock timestamp (when tokens can be claimed)
        uint256 unlockTimestamp;
    }

    struct ContributionsSealed {
        /// payloadID uint8 = 2
        uint8 payloadID;
        /// sale ID
        uint256 saleID;
        /// chain ID
        uint16 chainID;
        /// sealed contributions for this sale
        Contribution[] contributions;
    }

    struct SaleSealed {
        /// payloadID uint8 = 3
        uint8 payloadID;
        /// sale ID
        uint256 saleID;
        /// allocations
        Allocation[] allocations;
    }

    struct SaleAborted {
        /// payloadID uint8 = 4
        uint8 payloadID;
        /// sale ID
        uint256 saleID;
    }

    function normalizeAmount(uint256 amount, uint8 decimals) public pure returns(uint256){
        if (decimals > 8) {
            amount /= 10 ** (decimals - 8);
        }
        return amount;
    }

    function deNormalizeAmount(uint256 amount, uint8 decimals) public pure returns(uint256){
        if (decimals > 8) {
            amount *= 10 ** (decimals - 8);
        }
        return amount;
    }

    function encodeSaleInit(SaleInit memory saleInit) public pure returns (bytes memory encoded) {
        return abi.encodePacked(
            uint8(1),
            saleInit.saleID,
            saleInit.tokenAddress,
            saleInit.tokenChain,
            saleInit.tokenDecimals,
            saleInit.saleStart,
            saleInit.saleEnd,
            encodeTokens(saleInit.acceptedTokens),
            saleInit.recipient,
            saleInit.authority,
            saleInit.unlockTimestamp
        );
    }

    function encodeSolanaSaleInit(SolanaSaleInit memory solanaSaleInit) public pure returns (bytes memory encoded) {
        return abi.encodePacked(
            uint8(5),
            solanaSaleInit.saleID,
            solanaSaleInit.solanaTokenAccount,
            solanaSaleInit.tokenChain,
            solanaSaleInit.tokenDecimals,
            solanaSaleInit.saleStart,
            solanaSaleInit.saleEnd,
            encodeSolanaTokens(solanaSaleInit.acceptedTokens),
            solanaSaleInit.recipient,
            solanaSaleInit.authority,
            solanaSaleInit.unlockTimestamp
        );
    }

    function parseSaleInit(bytes memory encoded) public pure returns (SaleInit memory saleInit) {
        uint256 index = 0;

        saleInit.payloadID = encoded.toUint8(index);
        index += 1;

        require(saleInit.payloadID == 1, "invalid payloadID");

        saleInit.saleID = encoded.toUint256(index);
        index += 32;

        saleInit.tokenAddress = encoded.toBytes32(index);
        index += 32;

        saleInit.tokenChain = encoded.toUint16(index);
        index += 2;

        saleInit.tokenDecimals = encoded.toUint8(index);
        index += 1;

        saleInit.saleStart = encoded.toUint256(index);
        index += 32;

        saleInit.saleEnd = encoded.toUint256(index);
        index += 32;

        uint256 len = 1 + 50 * uint256(uint8(encoded[index]));
        saleInit.acceptedTokens = parseTokens(encoded.slice(index, len));
        index += len;

        saleInit.recipient = encoded.toBytes32(index);
        index += 32;

        saleInit.authority = encoded.toAddress(index);
        index += 20;

        saleInit.unlockTimestamp = encoded.toUint256(index);
        index += 32;

        require(encoded.length == index, "invalid SaleInit");
    }

    function encodeTokens(Token[] memory tokens) public pure returns (bytes memory encoded) {
        encoded = abi.encodePacked(uint8(tokens.length));
        for (uint256 i = 0; i < tokens.length; i++) {
            encoded = abi.encodePacked(
                encoded,
                tokens[i].tokenAddress,
                tokens[i].tokenChain,
                tokens[i].conversionRate
            );
        }
    }

    function encodeSolanaTokens(SolanaToken[] memory tokens) public pure returns (bytes memory encoded) {
        encoded = abi.encodePacked(uint8(tokens.length));
        for (uint256 i = 0; i < tokens.length; i++) {
            encoded = abi.encodePacked(
                encoded,
                tokens[i].tokenIndex,
                tokens[i].tokenAddress
            );
        }
    }

    function parseTokens(bytes memory encoded) public pure returns (Token[] memory tokens) {
        require(encoded.length % 50 == 1, "invalid Token[]");

        uint8 len = uint8(encoded[0]);

        tokens = new Token[](len);

        for (uint256 i = 0; i < len; i++) {
            tokens[i].tokenAddress   = encoded.toBytes32( 1 + i * 50);
            tokens[i].tokenChain     = encoded.toUint16( 33 + i * 50);
            tokens[i].conversionRate = encoded.toUint128(35 + i * 50);
        }
    }

    function encodeContributionsSealed(ContributionsSealed memory cs) public pure returns (bytes memory encoded) {
        return abi.encodePacked(
            uint8(2),
            cs.saleID,
            cs.chainID,
            encodeContributions(cs.contributions)
        );
    }

    function parseContributionsSealed(bytes memory encoded) public pure returns (ContributionsSealed memory consSealed) {
        uint256 index = 0;

        consSealed.payloadID = encoded.toUint8(index);
        index += 1;

        require(consSealed.payloadID == 2, "invalid payloadID");

        consSealed.saleID = encoded.toUint256(index);
        index += 32;

        consSealed.chainID = encoded.toUint16(index);
        index += 2;

        uint256 len = 1 + 33 * uint256(uint8(encoded[index]));
        consSealed.contributions = parseContributions(encoded.slice(index, len));
        index += len;

        require(encoded.length == index, "invalid ContributionsSealed");
    }

    function encodeContributions(Contribution[] memory contributions) public pure returns (bytes memory encoded) {
        encoded = abi.encodePacked(uint8(contributions.length));
        for (uint256 i = 0; i < contributions.length; i++) {
            encoded = abi.encodePacked(
                encoded,
                contributions[i].tokenIndex,
                contributions[i].contributed
            );
        }
    }

    function parseContributions(bytes memory encoded) public pure returns (Contribution[] memory cons) {
        require(encoded.length % 33 == 1, "invalid Contribution[]");

        uint8 len = uint8(encoded[0]);

        cons = new Contribution[](len);

        for (uint256 i = 0; i < len; i++) {
            cons[i].tokenIndex  = encoded.toUint8(1 + i * 33);
            cons[i].contributed = encoded.toUint256(2 + i * 33);
        }
    }

    function encodeSaleSealed(SaleSealed memory ss) public pure returns (bytes memory encoded) {
        return abi.encodePacked(
            uint8(3),
            ss.saleID,
            encodeAllocations(ss.allocations)
        );
    }

    function parseSaleSealed(bytes memory encoded) public pure returns (SaleSealed memory ss) {
        uint256 index = 0;
        ss.payloadID = encoded.toUint8(index);
        index += 1;

        require(ss.payloadID == 3, "invalid payloadID");

        ss.saleID = encoded.toUint256(index);
        index += 32;

        uint256 len = 1 + 65 * uint256(uint8(encoded[index]));
        ss.allocations = parseAllocations(encoded.slice(index, len));
        index += len;

        require(encoded.length == index, "invalid SaleSealed");
    }

    function encodeAllocations(Allocation[] memory allocations) public pure returns (bytes memory encoded) {
        encoded = abi.encodePacked(uint8(allocations.length));
        for (uint256 i = 0; i < allocations.length; i++) {
            encoded = abi.encodePacked(
                encoded,
                allocations[i].tokenIndex,
                allocations[i].allocation,
                allocations[i].excessContribution
            );
        }
    }

    function parseAllocations(bytes memory encoded) public pure returns (Allocation[] memory allos) {
        require(encoded.length % 65 == 1, "invalid Allocation[]");

        uint8 len = uint8(encoded[0]);

        allos = new Allocation[](len);

        for (uint256 i = 0; i < len; i++) {
            allos[i].tokenIndex = encoded.toUint8(1 + i * 65);
            allos[i].allocation = encoded.toUint256(2 + i * 65);
            allos[i].excessContribution = encoded.toUint256(34 + i * 65);
        }
    }

    function encodeSaleAborted(SaleAborted memory ca) public pure returns (bytes memory encoded) {
        return abi.encodePacked(uint8(4), ca.saleID);
    }

    function parseSaleAborted(bytes memory encoded) public pure returns (SaleAborted memory sa) {
        uint256 index = 0;
        sa.payloadID = encoded.toUint8(index);
        index += 1;

        require(sa.payloadID == 4, "invalid payloadID");

        sa.saleID = encoded.toUint256(index);
        index += 32;

        require(encoded.length == index, "invalid SaleAborted");
    }
}