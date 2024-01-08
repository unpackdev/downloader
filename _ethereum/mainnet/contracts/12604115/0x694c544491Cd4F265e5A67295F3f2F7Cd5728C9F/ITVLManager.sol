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
interface ITVLManager {
    // struct representing a view call execution against a target contract given bytes
    // target is the target contract to execute view calls against
    // bytes data represents the encoded function signature + parameters
    struct Data {
        address target;
        bytes data;
    }

    // struct representing the relevant pieces of data that need to be provided when registering an asset allocation
    // symbol is the symbol of the token that the resulting view call execution will need to be evaluated as
    // decimals is the number of decimals that the resulting view call execution will need to be evaluated as
    // data is the struct representing the view call execution
    struct AssetAllocation {
        string symbol;
        uint256 decimals;
        Data data;
    }

    function addAssetAllocation(
        Data calldata data,
        string calldata symbol,
        uint256 decimals
    ) external;

    function removeAssetAllocation(Data calldata data) external;

    function generateDataHash(Data calldata data)
        external
        pure
        returns (bytes32);

    function isAssetAllocationRegistered(Data calldata data)
        external
        view
        returns (bool);
}
