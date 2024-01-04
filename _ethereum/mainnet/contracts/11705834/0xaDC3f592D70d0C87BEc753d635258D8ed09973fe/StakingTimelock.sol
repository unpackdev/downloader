// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./SafeMath.sol";
import "./Ownable.sol";

contract StakingTimelock is Ownable {
    using SafeMath for uint256;

    uint256 public duration = 1 days;

    struct StakingDetails {
        uint256 lastStakedOn;
        uint256 lastStakedAmount;
        uint256 totalStakedAmount;
    }

    mapping(address => StakingDetails) public _stakingDetails;

    constructor(uint256 _duration) public {
        duration = _duration;
    }

    modifier checkLockDuration {
        StakingDetails storage _stakerDetails = _stakingDetails[msg.sender];

        require(_stakerDetails.lastStakedOn != 0);
        require(_stakerDetails.lastStakedAmount != 0);
        require(_stakerDetails.totalStakedAmount != 0);
        require(_stakerDetails.lastStakedOn + duration <= block.timestamp);
        _;
    }

    function getStakerDetails() public view returns (uint256, uint256) {
        StakingDetails storage _stakerDetails = _stakingDetails[msg.sender];

        return (_stakerDetails.lastStakedOn, _stakerDetails.lastStakedAmount);
    }

    function changeLockDuration(uint256 _duration) public onlyOwner {
        duration = _duration;
    }

    function getLockDuration() public view returns (uint256) {
        return duration;
    }
}
