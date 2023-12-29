// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @notice IInstanceRegistry interface
 * @dev Source: https://github.com/ampleforth/token-geyser-v2/blob/c878fd6ba5856d818ff41c54bce59c9413bc93c9/contracts/Factory/InstanceRegistry.sol#L6-L19
 */
interface IInstanceRegistry {
    /* events */

    event InstanceAdded(address instance);
    event InstanceRemoved(address instance);

    /* view functions */

    function isInstance(address instance) external view returns (bool validity);

    function instanceCount() external view returns (uint256 count);

    function instanceAt(uint256 index) external view returns (address instance);
}
