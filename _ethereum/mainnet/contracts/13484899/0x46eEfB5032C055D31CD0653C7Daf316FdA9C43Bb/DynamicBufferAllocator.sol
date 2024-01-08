// SPDX-License-Identifier: UNLICENSED
// Copyright 2021 David Huber (@cxkoda)
// All Rights Reserved

pragma solidity >=0.8.0 <0.9.0;

/**
 * @notice Allocation of a dynamically resizable byte container.
 * @author David Huber (@cxkoda)
 */
contract DynamicBufferAllocator {
    /**
     * @notice Allocates a byte buffer container with a given max capacity.
     * @dev In solidity, the first 32B in dynamic arrays are always reserved
     * @dev for the length of the array. This tells consumers for how long they
     * @dev have to read the memory. 
     * @dev Here we allocate a container that contains the memory layout of 
     * @dev another dynamic array (buffer), whose length we will continuously
     * @dev increase as we append data to it.
     * @dev This has the advantage that solidity can directly interpret the data
     * @dev from the buffer position in memory as a standard array.
     * @dev | container length (32B) | buffer length = s (32B) | buffer data (s B) | ... |
     */
    function _allocate(uint256 capacity)
        internal
        pure
        returns (bytes memory container, bytes memory buffer)
    {
        assembly {
            // Get next-free memory address
            container := mload(0x40)

            // Allocate memory by setting a new next-free address
            {
                // Add 2 x 32 bytes in size for the two length fields
                let size := add(capacity, 0x40)
                let newNextFree := add(container, size)
                mstore(0x40, newNextFree)
            }

            // Set the correct container length
            {
                let length := add(capacity, 0x40)
                mstore(container, length)
            }

            // The buffer starts at idx 1 in the container (0 is length)
            buffer := add(container, 0x20)

            // Init content with length 0
            mstore(buffer, 0)
        }
    }
}
