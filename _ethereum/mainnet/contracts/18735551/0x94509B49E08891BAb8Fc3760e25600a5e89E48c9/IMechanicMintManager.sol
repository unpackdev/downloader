// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./IMechanicData.sol";

/**
 * @notice Capabilities on MintManager pertaining to mechanics
 */
interface IMechanicMintManager is IMechanicData {
    /**
     * @notice Register a new mechanic vector
     * @param _mechanicVectorMetadata Mechanic vector metadata
     * @param seed Used to seed uniqueness into mechanic vector ID generation
     * @param vectorData Vector data to store on mechanic (optional)
     */
    function registerMechanicVector(
        MechanicVectorMetadata calldata _mechanicVectorMetadata,
        uint96 seed,
        bytes calldata vectorData
    ) external;

    /**
     * @notice Pause or unpause a mechanic vector
     * @param mechanicVectorId Global mechanic ID
     * @param pause If true, pause the mechanic mint vector. If false, unpause
     */
    function setPauseOnMechanicMintVector(bytes32 mechanicVectorId, bool pause) external;

    /**
     * @notice Mint a number of tokens sequentially via a mechanic vector
     * @param mechanicVectorId Global mechanic ID
     * @param recipient Mint recipient
     * @param numToMint Number of tokens to mint
     * @param data Custom data to be processed by mechanic
     */
    function mechanicMintNum(
        bytes32 mechanicVectorId,
        address recipient,
        uint32 numToMint,
        bytes calldata data
    ) external payable;

    /**
     * @notice Mint a specific set of token ids via a mechanic vector
     * @param mechanicVectorId Global mechanic ID
     * @param recipient Mint recipient
     * @param tokenIds IDs of tokens to mint
     * @param data Custom data to be processed by mechanic
     */
    function mechanicMintChoose(
        bytes32 mechanicVectorId,
        address recipient,
        uint256[] calldata tokenIds,
        bytes calldata data
    ) external payable;
}
