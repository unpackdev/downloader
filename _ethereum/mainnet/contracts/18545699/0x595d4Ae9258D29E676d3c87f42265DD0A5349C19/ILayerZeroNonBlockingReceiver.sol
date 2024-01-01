// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

interface ILayerZeroNonBlockingReceiver {
    // bridge event
    event MessageFailed(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes _payload, bytes _reason);
    event RetryMessageSuccess(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes32 _payloadHash);
    event RevokeMessageSuccess(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes32 _payloadHash);

    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _lzSrcId - the source endpoint identifier
    // @param _pathData - encodePacked(srcAddr,dstAddr)
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _lzSrcId, bytes calldata _pathData, uint64 _nonce, bytes calldata _payload) external;

    /// @notice can try message if it is nonblocking lzapp
    function retryMessage(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) external;
}
