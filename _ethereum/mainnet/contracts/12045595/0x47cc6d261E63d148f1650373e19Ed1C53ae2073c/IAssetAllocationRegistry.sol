// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

/**
 * @title Interface for addition and removal of asset allocations
          for account deployments
 * @author APY.Finance
 * @notice These functions enable external systems to pull necessary info
 *         to compute the TVL of the APY.Finance system.
 */
interface IAssetAllocationRegistry {
    // struct representing an execution against a contract given bytes
    // target is the garget contract to execute view calls agaisnt
    // bytes data represents the encoded function signature + parameters
    struct Data {
        address target;
        bytes data;
    }

    struct AssetAllocation {
        bytes32 sequenceId;
        string symbol;
        uint256 decimals;
        Data data;
    }

    function addAssetAllocation(
        bytes32 allocationId,
        Data calldata data,
        string calldata symbol,
        uint256 decimals
    ) external;

    function removeAssetAllocation(bytes32 allocationId) external;

    function isAssetAllocationRegistered(bytes32 allocationId)
        external
        view
        returns (bool);
}
