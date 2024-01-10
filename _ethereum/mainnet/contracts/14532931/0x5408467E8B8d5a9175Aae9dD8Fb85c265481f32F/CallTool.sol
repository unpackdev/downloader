// SPDX-License-Identifier: NONE
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Address.sol";

/* solhint-disable comprehensive-interface */
/// @title Call tools
/// @notice contract for executing a batch of calls to other contracts
contract CallTool {
    /// @notice Calls a list of contracts with the supplied data for each call. Reverts if any of the calls revert
    /// @param contracts list of contracts to call
    /// @param data list of data for call to each contract, must be equal length to contracts
    function multicall(address[] calldata contracts, bytes[] calldata data)
        external
    {
        require(contracts.length == data.length, "Mismatching length");
        for (uint256 i = 0; i < data.length; i++) {
            Address.functionCall(contracts[i], data[i]);
        }
    }

    /// @notice same as multicall, but doesn't revert if any of the calls revert
    /// @param contracts list of contracts to call
    /// @param data list of data for call to each contract, must be equal length to contracts
    function multicallUnsafe(
        address[] calldata contracts,
        bytes[] calldata data
    ) external {
        require(contracts.length == data.length, "Mismatching length");
        for (uint256 i = 0; i < data.length; i++) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool _success, ) = contracts[i].call(data[i]); //unsafe call, ignores reverts
            // solhint-disable-next-line no-empty-blocks
            if (_success) {} //ignore success or failure
        }
    }
}
