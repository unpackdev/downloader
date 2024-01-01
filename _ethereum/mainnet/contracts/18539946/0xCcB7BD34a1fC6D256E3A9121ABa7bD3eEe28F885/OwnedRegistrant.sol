// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IOperatorFilterRegistry.sol";
import "./Ownable2Step.sol";
/**
 * @title  OwnedRegistrant
 * @notice Ownable contract that registers itself with the OperatorFilterRegistry and administers its own entries,
 *         to facilitate a subscription whose ownership can be transferred.
 */

contract OwnedRegistrant is Ownable2Step {
    address private constant REGISTRY = 0x000000000000AAeB6D7670E522A718067333cd4E;

    /// @dev The constructor that is called when the contract is being deployed.
    constructor(address _owner) {
        IOperatorFilterRegistry(REGISTRY).register(address(this));
        transferOwnership(_owner);
    }
}
