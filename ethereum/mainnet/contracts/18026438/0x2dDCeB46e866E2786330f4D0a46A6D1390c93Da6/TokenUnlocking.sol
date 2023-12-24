// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "./Ownable.sol";
import "./IERC20.sol";

contract TokenUnlocking is Ownable {
    address public immutable lbr;

    mapping(address => UnlockingRule) public UnlockingInfo;

    event Vest(address indexed _user, uint256 _amount, uint256 _timestamp);

    event SetUnlockRule(
        address indexed _user,
        uint256 _totalLocked,
        uint256 _duration,
        uint256 _unlockStartTime,
        uint256 _lastWithdrawTime
    );

    constructor(address _lbr) {
        lbr = _lbr;
    }

    struct UnlockingRule {
        uint256 totalLocked;
        uint256 duration;
        uint256 unlockStartTime;
        uint256 lastWithdrawTime;
        uint256 lastWithdrawRemain;
    }

    function setUnlockRule(
        address _user,
        uint256 _duration,
        uint256 _totalLocked,
        uint256 _unlockStartTime,
        uint256 _lastWithdrawTime
    ) external onlyOwner {
        require(_unlockStartTime > 0, "Invalid time");
        require(
            UnlockingInfo[_user].lastWithdrawTime == 0,
            "This rule has already been set."
        );

        UnlockingInfo[_user].totalLocked = _totalLocked;
        UnlockingInfo[_user].duration = _duration;
        UnlockingInfo[_user].unlockStartTime = _unlockStartTime;
        UnlockingInfo[_user].lastWithdrawTime = _lastWithdrawTime;
        emit SetUnlockRule(
            _user,
            _totalLocked,
            _duration,
            _unlockStartTime,
            _lastWithdrawTime
        );
    }

    function getUserUnlockInfo(
        address _user
    ) external view returns (UnlockingRule memory) {
        return UnlockingInfo[_user];
    }

    function getRewards(address _user) public view returns (uint256) {
        if (
            block.timestamp <= UnlockingInfo[_user].unlockStartTime ||
            UnlockingInfo[_user].unlockStartTime == 0
        ) return 0;
        uint256 unlockEndTime = UnlockingInfo[_user].unlockStartTime +
            UnlockingInfo[_user].duration;
        uint256 rate = UnlockingInfo[_user].totalLocked /
            UnlockingInfo[_user].duration;
        uint256 reward = block.timestamp > unlockEndTime
            ? (unlockEndTime - UnlockingInfo[_user].lastWithdrawTime) * rate
            : (block.timestamp - UnlockingInfo[_user].lastWithdrawTime) * rate;
        return reward;
    }

    function getTotalRewards(address _user) external view returns (uint256) {
        return getRewards(_user) + UnlockingInfo[_user].lastWithdrawRemain;
    }

    function vest(address _user, uint256 _amount) external {
        require(
            block.timestamp >= UnlockingInfo[_user].unlockStartTime,
            "The time has not yet arrived."
        );
        require(_amount > 0, "Invalid amount.");
        uint256 unlockEndTime = UnlockingInfo[_user].unlockStartTime +
            UnlockingInfo[_user].duration;
        uint256 lastWithdrawRemain = UnlockingInfo[_user].lastWithdrawRemain;

        if (_amount <= lastWithdrawRemain) {
            UnlockingInfo[_user].lastWithdrawRemain =
                lastWithdrawRemain -
                _amount;
            IERC20(lbr).transfer(_user, _amount);
            emit Vest(_user, _amount, block.timestamp);
        } else {
            uint256 currVestAmount = getRewards(_user);
            uint256 canClaimAmount = lastWithdrawRemain + currVestAmount;
            if (_amount <= canClaimAmount) {
                UnlockingInfo[_user].lastWithdrawRemain =
                    canClaimAmount -
                    _amount;
                IERC20(lbr).transfer(_user, _amount);
                emit Vest(_user, _amount, block.timestamp);
            } else {
                UnlockingInfo[_user].lastWithdrawRemain = 0;
                IERC20(lbr).transfer(_user, canClaimAmount);
                emit Vest(_user, canClaimAmount, block.timestamp);
            }

            if (block.timestamp >= unlockEndTime) {
                UnlockingInfo[_user].lastWithdrawTime = unlockEndTime;
            } else {
                UnlockingInfo[_user].lastWithdrawTime = block.timestamp;
            }
        }
    }

    function withdrawTokenEmergency(
        address token,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
    }
}
