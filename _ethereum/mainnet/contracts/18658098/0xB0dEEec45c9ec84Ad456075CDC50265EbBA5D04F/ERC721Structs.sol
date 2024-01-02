// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IERC20.sol";

struct CreateParams {
    string name;
    string symbol;
    string uri;
    string tokensURI;
    uint24 maxSupply;
    bool isZeroIndexed;
    uint24 royaltyAmount;
    uint256 endTime;
    bool isEdition;
    bool isSBT;
    uint256 premintQuantity;
}

struct MintParams {
    address to;
    address collection;
    uint24 quantity;
    bytes32[] merkleProof;
    uint8 phaseId;
    bytes payloadForCall;
}

struct OmnichainMintParams {
    address collection;
    uint24 quantity;
    uint256 paid;
    uint8 phaseId;
    address minter;
}

struct Phase {
    uint256 from;
    uint256 to;
    uint24 maxPerAddress;
    uint256 price;
    bytes32 merkleRoot;
    address token;
    uint256 minToken;
}

    struct BasicCollectionParams {
        uint tokenId;
        string name;
        string symbol;
        string uri;
        string tokenURI;
        address owner;
    }

    struct LzParams {
        uint16 dstChainId;
        address zroPaymentAddress;
        bytes adapterParams;
        address payable refundAddress;
    }

    struct SendParams {
        bytes toAddress;
        address sender;
        address from;
        bytes payloadForCall;
    }

    struct EncodedSendParams {
        bytes toAddress;
        bytes sender;
        bytes from;
        bytes payloadForCall;
    }
