// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Ownable.sol";

contract Wallet is Ownable {
    event Execute(address indexed target, bytes data, bytes response);

    error ExecutionFailed(uint256 index);

    function call(
        address target,
        uint256 value,
        bytes memory data
    ) external payable onlyOwner returns (bytes memory result) {
        bool success;
        (success, result) = target.call{ value: value }(data);

        emit Execute(target, data, result);

        if (!success) {
            // If there is return data, the call reverted with a reason or a custom error.
            if (result.length > 0) {
                assembly {
                    let returndata_size := mload(result)
                    revert(add(32, result), returndata_size)
                }
            } else {
                revert ExecutionFailed(0);
            }
        }
    }

    function multicall(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory datas
    ) external payable onlyOwner returns (bytes[] memory results) {
        uint256 length = datas.length;
        results = new bytes[](length);

        for (uint256 i; i < length; i++) {
            address target = targets[i];
            uint256 value = values[i];
            bytes memory data = datas[i];

            (bool success, bytes memory result) = target.call{ value: value }(data);

            emit Execute(target, data, result);

            if (!success) {
                // If there is return data, the call reverted with a reason or a custom error.
                if (result.length > 0) {
                    assembly {
                        let returndata_size := mload(result)
                        revert(add(32, result), returndata_size)
                    }
                } else {
                    revert ExecutionFailed(i);
                }
            }

            results[i] = result;
        }
    }

    receive() external payable {}
}
