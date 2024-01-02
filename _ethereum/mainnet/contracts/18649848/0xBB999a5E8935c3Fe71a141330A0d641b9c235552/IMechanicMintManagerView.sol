// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./IMechanicData.sol";

interface IMechanicMintManagerView is IMechanicData {
    /**
     * @notice Get a mechanic vector's metadata
     * @param mechanicVectorId Global mechanic vector ID
     */
    function mechanicVectorMetadata(bytes32 mechanicVectorId) external view returns (MechanicVectorMetadata memory);
}
