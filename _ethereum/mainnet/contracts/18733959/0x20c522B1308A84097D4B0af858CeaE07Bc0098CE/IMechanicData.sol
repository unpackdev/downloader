// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

/**
 * @notice Defines a mechanic's metadata on the MintManager
 */
interface IMechanicData {
    /**
     * @notice A mechanic's metadata
     * @param contractAddress Collection contract address
     * @param editionId Edition ID if the collection is edition based
     * @param mechanic Address of mint mechanic contract
     * @param isEditionBased True if collection is edition based
     * @param isChoose True if collection uses a collector's choice mint paradigm
     * @param paused True if mechanic vector is paused
     */
    struct MechanicVectorMetadata {
        address contractAddress;
        uint96 editionId;
        address mechanic;
        bool isEditionBased;
        bool isChoose;
        bool paused;
    }
}
