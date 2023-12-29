// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Ownable.sol";

error Frozen();

/**
 * @dev Extension of Ownable that has ability to freeze parts of the contract
 * decorated with `notFrozen` and allows turning parts of the contract
 * to be immutable.
 */
contract Freezable is Ownable {
    bool public frozen;

    /**
     * @dev Throws if called after the contract is frozen
     */
    modifier notFrozen() {
        if (frozen) {
            revert Frozen();
        }
        _;
    }

    /**
     * @dev Freezes contract
     */
    function freeze() external onlyOwner notFrozen {
        frozen = true;
    }
}
