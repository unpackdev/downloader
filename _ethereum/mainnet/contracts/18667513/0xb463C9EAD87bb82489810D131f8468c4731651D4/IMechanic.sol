// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./IMechanicData.sol";

/**
 * @notice Interface that mint mechanics are forced to adhere to,
 *         provided they support both collector's choice and sequential minting
 */
interface IMechanic is IMechanicData {
    /**
     * @notice Create a mechanic vector on the mechanic
     * @param mechanicVectorId Global mechanic vector ID
     * @param vectorData Mechanic vector data
     */
    function createVector(bytes32 mechanicVectorId, bytes calldata vectorData) external;

    /**
     * @notice Process a sequential mint
     * @param mechanicVectorId Global ID identifying mint vector, using this mechanic
     * @param recipient Mint recipient
     * @param numToMint Number of tokens to mint
     * @param mechanicVectorMetadata Mechanic vector metadata
     * @param data Custom data that can be deserialized and processed according to implementation
     */
    function processNumMint(
        bytes32 mechanicVectorId,
        address recipient,
        uint32 numToMint,
        MechanicVectorMetadata calldata mechanicVectorMetadata,
        bytes calldata data
    ) external payable;

    /**
     * @notice Process a collector's choice mint
     * @param mechanicVectorId Global ID identifying mint vector, using this mechanic
     * @param recipient Mint recipient
     * @param tokenIds IDs of tokens to mint
     * @param mechanicVectorMetadata Mechanic vector metadata
     * @param data Custom data that can be deserialized and processed according to implementation
     */
    function processChooseMint(
        bytes32 mechanicVectorId,
        address recipient,
        uint256[] calldata tokenIds,
        MechanicVectorMetadata calldata mechanicVectorMetadata,
        bytes calldata data
    ) external payable;
}
