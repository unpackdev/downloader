// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract MultipleTimeLock {
    struct TimeLock {
        address token;
        uint256 releaseTime;
    }

    mapping(address => TimeLock) public timeLocks;

    address public immutable beneficiary;

    /**
     * @dev Check if the given address is the beneficiary
     */
    modifier onlyBeneficiary() {
        require(msg.sender == beneficiary, "onlyBeneficiary");
        _;
    }

    /**
     * @dev Deploys a timelock instance that is able to hold tokens and will only release them to the deployer after the releaseTime
     */
    constructor() {
        beneficiary = msg.sender;
    }

    /**
     * @dev Create a timelock instance for one token. Could be called only one time by token
     */
    function addTimeLock(address _token, uint256 _releaseTime) public onlyBeneficiary {
        require(_releaseTime > block.timestamp, "release time is before current time");
        
        TimeLock storage timeLock = timeLocks[_token];
        require(timeLocks[_token].token == address(0), "TimeLock already exist for this token");

        timeLock.token = _token;
        timeLock.releaseTime = _releaseTime;
    }

    /**
     * @dev Increase the lock, can never be lower than the previous config
     */
    function increaseTimeLock(address _token, uint256 _releaseTime) public onlyBeneficiary {
        require(_releaseTime > block.timestamp, "release time is before current time");
        
        TimeLock storage timeLock = timeLocks[_token];
        require(timeLocks[_token].token == _token, "TimeLock not exist");
        require(_releaseTime > timeLock.releaseTime, "release time is before the current lock time");
        
        timeLock.releaseTime = _releaseTime;
    }

    /**
     * @dev Transfers tokens held by the timelock to the beneficiary. Will only succeed if invoked after the release
     * time.
     */
    function release(address _token) public onlyBeneficiary {
        TimeLock memory timeLock = timeLocks[_token];
        require(block.timestamp >= timeLock.releaseTime, "current time is before release time");

        uint256 amount = IERC20(_token).balanceOf(address(this));
        require(amount > 0, "no tokens to release");

        IERC20(_token).transfer(beneficiary, amount);
    }

    function getTimeLock(address _token) external view returns (TimeLock memory) {
        return timeLocks[_token];
    }
}