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

/// @notice Library containing investor funds info storage with getters and setters.
library LibLayerZeroBase {
    // -----------------------------------------------------------------------
    //                              Constants
    // -----------------------------------------------------------------------

    /// @dev LayerZero base storage pointer.
    bytes32 internal constant CROSS_CHAIN_LAYER_ZERO_BASE_STORAGE_POSITION = keccak256("angelblock.cc.lz.base");

    // -----------------------------------------------------------------------
    //                              Structs
    // -----------------------------------------------------------------------

    /// @dev LayerZero base storage struct.
    /// @param crossChainEndpoint LayerZero endpoint address
    struct LayerZeroBaseStorage {
        address crossChainEndpoint;
    }

    // -----------------------------------------------------------------------
    //                              Diamond storage
    // -----------------------------------------------------------------------

    /// @dev Function returning LayerZero base storage at storage pointer slot.
    /// @return lzbs LayerZeroBaseStorage struct instance at storage pointer position
    function layerZeroBaseStorage() internal pure returns (LayerZeroBaseStorage storage lzbs) {
        // declare position
        bytes32 position = CROSS_CHAIN_LAYER_ZERO_BASE_STORAGE_POSITION;

        // set slot to position
        assembly {
            lzbs.slot := position
        }

        // explicit return
        return lzbs;
    }

    // -----------------------------------------------------------------------
    //                              Getters / setters
    // -----------------------------------------------------------------------

    /// @dev Diamond storage getter: LayerZero endpoint.
    /// @return LayerZero endpoint address
    function getCrossChainEndpoint() internal view returns (address) {
        return layerZeroBaseStorage().crossChainEndpoint;
    }

    /// @dev Diamond storage setter: LayerZero endpoint.
    /// @param _crossChainEndpoint LayerZero endpoint address
    function setCrossChainEndpoint(address _crossChainEndpoint) internal {
        layerZeroBaseStorage().crossChainEndpoint = _crossChainEndpoint;
    }
}
