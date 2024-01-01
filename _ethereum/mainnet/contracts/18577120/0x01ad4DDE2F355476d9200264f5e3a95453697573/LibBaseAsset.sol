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

// Local imports - Structs
import "./StorageTypes.sol";

/// @dev Library containing base asset storage with getters and setters
library LibBaseAsset {
    // -----------------------------------------------------------------------
    //                              Constants
    // -----------------------------------------------------------------------

    /// @dev Base asset storage pointer.
    bytes32 internal constant BASE_ASSET_STORAGE_POSITION = keccak256("angelblock.fundraising.baseAsset");

    // -----------------------------------------------------------------------
    //                              Structs
    // -----------------------------------------------------------------------

    /// @dev Base asset storage struct.
    /// @param base Mapping of raise id to base asset struct
    struct BaseAssetStorage {
        mapping(string => StorageTypes.BaseAsset) base;
    }

    // -----------------------------------------------------------------------
    //                              Diamond storage
    // -----------------------------------------------------------------------

    /// @dev Function returning base asset storage at storage pointer slot.
    /// @return bas BaseAssetStorage struct instance at storage pointer position
    function baseAssetStorage() internal pure returns (BaseAssetStorage storage bas) {
        // declare position
        bytes32 position = BASE_ASSET_STORAGE_POSITION;

        // set slot to position
        assembly {
            bas.slot := position
        }

        // explicit return
        return bas;
    }

    // -----------------------------------------------------------------------
    //                              Getters / setters
    // -----------------------------------------------------------------------

    /// @dev Diamond storage getter: Base asset address.
    /// @param _raiseId ID of the raise
    /// @return Address of the base asset
    function getAddress(string memory _raiseId) internal view returns (address) {
        // return
        return baseAssetStorage().base[_raiseId].base;
    }

    /// @dev Diamond storage getter: Base asset chain id.
    /// @param _raiseId ID of the raise
    /// @return Id of the chain
    function getChainId(string memory _raiseId) internal view returns (uint256) {
        // return
        return baseAssetStorage().base[_raiseId].chainId;
    }

    /// @dev Diamond storage setter: Base asset
    /// @param _raiseId ID of the raise
    /// @param _baseAsset StorageTypes.BaseAsset struct
    function setBaseAsset(string memory _raiseId, StorageTypes.BaseAsset memory _baseAsset) internal {
        // set base asset
        baseAssetStorage().base[_raiseId] = _baseAsset;
    }
}
