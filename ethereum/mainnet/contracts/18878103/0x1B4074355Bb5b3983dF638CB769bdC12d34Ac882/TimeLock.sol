// SPDX-License-Identifier: MIT
// Timelock
pragma solidity 0.8.21;

abstract contract TimeLock {
	uint256 public immutable TIME_LOCK_DELAY;

	mapping(bytes32 => uint256) public changePendings;

	event ChangeScheduled(bytes32 indexed ParamsHash, uint256 ScheduledAt);
    event Changed(bytes32 indexed ParamsHash, uint256 FactdAt);
	
	modifier afterTimeLock(bytes32 newParamsHash)
    {
        if (TIME_LOCK_DELAY != 0) {
            if (changePendings[newParamsHash] == 0) {
                // New change pending
                changePendings[newParamsHash] = block.timestamp + TIME_LOCK_DELAY;
                emit ChangeScheduled(newParamsHash, block.timestamp + TIME_LOCK_DELAY);
        
            } else if (changePendings[newParamsHash] <= block.timestamp ) {
                // Operation ready
                changePendings[newParamsHash] = 0;
                emit Changed(newParamsHash, block.timestamp);
                _;

            } else {
                revert('Still pending');
            }

        } else {
            _;
        }
    }

    constructor(uint256 _timeLockDelay)
    {
        TIME_LOCK_DELAY = _timeLockDelay;
    }
}