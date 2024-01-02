// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MulticallDelegateCall {
    function multicall(address target, bytes[] memory data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory returndata) = target.delegatecall(data[i]);
            require(success);
            results[i] = returndata;
        }
        return results;
    }
}