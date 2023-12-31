// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Interface to the MstWrapper Factory
 */
interface IMstWrapperFactory {
    /*--------------------------------------------------------------------------*/
    /* Errors                                                                   */
    /*--------------------------------------------------------------------------*/

    /**
     * @notice Unsupported MstWrapper implementation
     */
    error UnsupportedImplementation();

    /*--------------------------------------------------------------------------*/
    /* Events */
    /*--------------------------------------------------------------------------*/

    /**
     * @notice Emitted when a mstWrapper token is created
     * @param mstWrapper MstWrapper instance
     * @param implementation Implementation contract
     */
    event MstWrapperCreated(address indexed mstWrapper, address indexed implementation);

    /**
     * @notice Emitted when a mstWrapper token implementation is added to allowlist
     * @param implementation Implementation contract
     */
    event MstWrapperImplementationAdded(address indexed implementation);

    /**
     * @notice Emitted when a mstWrapper token implementation is removed from allowlist
     * @param implementation Implementation contract
     */
    event MstWrapperImplementationRemoved(address indexed implementation);

    /*--------------------------------------------------------------------------*/
    /* API                                                                      */
    /*--------------------------------------------------------------------------*/

    /**
     * @notice Create a mstWrapper token (immutable)
     * @param mstWrapperImplementation MstWrapper implementation contract
     * @param params Parameters
     * @return MstWrapper address
     */
    function create(address mstWrapperImplementation, bytes calldata params) external returns (address);

    /**
     * @notice Create a mstWrapper token (proxied)
     * @param mstWrapperBeacon MstWrapper beacon contract
     * @param params Parameters
     * @return MstWrapper address
     */
    function createProxied(address mstWrapperBeacon, bytes calldata params) external returns (address);

    /**
     * @notice Check if address is a mstWrapper token
     * @param mstWrapperToken MstWrapper token address
     * @return True if address is a mstWrapper, otherwise false
     */
    function isMstWrapperToken(address mstWrapperToken) external view returns (bool);

    /**
     * @notice Get list of mstWrapper tokens
     * @return List of mstWrapper addresses
     */
    function getMstWrapperTokens() external view returns (address[] memory);

    /**
     * @notice Get count of mstWrapper tokens
     * @return Count of mstWrapper tokens
     */
    function getMstWrapperTokenCount() external view returns (uint256);

    /**
     * @notice Get mstWrapper token at index
     * @param index Index
     * @return MstWrapper token address
     */
    function getMstWrapperTokenAt(uint256 index) external view returns (address);

    /**
     * @notice Get list of supported mstWrapper implementations
     * @return List of mstWrapper implementations
     */
    function getMstWrapperImplementations() external view returns (address[] memory);
}
