// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Ownable.sol";

contract Wallet is Ownable {
    event Execute(address indexed target, bytes data, bytes response);

    error ExecutionFailed(uint256 index);

    function call(address target, bytes memory data) external payable onlyOwner returns (bytes memory response) {
        bool success;
        (success, response) = target.delegatecall(data);

        emit Execute(target, data, response);

        if (!success) {
            // If there is return data, the call reverted with a reason or a custom error.
            if (response.length > 0) {
                assembly {
                    let returndata_size := mload(response)
                    revert(add(32, response), returndata_size)
                }
            } else {
                revert ExecutionFailed(0);
            }
        }
    }

    function multicall(address[] memory targets, bytes[] memory datas)
        external
        payable
        onlyOwner
        returns (bytes[] memory responses)
    {
        uint256 length = datas.length;
        responses = new bytes[](length);

        for (uint256 i; i < length; i++) {
            address target = targets[i];
            bytes memory data = datas[i];

            (bool success, bytes memory response) = target.delegatecall(data);

            emit Execute(target, data, response);

            if (!success) {
                // If there is return data, the call reverted with a reason or a custom error.
                if (response.length > 0) {
                    assembly {
                        let returndata_size := mload(response)
                        revert(add(32, response), returndata_size)
                    }
                } else {
                    revert ExecutionFailed(i);
                }
            }

            responses[i] = response;
        }
    }

    receive() external payable {}
}
