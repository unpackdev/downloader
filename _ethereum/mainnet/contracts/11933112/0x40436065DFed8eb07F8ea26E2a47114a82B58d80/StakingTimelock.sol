// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Ownable.sol";

abstract contract StakingTimelock is Ownable {
    using SafeMath for uint256;

    uint256 public duration = 1 days;

    struct StakingDetails {
        uint256 deadline;
        uint256 amount;
        uint256 updatedOn;
    }

    mapping(address => StakingDetails) public stakingDetails;

    constructor(uint256 _duration) {
        duration = _duration;
    }

    modifier checkLockDuration {
        StakingDetails storage _stakerDetails = stakingDetails[msg.sender];

        require(_stakerDetails.deadline != 0);
        require(_stakerDetails.amount != 0);
        require(_stakerDetails.deadline <= block.timestamp);
        _;
    }

    modifier checkLockDurationFor(address who) {
        StakingDetails storage _stakerDetails = stakingDetails[who];

        require(_stakerDetails.deadline != 0);
        require(_stakerDetails.amount != 0);
        require(_stakerDetails.deadline <= block.timestamp);
        _;
    }

    modifier checkLockDurationWithAmount(uint256 amount) {
        StakingDetails storage _stakerDetails = stakingDetails[msg.sender];

        require(_stakerDetails.deadline != 0);
        require(_stakerDetails.amount <= amount);
        require(_stakerDetails.deadline <= block.timestamp);
        _;
    }

    function getStakerDetails(address who)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        StakingDetails storage _stakerDetails = stakingDetails[who];
        return (
            _stakerDetails.amount,
            _stakerDetails.deadline,
            _stakerDetails.updatedOn
        );
    }

    function getStakedAmount(address who) public view returns (uint256) {
        StakingDetails storage _stakerDetails = stakingDetails[who];
        return _stakerDetails.amount;
    }

    function _updateStakerDetails(address who, uint256 _amount) internal {
        StakingDetails storage _stakerDetails = stakingDetails[who];
        _stakerDetails.deadline = block.timestamp + duration;
        _stakerDetails.updatedOn = block.timestamp;
        _stakerDetails.amount = _amount;
    }

    function changeLockDuration(uint256 _duration) public onlyOwner {
        duration = _duration;
    }

    function getLockDuration() public view returns (uint256) {
        return duration;
    }
}
