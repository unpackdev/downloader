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

/// @dev Library containing ERC-20 asset storage with getters and setters
library LibERC20Asset {
    // -----------------------------------------------------------------------
    //                              Constants
    // -----------------------------------------------------------------------

    /// @dev ERC-20 asset storage pointer.
    bytes32 internal constant ERC20_ASSET_STORAGE_POSITION = keccak256("angelblock.fundraising.erc20");

    // -----------------------------------------------------------------------
    //                              Structs
    // -----------------------------------------------------------------------

    /// @dev ERC-20 asset storage struct.
    /// @param erc20 Mapping of raise id to ERC-20 asset struct
    struct ERC20AssetStorage {
        mapping(string => StorageTypes.ERC20Asset) erc20;
    }

    // -----------------------------------------------------------------------
    //                              Diamond storage
    // -----------------------------------------------------------------------

    /// @dev Function returning ERC-20 asset storage at storage pointer slot.
    /// @return eas ERC20AssetStorage struct instance at storage pointer position
    function erc20AssetStorage() internal pure returns (ERC20AssetStorage storage eas) {
        // declare position
        bytes32 position = ERC20_ASSET_STORAGE_POSITION;

        // set slot to position
        assembly {
            eas.slot := position
        }

        // explicit return
        return eas;
    }

    // -----------------------------------------------------------------------
    //                              Getters / setters
    // -----------------------------------------------------------------------

    /// @dev Diamond storage getter: ERC-20 asset address.
    /// @param _raiseId ID of the raise
    /// @return Address of the ERC-20 asset
    function getAddress(string memory _raiseId) internal view returns (address) {
        return erc20AssetStorage().erc20[_raiseId].erc20;
    }

    /// @dev Diamond storage getter: ERC-20 asset chain id.
    /// @param _raiseId ID of the raise
    /// @return Id of the chain
    function getChainId(string memory _raiseId) internal view returns (uint256) {
        // return
        return erc20AssetStorage().erc20[_raiseId].chainId;
    }

    /// @dev Diamond storage getter: ERC-20 asset vested amount.
    /// @param _raiseId ID of the raise
    /// @return Amount of vested ERC-20 tokens
    function getAmount(string memory _raiseId) internal view returns (uint256) {
        return erc20AssetStorage().erc20[_raiseId].amount;
    }

    /// @dev Diamond storage setter: ERC-20 asset
    /// @param _raiseId ID of the raise
    /// @param _erc20Asset StorageTypes.ERC20Asset struct
    function setERC20Asset(string memory _raiseId, StorageTypes.ERC20Asset memory _erc20Asset) internal {
        erc20AssetStorage().erc20[_raiseId] = _erc20Asset;
    }

    /// @dev Diamond storage setter: ERC-20 asset address.
    /// @param _raiseId ID of the raise
    /// @param _erc20 Address of the ERC-20 asset
    function setERC20Address(string memory _raiseId, address _erc20) internal {
        erc20AssetStorage().erc20[_raiseId].erc20 = _erc20;
    }
}
