// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IQuote {
    enum RFQType {
        RFQT,
        RFQM
    }

    struct Quote {
        RFQType rfqType;
        address pool;
        address eoa;
        address trader;
        address effectiveTrader;
        address baseToken;
        address quoteToken;
        uint256 effectiveBaseTokenAmount;
        uint256 maxBaseTokenAmount;
        uint256 maxQuoteTokenAmount;
        uint256 fees;
        uint256 quoteExpiry;
        uint256 nonce;
        bytes32 txid;
        bytes signedQuote;
    }

    struct LzQuote {
        RFQType rfqType;
        uint16 srcChainId;
        uint16 dstChainId;
        address srcPool;
        address dstPool;
        address trader;
        address baseToken;
        address quoteToken;
        uint256 baseTokenAmount;
        uint256 quoteTokenAmount;
        uint256 fees;
        uint256 quoteExpiry;
        bytes32 txid;
        bytes signedQuote;
    }

    struct Deposit {
        address pool;
        address token;
        uint256 amount;
        uint256 nonce;
        bytes signedDeposit;
    }

    function tradeSingleHop(
        Quote calldata quote
    ) external payable;
}
