// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import "./SafeMath.sol";
import "./IAbstractCooldownStaking.sol";

abstract contract AbstractCooldownStaking is IAbstractCooldownStaking{
    using SafeMath for uint256;

    uint256 internal constant WITHDRAWING_COOLDOWN_DURATION = 7 days;
    uint256 internal constant WITHDRAWAL_PHASE_DURATION = 2 days;

    struct WithdrawalInfo {
        uint256 coolDownTimeEnd;
        uint256 amount;             //optional
    }

    mapping(address => WithdrawalInfo) internal withdrawalsInfo;

    // There is a second withdrawal phase of 48 hours to actually receive the rewards.
    // If a user misses this period, in order to withdraw he has to wait for 7 days again.
    // It will return:
    // 0 if cooldown time didn't start or if phase duration (48hs) has expired
    // #coolDownTimeEnd Time when user can withdraw.
    function whenCanWithdrawBrightReward(address _address) internal view returns (uint256) {
        return
        withdrawalsInfo[_address].coolDownTimeEnd.add(WITHDRAWAL_PHASE_DURATION) >=
        block.timestamp
        ? withdrawalsInfo[_address].coolDownTimeEnd
        : 0;
    }

    function getWithdrawalInfo(address _userAddr) external view override
    returns (
        uint256 _amount,
        uint256 _unlockPeriod,
        uint256 _availableFor
    )
    {
        _unlockPeriod = whenCanWithdrawBrightReward(_userAddr);
        if (_unlockPeriod > 0) {
            _amount = withdrawalsInfo[_userAddr].amount;

            uint256 endUnlockPeriod = _unlockPeriod.add(WITHDRAWAL_PHASE_DURATION);
            _availableFor = _unlockPeriod <= block.timestamp ? endUnlockPeriod : 0;
        }
    }

}
