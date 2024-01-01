// SPDX-License-Identifier: LZBL-1.1
// Copyright 2023 LayerZero Labs Ltd.
// You may obtain a copy of the License at
// https://github.com/LayerZero-Labs/license/blob/main/LICENSE-LZBL-1.1

pragma solidity ^0.8.0;

import "./IUSDV.sol";
import "./Buffer.sol";

struct SendMsg {
    address to;
    uint32 color;
    uint64 amount;
    uint64 theta;
}

struct SendAndCallMsg {
    address to;
    uint32 color;
    uint64 amount;
    uint64 theta;
    bytes composeMsg;
}

struct SyncDeltaMsg {
    Delta[] deltas;
}

struct RemintMsg {
    Delta[] deltas;
    uint32 color;
    uint64 amount;
    uint64 theta;
}

library MsgCodec {
    using Buffer for Buffer.buffer;

    // message types
    uint8 internal constant MSG_TYPE_SEND = 1;
    uint8 internal constant MSG_TYPE_SEND_AND_CALL = 2;
    uint8 internal constant MSG_TYPE_SYNC_DELTA = 3;
    uint8 internal constant MSG_TYPE_REMINT = 4;

    // offsets
    uint8 internal constant MSG_TYPE_OFFSET = 0;

    // send / send and call
    uint8 internal constant TO_OFFSET = 1;
    uint8 internal constant COLOR_OFFSET = 33;
    uint8 internal constant AMOUNT_OFFSET = 37;
    uint8 internal constant THETA_OFFSET = 45;
    // send and call
    uint8 internal constant COMPOSED_MSG_OFFSET = 53;

    // sync delta
    uint8 internal constant SYNC_DELTAS_OFFSET = 1;

    // remint
    uint8 internal constant REMINT_COLOR_OFFSET = 1;
    uint8 internal constant REMINT_AMOUNT_OFFSET = 5;
    uint8 internal constant REMINT_THETA_OFFSET = 13;
    uint8 internal constant REMINT_DELTAS_OFFSET = 21;

    error InvalidSize();

    function encodeSendMsg(
        bytes32 _to,
        uint32 _color,
        uint64 _amount,
        uint64 _theta
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(MSG_TYPE_SEND, _to, _color, _amount, _theta);
    }

    function decodeSendMsg(bytes calldata _message) internal pure returns (SendMsg memory) {
        if (_message.length != 53) revert InvalidSize();
        return
            SendMsg({
                to: toAddressB20(bytes32(_message[TO_OFFSET:COLOR_OFFSET])),
                color: uint32(bytes4(_message[COLOR_OFFSET:AMOUNT_OFFSET])),
                amount: uint64(bytes8(_message[AMOUNT_OFFSET:THETA_OFFSET])),
                theta: uint64(bytes8(_message[THETA_OFFSET:53]))
            });
    }

    function encodeSendAndCallMsg(
        bytes32 _to,
        uint32 _color,
        uint64 _amount,
        uint64 _theta,
        address _caller, // OFTComposeMsgCodec expects compose msg to include caller/composeFrom
        bytes memory _composeMsg // extra data
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                MSG_TYPE_SEND_AND_CALL,
                _to,
                _color,
                _amount,
                _theta,
                addressToBytes32(_caller),
                _composeMsg
            );
    }

    function decodeSendAndCallMsg(bytes calldata _message) internal pure returns (SendAndCallMsg memory) {
        if (_message.length < 53) revert InvalidSize();
        return
            SendAndCallMsg({
                to: toAddressB20(bytes32(_message[TO_OFFSET:COLOR_OFFSET])),
                color: uint32(bytes4(_message[COLOR_OFFSET:AMOUNT_OFFSET])),
                amount: uint64(bytes8(_message[AMOUNT_OFFSET:THETA_OFFSET])),
                theta: uint64(bytes8(_message[THETA_OFFSET:COMPOSED_MSG_OFFSET])),
                composeMsg: _message[COMPOSED_MSG_OFFSET:]
            });
    }

    function encodeSyncDeltaMsg(Delta[] calldata _deltas) internal pure returns (bytes memory) {
        Buffer.buffer memory buf;
        buf.init(_deltas.length * 12 + 1);
        buf.appendUint8(MSG_TYPE_SYNC_DELTA);
        for (uint i = 0; i < _deltas.length; i++) {
            Delta calldata delta = _deltas[i];
            buf.appendInt(delta.color, 4);
            buf.appendInt(uint64(delta.amount), 8);
        }
        return buf.buf;
    }

    function decodeSyncDeltaMsg(bytes calldata _message) internal pure returns (SyncDeltaMsg memory) {
        if ((_message.length - SYNC_DELTAS_OFFSET) % 12 != 0) revert InvalidSize();
        uint size = (_message.length - SYNC_DELTAS_OFFSET) / 12;
        Delta[] memory deltas = new Delta[](size);
        for (uint i = 0; i < size; i++) {
            uint offset = SYNC_DELTAS_OFFSET + i * 12;
            deltas[i] = Delta({
                color: uint32(bytes4(_message[offset:offset + 4])),
                amount: int64(uint64(bytes8(_message[offset + 4:offset + 12])))
            });
        }
        return SyncDeltaMsg({deltas: deltas});
    }

    function encodeRemintMsg(
        Delta[] calldata _deltas,
        uint32 _color,
        uint64 _amount,
        uint64 _theta
    ) internal pure returns (bytes memory) {
        Buffer.buffer memory buf;
        buf.init(_deltas.length * 12 + 21); // 1 + 4 + 8 + 8
        buf.appendUint8(MSG_TYPE_REMINT);
        buf.appendInt(_color, 4);
        buf.appendInt(_amount, 8);
        buf.appendInt(_theta, 8);
        for (uint i = 0; i < _deltas.length; i++) {
            Delta calldata delta = _deltas[i];
            buf.appendInt(delta.color, 4);
            buf.appendInt(uint64(delta.amount), 8);
        }
        return buf.buf;
    }

    function decodeRemintMsg(bytes calldata _message) internal pure returns (RemintMsg memory) {
        if ((_message.length - REMINT_DELTAS_OFFSET) % 12 != 0) revert InvalidSize();
        uint size = (_message.length - REMINT_DELTAS_OFFSET) / 12;
        Delta[] memory deltas = new Delta[](size);
        for (uint i = 0; i < size; i++) {
            uint offset = REMINT_DELTAS_OFFSET + i * 12;
            deltas[i] = Delta({
                color: uint32(bytes4(_message[offset:offset + 4])),
                amount: int64(uint64(bytes8(_message[offset + 4:offset + 12])))
            });
        }
        return
            RemintMsg({
                color: uint32(bytes4(_message[REMINT_COLOR_OFFSET:REMINT_AMOUNT_OFFSET])),
                amount: uint64(bytes8(_message[REMINT_AMOUNT_OFFSET:REMINT_THETA_OFFSET])),
                theta: uint64(bytes8(_message[REMINT_THETA_OFFSET:REMINT_DELTAS_OFFSET])),
                deltas: deltas
            });
    }

    function msgType(bytes calldata _message) internal pure returns (uint8) {
        return uint8(bytes1(_message[MSG_TYPE_OFFSET:1]));
    }

    function toAddressB20(bytes32 _addr) internal pure returns (address) {
        return bytes32ToAddress(_addr);
    }

    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    function bytes32ToAddress(bytes32 _b) internal pure returns (address) {
        return address(uint160(uint256(_b)));
    }
}
