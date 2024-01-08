// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.3;

/**
 Contract which implements locking of functions via a notLocked modifier
 Functions are locked per address. 
 */
contract BlockLock {
    // how many blocks are the functions locked for
    uint256 private constant BLOCK_LOCK_COUNT = 16;
    // last block for which this address is timelocked
    mapping(address => uint256) public lastLockedBlock;

    function lock(address _address) internal {
        lastLockedBlock[_address] = block.number + BLOCK_LOCK_COUNT;
    }

    modifier notLocked(address lockedAddress) {
        require(lastLockedBlock[lockedAddress] <= block.number);
        _;
    }
}
