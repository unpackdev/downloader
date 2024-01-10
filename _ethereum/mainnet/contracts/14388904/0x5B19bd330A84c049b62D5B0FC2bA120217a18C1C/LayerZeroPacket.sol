// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "./SafeMath.sol";
import "./Buffer.sol";

library LayerZeroPacket {
    using Buffer for Buffer.buffer;
    using SafeMath for uint;

    //---------------------------------------------------------------------------
    // packet
    struct Packet {
        uint16 srcChainId;
        uint16 dstChainId;
        uint64 nonce;
        address dstAddress;
        bytes srcAddress;
        bytes32 ulnAddress;
        bytes payload;
    }

    function getPacket(bytes memory data, uint16 srcChain, uint sizeOfSrcAddress, bytes32 ulnAddress) internal pure returns (Packet memory) {
        uint16 dstChainId;
        address dstAddress;
        uint size;
        uint64 nonce;

        // The log consists of the destination chain id and then a bytes payload
        //      0--------------------------------------------31
        // 0   |  destination chain id
        // 32  |  defines bytes array
        // 64  |
        // 96  |  bytes array size
        // 128 |  payload
        assembly {
            dstChainId := mload(add(data, 32))
            size := mload(add(data, 96)) /// size of the byte array
            nonce := mload(add(data, 104)) // offset to convert to uint64  128  is index -24
            dstAddress := mload(add(data, sub(add(128, sizeOfSrcAddress), 4))) // offset to convert to address 12 -8
        }

        Buffer.buffer memory srcAddressBuffer;
        srcAddressBuffer.init(sizeOfSrcAddress);
        srcAddressBuffer.writeRawBytes(0, data, 136, sizeOfSrcAddress); // 128 + 8

        uint payloadSize = size.sub(20).sub(sizeOfSrcAddress);
        Buffer.buffer memory payloadBuffer;
        payloadBuffer.init(payloadSize);
        payloadBuffer.writeRawBytes(0, data, sizeOfSrcAddress.add(156), payloadSize); // 148 + 8
        return Packet(srcChain, dstChainId, nonce, address(dstAddress), srcAddressBuffer.buf, ulnAddress, payloadBuffer.buf);
    }
}
