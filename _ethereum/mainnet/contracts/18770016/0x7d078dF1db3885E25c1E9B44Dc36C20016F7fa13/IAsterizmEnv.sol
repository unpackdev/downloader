// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IAsterizmEnv {

    /// Base transfer direction DTO
    /// @param srcChainId uint64  Source chain ID
    /// @param srcAddress uint  Source address
    /// @param dstChainId uint64  Destination chain ID
    /// @param dstAddress uint  Destination address
    struct BaseTransferDirectionDto {
        uint64 srcChainId;
        uint srcAddress;
        uint64 dstChainId;
        uint dstAddress;
    }

    /// Client initiation transfer request DTO
    /// @param dstChainId uint64  Destination chain ID
    /// @param dstAddress uint  Destination address
    /// @param feeAmount uint  Fee amount
    /// @param txId uint  Transaction ID
    /// @param transferHash bytes32  Transfer hash
    /// @param payload bytes  Payload
    struct ClInitTransferRequestDto {
        uint64 dstChainId;
        uint dstAddress;
        uint feeAmount;
        uint txId;
        bytes32 transferHash;
    }

    /// Internal client initiation transfer request DTO
    /// @param dstChainId uint64  Destination chain ID
    /// @param dstAddress uint  Destination address
    /// @param feeAmount uint  Fee amount
    /// @param txId uint  Transaction ID
    /// @param transferHash bytes32  Transfer hash
    /// @param payload bytes  Payload
    struct InternalClInitTransferRequestDto {
        uint64 dstChainId;
        uint dstAddress;
        uint feeAmount;
        bytes payload;
    }

    /// Initializer asterizm receive request DTO
    /// @param srcChainId uint64  Source chain ID
    /// @param srcAddress uint  Source address
    /// @param dstChainId uint64  Destination chain ID
    /// @param dstAddress uint  Destination address
    /// @param nonce uint  Nonce
    /// @param txId uint  Transaction ID
    /// @param transferHash bytes32  Transfer hash
    struct IzAsterizmReceiveRequestDto {
        uint64 srcChainId;
        uint srcAddress;
        uint64 dstChainId;
        uint dstAddress;
        uint txId;
        bytes32 transferHash;
    }

    /// Client asterizm receive request DTO
    /// @param srcChainId uint64  Source chain ID
    /// @param srcAddress uint  Source address
    /// @param dstChainId uint64  Destination chain ID
    /// @param dstAddress uint  Destination address
    /// @param txId uint  Transaction ID
    /// @param transferHash bytes32  Transfer hash
    /// @param payload bytes  Transfer payload
    struct ClAsterizmReceiveRequestDto {
        uint64 srcChainId;
        uint srcAddress;
        uint64 dstChainId;
        uint dstAddress;
        uint txId;
        bytes32 transferHash;
        bytes payload;
    }

    /// Translator send message request DTO
    /// @param srcAddress uint  Source address
    /// @param dstChainId uint64  Destination chain ID
    /// @param dstAddress uint  Destination address
    /// @param txId uint  Transaction ID
    /// @param transferHash bytes32  Transfer hash
    /// @param transferResultNotifyFlag bool  Transfer result notification flag
    struct TrSendMessageRequestDto {
        uint srcAddress;
        uint64 dstChainId;
        uint dstAddress;
        uint txId;
        bytes32 transferHash;
        bool transferResultNotifyFlag;
    }

    /// Translator transfer message request DTO
    /// @param gasLimit uint  Gas limit
    /// @param payload bytes  Payload
    struct TrTransferMessageRequestDto {
        uint gasLimit;
        bytes payload;
    }

    /// Initializator initiate transfer request DTO
    /// @param dstChainId uint64  Destination chain ID
    /// @param dstAddress uint  Destination address
    /// @param transferHash bytes32  Transfer hash
    /// @param txId uint  Transaction ID
    /// @param relay address  Relay address
    /// @param transferResultNotifyFlag bool  Transfer result notification flag
    /// @param feeToken address  Token address for paying relay fee (Chainlink for example)
    struct IzInitTransferRequestDto {
        uint64 dstChainId;
        uint dstAddress;
        bytes32 transferHash;
        uint txId;
        address relay;
        bool transferResultNotifyFlag;
        address feeToken;
    }

    /// Initializator receive payload request DTO
    /// @param srcChainId uint64  Source chain ID
    /// @param srcAddress uint  Source address
    /// @param dstChainId uint64  Destination chain ID
    /// @param dstAddress uint  Destination address
    /// @param gasLimit uint  Gas limit
    /// @param txId uint  Transaction ID
    /// @param transferHash bytes32  Transfer hash
    struct IzReceivePayloadRequestDto {
        uint64 srcChainId;
        uint srcAddress;
        uint64 dstChainId;
        uint dstAddress;
        uint gasLimit;
        uint txId;
        bytes32 transferHash;
    }

    /// Initializator retry payload request DTO
    /// @param srcChainId uint64  Source chain ID
    /// @param srcAddress uint  Source address
    /// @param dstChainId uint64  Destination chain ID
    /// @param dstAddress uint  Destination address
    /// @param nonce uint  Nonce
    /// @param gasLimit uint  Gas limit
    /// @param forceOrder bool  Force order flag
    /// @param isEncrypted bool  User encryption flag
    /// @param transferHash bytes32  Transfer hash
    /// @param payload bytes  Payload
    struct IzRetryPayloadRequestDto {
        uint64 srcChainId;
        uint srcAddress;
        uint64 dstChainId;
        uint dstAddress;
        uint nonce;
        uint gasLimit;
        bool forceOrder;
        bool useEncryption;
        bytes32 transferHash;
        bytes payload;
    }
}
