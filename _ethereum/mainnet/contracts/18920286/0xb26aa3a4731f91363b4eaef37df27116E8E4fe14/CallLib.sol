// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library CallLib {
    /**
     * @dev internal method that fecilitates the extenral calls from SmartAccount
     * @dev similar to execute() of Executor.sol
     * @param target destination address contract/non-contract
     * @param value amount of native tokens
     * @param data function singature of destination
     */
    function _call(
        address target,
        uint256 value,
        bytes memory data
    ) internal returns (bytes memory result) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let success := call(
                gas(),
                target,
                value,
                add(data, 0x20),
                mload(data),
                0,
                0
            )

            // Get the size of the returned data
            let size := returndatasize()

            // Allocate memory for the return data
            result := mload(0x40)

            // Set the length of the return data
            mstore(result, size)

            // Copy the return data to the allocated memory
            returndatacopy(add(result, 0x20), 0, size)

            // Update the free memory pointer
            mstore(0x40, add(result, add(0x20, size)))

            if iszero(success) {
                revert(result, returndatasize())
            }
        }
    }

    /**
     * @dev internal method that fecilitates the extenral calls from SmartAccount
     * @dev similar to execute() of Executor.sol
     * @param target destination address contract/non-contract
     * @param data function singature of destination
     */
    function _delegateCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory result) {
        require(target != address(this), "delegatecall to self");

        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Perform delegatecall to the target contract
            let success := delegatecall(
                gas(),
                target,
                add(data, 0x20),
                mload(data),
                0,
                0
            )

            // Get the size of the returned data
            let size := returndatasize()

            // Allocate memory for the return data
            result := mload(0x40)

            // Set the length of the return data
            mstore(result, size)

            // Copy the return data to the allocated memory
            returndatacopy(add(result, 0x20), 0, size)

            // Update the free memory pointer
            mstore(0x40, add(result, add(0x20, size)))

            if iszero(success) {
                revert(result, returndatasize())
            }
        }
    }
}
