// SPDX-License-Identifier: LZBL-1.1
// Copyright 2023 LayerZero Labs Ltd.
// You may obtain a copy of the License at
// https://github.com/LayerZero-Labs/license/blob/main/LICENSE-LZBL-1.1

pragma solidity 0.8.19;

import "./SafeCast.sol";
import "./IOFT.sol";
import "./PreCrimeV2Simulator.sol";
import "./IUSDV.sol";
import "./IUSDVMain.sol";
import "./Messaging.sol";
import "./NonblockingLzApp.sol";
import "./MsgCodec.sol";

contract MessagingV1 is NonblockingLzApp, Messaging, PreCrimeV2Simulator {
    using BytesLib for bytes;
    using MsgCodec for bytes;
    using SafeCast for uint32;

    constructor(
        address _endpoint,
        address _usdv,
        uint32 _mainChainEid,
        bool _isMainChain
    ) Messaging(_usdv, _mainChainEid, _isMainChain) NonblockingLzApp(_endpoint) {}

    // ======================== onlyUSDV ========================
    function send(
        SendParam calldata _param,
        bytes calldata _extraOptions,
        MessagingFee calldata /* _msgFee */,
        address payable _refundAddress,
        bytes calldata _composeMsg
    ) external payable onlyUSDV returns (MessagingReceipt memory msgReceipt) {
        require(_composeMsg.length == 0, "MessagingV1: composeMsg not supported");
        uint16 dstEid = _param.dstEid.toUint16();
        _checkGasLimit(dstEid, MsgCodec.MSG_TYPE_SEND, _extraOptions, 0);
        _lzSend(
            dstEid,
            MsgCodec.encodeSendMsg(_param.to, _param.color, _param.amount, _param.theta),
            _refundAddress,
            address(0x0),
            _extraOptions,
            msg.value
        );

        return msgReceipt;
    }

    /// @dev gas provided to sync linearly increases with num deltas
    function syncDelta(
        uint32 _dstEid,
        Delta[] calldata _deltas,
        bytes calldata _extraOptions,
        MessagingFee calldata /* _msgFee */,
        address payable _refundAddress
    ) external payable onlyUSDV returns (MessagingReceipt memory msgReceipt) {
        uint16 dstEid = _dstEid.toUint16();
        _checkGasLimit(
            dstEid,
            MsgCodec.MSG_TYPE_SYNC_DELTA,
            _extraOptions,
            perColorExtraGasLookup[_dstEid][MsgCodec.MSG_TYPE_SYNC_DELTA] * _deltas.length
        );
        _lzSend(dstEid, MsgCodec.encodeSyncDeltaMsg(_deltas), _refundAddress, address(0x0), _extraOptions, msg.value);
        return msgReceipt;
    }

    /// @dev gas provided to remint linearly increases with num deltas
    function remint(
        Delta[] calldata _deltas,
        uint32 _feeColor,
        uint64 _feeAmount,
        uint64 _feeTheta,
        bytes calldata _extraOptions,
        MessagingFee calldata /* _msgFee */,
        address payable _refundAddress
    ) external payable onlyUSDV returns (MessagingReceipt memory msgReceipt) {
        uint16 dstEid = mainChainEid.toUint16();
        _checkGasLimit(
            dstEid,
            MsgCodec.MSG_TYPE_REMINT,
            _extraOptions,
            perColorExtraGasLookup[mainChainEid][MsgCodec.MSG_TYPE_REMINT] * _deltas.length
        );
        _lzSend(
            dstEid,
            MsgCodec.encodeRemintMsg(_deltas, _feeColor, _feeAmount, _feeTheta),
            _refundAddress,
            address(0x0),
            _extraOptions,
            msg.value
        );
        return msgReceipt;
    }

    // ======================== View ========================
    function quoteSendFee(
        uint32 _dstEid,
        bytes calldata _extraOptions,
        bool /*_useLZToken*/,
        bytes calldata _composeMsg
    ) external view returns (uint nativeFee, uint lzTokenFee) {
        require(_composeMsg.length == 0, "MessagingV1: composeMsg not supported");
        uint16 dstEid = _dstEid.toUint16();
        _checkGasLimit(dstEid, MsgCodec.MSG_TYPE_SEND, _extraOptions, 0);
        return
            lzEndpoint.estimateFees(dstEid, address(this), MsgCodec.encodeSendMsg(0x0, 0, 0, 0), false, _extraOptions);
    }

    function quoteSyncDeltaFee(
        uint32 _dstEid,
        Delta[] calldata _deltas,
        bytes calldata _extraOptions,
        bool /*_useLZToken*/
    ) external view returns (uint nativeFee, uint lzTokenFee) {
        uint16 dstEid = _dstEid.toUint16();
        _checkGasLimit(
            dstEid,
            MsgCodec.MSG_TYPE_SYNC_DELTA,
            _extraOptions,
            perColorExtraGasLookup[_dstEid][MsgCodec.MSG_TYPE_SYNC_DELTA] * _deltas.length
        );
        return
            lzEndpoint.estimateFees(dstEid, address(this), MsgCodec.encodeSyncDeltaMsg(_deltas), false, _extraOptions);
    }

    function quoteRemintFee(
        Delta[] calldata _deltas,
        bytes calldata _extraOptions,
        bool /*_useLZToken*/
    ) external view returns (uint nativeFee, uint lzTokenFee) {
        uint16 dstEid = mainChainEid.toUint16();
        _checkGasLimit(
            dstEid,
            MsgCodec.MSG_TYPE_REMINT,
            _extraOptions,
            perColorExtraGasLookup[mainChainEid][MsgCodec.MSG_TYPE_REMINT] * _deltas.length
        );
        return
            lzEndpoint.estimateFees(
                dstEid,
                address(this),
                MsgCodec.encodeRemintMsg(_deltas, 0, 0, 0),
                false,
                _extraOptions
            );
    }

    function isPeer(uint32 _eid, bytes32 _peer) public view override returns (bool) {
        bytes memory path = trustedRemoteLookup[_eid.toUint16()];
        uint pathLength = path.length;
        require(pathLength > 20 && pathLength <= 52, "MessagingV1: invalid path length");

        bytes32 expectedPeer = bytes32(path.slice(0, pathLength - 20));
        unchecked {
            uint offset = 52 - path.length;
            expectedPeer = expectedPeer >> (offset * 8);
        }

        return expectedPeer == _peer;
    }

    // ======================== Internal ========================

    function _nonblockingLzReceive(
        uint16 /*_srcChainId*/,
        bytes calldata /*_srcAddress*/,
        uint64 /*_nonce*/,
        bytes calldata _message
    ) internal override {
        uint8 msgType = _message.msgType();

        if (msgType == MsgCodec.MSG_TYPE_SEND) {
            SendMsg memory message = _message.decodeSendMsg();
            IUSDV(usdv).sendAck(0x0, message.to, message.color, message.amount, message.theta);
        } else if (msgType == MsgCodec.MSG_TYPE_SYNC_DELTA) {
            SyncDeltaMsg memory message = _message.decodeSyncDeltaMsg();
            IUSDV(usdv).syncDeltaAck(message.deltas);
        } else if (msgType == MsgCodec.MSG_TYPE_REMINT) {
            if (!isMainChain) revert NotMainChain();
            RemintMsg memory message = _message.decodeRemintMsg();
            IUSDVMain(usdv).remintAck(message.deltas, message.color, message.amount, message.theta);
        } else {
            revert NotImplemented();
        }
    }

    // ======================== precrime ========================

    function _lzReceive(Origin calldata /*_origin*/, bytes32 /*_guid*/, bytes calldata _message) internal override {
        // only pass in the message
        this.nonblockingLzReceive(0x0, bytes(""), 0, _message);
    }
}
