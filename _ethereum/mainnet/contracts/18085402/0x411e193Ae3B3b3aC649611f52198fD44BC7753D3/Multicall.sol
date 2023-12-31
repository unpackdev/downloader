// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MultiCall {
    struct Call {
        address target;
        bytes callData;
    }

    function aggregate(
        Call[] memory calls
    ) external view returns (bytes[] memory) {
        bytes[] memory results = new bytes[](calls.length);

        for (uint i; i < calls.length; i++) {
            (bool success, bytes memory result) = calls[i].target.staticcall(
                calls[i].callData
            );
            require(success, "call failed");
            results[i] = result;
        }

        return results;
    }
}
