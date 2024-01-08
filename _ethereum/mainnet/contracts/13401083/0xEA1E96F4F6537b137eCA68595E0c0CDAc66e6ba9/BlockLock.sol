// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.6.12;

/**
 Contract which implements locking of functions via a notLocked modifier
 Functions are locked per address. 
 */
contract BlockLock {
    // how many blocks are the functions locked for
    uint256 private constant BLOCK_LOCK_COUNT = 6;
    // last block for which this address is timelocked
    mapping(address => uint256) public lastLockedBlock;
    mapping(address => bool) public blockLockExempt;

    function _lock(address lockAddress) internal {
        if (!blockLockExempt[lockAddress]) {
            lastLockedBlock[lockAddress] = block.number + BLOCK_LOCK_COUNT;
        }
    }

    function _exemptFromBlockLock(address lockAddress) internal {
        blockLockExempt[lockAddress] = true;
    }

    function _removeBlockLockExemption(address lockAddress) internal {
        blockLockExempt[lockAddress] = false;
    }

    modifier notLocked(address lockAddress) {
        require(lastLockedBlock[lockAddress] <= block.number, "Address is temporarily locked");
        _;
    }
}
