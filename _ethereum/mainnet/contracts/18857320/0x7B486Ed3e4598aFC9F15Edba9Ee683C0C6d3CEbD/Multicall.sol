// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import "./IMulticall.sol";

/// @title Multicall
/// @author Florida St
/// @notice Base implementation for multicall.
abstract contract Multicall is IMulticall {
    function multicall(bytes[] calldata data) external payable override returns (bytes[] memory results) {
        results = new bytes[](data.length);
        bool success;
        for (uint256 i = 0; i < data.length;) {
            //slither-disable-next-line calls-loop,delegatecall-loop
            (success, results[i]) = address(this).delegatecall(data[i]);
            if (!success) revert MulticallFailed(i, results[i]);
            unchecked {
                ++i;
            }
        }
    }
}
