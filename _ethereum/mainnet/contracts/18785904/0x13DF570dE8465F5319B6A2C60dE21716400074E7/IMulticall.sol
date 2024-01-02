// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

interface IMulticall {
    error MulticallFailed(uint256 i, bytes returndata);

    /// @notice Call multiple functions in the contract. Revert if one of them fails, return results otherwise.
    /// @param data Encoded function calls.
    /// @return results The results of the function calls.
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}
