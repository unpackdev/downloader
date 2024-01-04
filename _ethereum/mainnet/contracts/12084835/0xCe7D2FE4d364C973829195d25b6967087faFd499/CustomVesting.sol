// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";

contract CustomVesting is Ownable {
    using SafeERC20 for IERC20;

    event PauseVesting(address indexed account, bool pause);
    event AddVesting(address indexed account, uint256 amount, uint256 startTime, uint256 endTime);
    event DeleteVesting(address indexed account);

    struct VestingData {
        bool isPaused;
        IERC20 token;
        uint256 vested;
        uint256 total;
        uint256 startTime;
        uint256 endTime;
    }

    mapping(address => VestingData) public vesting;

    function setPause(address _account, bool _pause) external onlyOwner {
        require(vesting[_account].total > 0, "Vesting: user has no vesting schedule");
        vesting[_account].isPaused = _pause;
        emit PauseVesting(_account, _pause);
    }

    function addVestingSchedule(address _account, IERC20 _token, uint256 _amount, uint256 _startTime, uint256 _endTime) external onlyOwner {
        // initialize vesting schedule for user (one-time only)
        require(vesting[_account].total == vesting[_account].vested, "Vesting: user already has a vesting schedule");
        require(_startTime < _endTime, "Vesting: _startTime >= _endTime");
        vesting[_account] = VestingData({
            isPaused: false,
            token: _token,
            vested: 0,
            total: _amount,
            startTime: _startTime,
            endTime: _endTime
        });
        emit AddVesting(_account, _amount, _startTime, _endTime);
    }
    
    function deleteVestingSchedule(address _account) external onlyOwner {
        require(vesting[_account].total > 0, "Vesting: user has no vesting schedule");
        vesting[_account].token.safeTransfer(owner(), vesting[_account].total - vesting[_account].vested);
        delete vesting[_account];
        emit DeleteVesting(_account);
    }

    function vest() external {
        VestingData storage userVesting = vesting[msg.sender];
        require(userVesting.total > 0, "Vesting: no vesting schedule!");
        require(!userVesting.isPaused, "Vesting: user's vesting is paused!");
        require(block.timestamp > userVesting.startTime, "Vesting: !started");
        uint256 toBeReleased = releasableAmount(msg.sender);
        require(toBeReleased > 0, "Vesting: no tokens to release");

        userVesting.vested = userVesting.vested + toBeReleased;
        userVesting.token.safeTransfer(msg.sender, toBeReleased);
    }

    function releasableAmount(address _addr) public view returns (uint256) {
        return _unlockedAmount(_addr) - vesting[_addr].vested;
    }

    function _unlockedAmount(address _addr) private view returns (uint256) {
        if (block.timestamp <= vesting[_addr].endTime) {
            uint256 duration = vesting[_addr].endTime - vesting[_addr].startTime;
            uint256 timePassed = block.timestamp - vesting[_addr].startTime;
            return (vesting[_addr].total * timePassed) / duration;
        } else {
            return vesting[_addr].total;
        }
    }
}
