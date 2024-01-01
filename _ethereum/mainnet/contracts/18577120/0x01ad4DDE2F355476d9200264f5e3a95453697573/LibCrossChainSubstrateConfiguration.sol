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

/// @notice Library containing cross-chain Substrate configuration
library LibCrossChainSubstrateConfiguration {
    // -----------------------------------------------------------------------
    //                              Constants
    // -----------------------------------------------------------------------

    /// @dev Cross-chain Substrate configuration storage pointer.
    bytes32 internal constant CC_SUBSTRATE_CONFIG_STORAGE_POSITION = keccak256("angelblock.cc.substrate.config");

    // -----------------------------------------------------------------------
    //                              Structs
    // -----------------------------------------------------------------------

    /// @dev Cross-chain EVM configuration storage struct.
    /// @param fundraisings Mapping of native chain id to fundraising address on the given chain
    /// @param supportedFunctions Mapping of native chain id to supported function selector
    struct SubstrateConfigurationStorage {
        mapping(uint256 => bytes) fundraisings;
        mapping(uint256 => mapping(bytes4 => bool)) supportedFunctions;
    }

    // -----------------------------------------------------------------------
    //                              Diamond storage
    // -----------------------------------------------------------------------

    /// @dev Function returning cross-chain evm configuration storage at storage pointer slot.
    /// @return scs SubstrateConfigurationStorage struct instance at storage pointer position
    function substrateConfigurationStorage() internal pure returns (SubstrateConfigurationStorage storage scs) {
        // declare position
        bytes32 position = CC_SUBSTRATE_CONFIG_STORAGE_POSITION;

        // set slot to position
        assembly {
            scs.slot := position
        }

        // explicit return
        return scs;
    }

    // -----------------------------------------------------------------------
    //                              Getters
    // -----------------------------------------------------------------------

    /// @dev Diamond storage getter: Fundraising address.
    /// @param _nativeChainId ID of the chain
    /// @return Byte-encoded address of the fundraising
    function getFundraising(uint256 _nativeChainId) internal view returns (bytes memory) {
        // return
        return substrateConfigurationStorage().fundraisings[_nativeChainId];
    }

    /// @dev Diamond storage getter: Supported function.
    /// @param _nativeChainId ID of the chain
    /// @param _supportedFunction String name of supported of function
    /// @return True if function is supported
    function getSupportedFunction(uint256 _nativeChainId, bytes4 _supportedFunction) internal view returns (bool) {
        // return
        return substrateConfigurationStorage().supportedFunctions[_nativeChainId][_supportedFunction];
    }

    // -----------------------------------------------------------------------
    //                              Setters
    // -----------------------------------------------------------------------

    /// @dev Diamond storage setter: Fundraising address.
    /// @param _nativeChainId ID of the chain
    /// @param _fundraising Byte-encoded address of the fundraising
    function setFundraising(uint256 _nativeChainId, bytes memory _fundraising) internal {
        // set fundraising
        substrateConfigurationStorage().fundraisings[_nativeChainId] = _fundraising;
    }

    /// @dev Diamond storage setter: Supported function.
    /// @param _nativeChainId ID of the chain
    /// @param _supportedFunction String name of supported of function
    /// @param _isSupported Boolean if function is supported
    function setSupportedFunction(uint256 _nativeChainId, bytes4 _supportedFunction, bool _isSupported) internal {
        // set supported function
        substrateConfigurationStorage().supportedFunctions[_nativeChainId][_supportedFunction] = _isSupported;
    }
}
