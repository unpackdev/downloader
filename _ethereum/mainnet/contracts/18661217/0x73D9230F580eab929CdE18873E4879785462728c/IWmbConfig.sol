// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWmbConfig {
    /**
     * @dev Batch sets the base fee for different target chains
     * @param targetChainIds An array of target chain IDs
     * @param baseFees An array of base fee values, corresponding to the target chain IDs
     */
    function batchSetBaseFees(uint256[] calldata targetChainIds, uint256[] calldata baseFees) external;

    /**
     * @dev Sets the signature verification and contract addresses
     * @param signatureVerifier The address of the signature verification contract
     */
    function setSignatureVerifier(address signatureVerifier) external;

    /**
     * @dev Sets the maximum global gas limit
     * @param maxGasLimit The maximum global gas limit value to set
     * @param minGasLimit The minimum global gas limit value to set
     * @param defaultGasLimit The default global gas limit value to set
     */
    function setGasLimit(uint256 maxGasLimit, uint256 minGasLimit, uint256 defaultGasLimit) external;

    /**
     * @notice Sets the maximum message length allowed by the contract
     * @param _maxMessageLength The maximum message length
     */
    function setMaxMessageLength(uint256 _maxMessageLength) external;

    /**
     * @dev Sets the supported destination chains
     * @param targetChainIds An array of target chain IDs
     * @param supported An array of supported values, corresponding to the target chain IDs
     */
    function setSupportedDstChains(uint256[] calldata targetChainIds, bool[] calldata supported) external;
}
