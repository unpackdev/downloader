pragma solidity 0.7.6;

/**
 Contract which implements locking of functions via a notLocked modifier
 Functions are locked per address. 
 */
contract BlockLock {
    // how many blocks are the functions locked for
    uint256 private constant BLOCK_LOCK_COUNT = 6;
    // last block for which this address is timelocked
    mapping(address => uint256) public lastLockedBlock;

    modifier notLocked() {
        require(lastLockedBlock[msg.sender] <= block.number);
        _;
        lastLockedBlock[msg.sender] = block.number + BLOCK_LOCK_COUNT;
    }
}
