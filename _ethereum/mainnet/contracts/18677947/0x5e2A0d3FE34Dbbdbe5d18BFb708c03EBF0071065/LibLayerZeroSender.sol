// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/**************************************

    security-contact:
    - security@angelblock.io

    maintainers:
    - marcin@angelblock.io
    - piotr@angelblock.io
    - mikolaj@angelblock.io
    - sebastian@angelblock.io

    contributors:
    - domenico@angelblock.io

**************************************/

/// @notice Library containing necessary information for sending messages via LayerZero
library LibLayerZeroSender {
    // -----------------------------------------------------------------------
    //                              Storage pointer
    // -----------------------------------------------------------------------

    bytes32 internal constant LZ_SENDER_STORAGE_POSITION = keccak256("angelblock.cc.lz.sender");

    // -----------------------------------------------------------------------
    //                              Structs
    // -----------------------------------------------------------------------

    struct LayerZeroSenderStorage {
        address refundAddress;
        mapping(uint256 => uint16) networks;
    }

    // -----------------------------------------------------------------------
    //                              Storage
    // -----------------------------------------------------------------------

    // diamond storage getter
    function lzSenderStorage() internal pure returns (LayerZeroSenderStorage storage lzs) {
        // declare position
        bytes32 position = LZ_SENDER_STORAGE_POSITION;

        // set slot to position
        assembly {
            lzs.slot := position
        }

        // explicit return
        return lzs;
    }

    // -----------------------------------------------------------------------
    //                              Getters / setters
    // -----------------------------------------------------------------------

    function getRefundAddress() internal view returns (address) {
        return lzSenderStorage().refundAddress;
    }

    function getNetwork(uint256 _nativeChainId) internal view returns (uint16) {
        return lzSenderStorage().networks[_nativeChainId];
    }

    function setRefundAddress(address _refundAddress) internal {
        lzSenderStorage().refundAddress = _refundAddress;
    }

    function setNetwork(uint256 _nativeChainId, uint16 _layerZeroChainId) internal {
        lzSenderStorage().networks[_nativeChainId] = _layerZeroChainId;
    }
}
