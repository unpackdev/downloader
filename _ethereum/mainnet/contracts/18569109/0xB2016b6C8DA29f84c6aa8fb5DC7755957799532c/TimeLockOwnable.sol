// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";

abstract contract TimeLockOwnable is Ownable {

    uint256 private immutable DELAY;

    uint256 private _lastTransferTimestamp;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(uint256 delay_) {
        require(delay_ > 0, "TimeLockOwnable: delay must be > 0");
        require(delay_ <= 30 days, "TimeLockOwnable: delay must be <= 30 days");

        _transferOwnership(_msgSender());
        DELAY = delay_;
        // The owner will be able to transfer ownership first time without waiting
        _lastTransferTimestamp = 0;
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        require(block.timestamp > _lastTransferTimestamp + DELAY, "TimeLockOwnable: still locked");
        _lastTransferTimestamp = block.timestamp;
        super.transferOwnership(newOwner);
    }
        
}
