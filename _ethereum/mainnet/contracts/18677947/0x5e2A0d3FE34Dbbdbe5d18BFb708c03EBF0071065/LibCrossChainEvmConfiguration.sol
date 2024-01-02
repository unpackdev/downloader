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

/// @notice Library containing cross-chain EVM configuration
library LibCrossChainEvmConfiguration {
    // -----------------------------------------------------------------------
    //                              Constants
    // -----------------------------------------------------------------------

    /// @dev Cross-chain EVM configuration storage pointer.
    bytes32 internal constant CC_EVM_CONFIG_STORAGE_POSITION = keccak256("angelblock.cc.evm.config");

    // -----------------------------------------------------------------------
    //                              Structs
    // -----------------------------------------------------------------------

    /// @dev Cross-chain EVM configuration storage struct.
    /// @param fundraisings Mapping of native chain id to fundraising address on the given chain
    /// @param supportedFunctions Mapping of native chain id to supported 4 byte signature of function
    struct EvmConfigurationStorage {
        mapping(uint256 => address) fundraisings;
        mapping(uint256 => mapping(bytes4 => bool)) supportedFunctions;
    }

    // -----------------------------------------------------------------------
    //                              Diamond storage
    // -----------------------------------------------------------------------

    /// @dev Function returning cross-chain evm configuration storage at storage pointer slot.
    /// @return ecs EvmConfigurationStorage struct instance at storage pointer position
    function evmConfigurationStorage() internal pure returns (EvmConfigurationStorage storage ecs) {
        // declare position
        bytes32 position = CC_EVM_CONFIG_STORAGE_POSITION;

        // set slot to position
        assembly {
            ecs.slot := position
        }

        // explicit return
        return ecs;
    }

    // -----------------------------------------------------------------------
    //                              Getters
    // -----------------------------------------------------------------------

    /// @dev Diamond storage getter: Fundraising address.
    /// @param _nativeChainId ID of the chain
    /// @return Address of the fundraising
    function getFundraising(uint256 _nativeChainId) internal view returns (address) {
        // return
        return evmConfigurationStorage().fundraisings[_nativeChainId];
    }

    /// @dev Diamond storage getter: Supported function.
    /// @param _nativeChainId ID of the chain
    /// @param _supportedFunctionSelector Selector of function
    /// @return True if function is supported
    function getSupportedFunction(uint256 _nativeChainId, bytes4 _supportedFunctionSelector) internal view returns (bool) {
        // return
        return evmConfigurationStorage().supportedFunctions[_nativeChainId][_supportedFunctionSelector];
    }

    // -----------------------------------------------------------------------
    //                              Setters
    // -----------------------------------------------------------------------

    /// @dev Diamond storage setter: Fundraising address.
    /// @param _nativeChainId ID of the chain
    /// @param _fundraising Address of the fundraising
    function setFundraising(uint256 _nativeChainId, address _fundraising) internal {
        // set fundraising
        evmConfigurationStorage().fundraisings[_nativeChainId] = _fundraising;
    }

    /// @dev Diamond storage setter: Supported function.
    /// @param _nativeChainId ID of the chain
    /// @param _supportedFunctionSelector Selector of function
    /// @param _isSupported Boolean if function is supported
    function setSupportedFunction(uint256 _nativeChainId, bytes4 _supportedFunctionSelector, bool _isSupported) internal {
        // set supported function
        evmConfigurationStorage().supportedFunctions[_nativeChainId][_supportedFunctionSelector] = _isSupported;
    }
}
