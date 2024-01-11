// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.11;

import "./Constants.sol";

library Bond {
    /// @param payout unlocked underlying tokens that will be received upon expiration
    /// @param expiresAt Timestamp of when the bond expires and is able to unlock the payout
    struct Data {
        uint128 payout;
        uint128 expiresAt;
    }

    struct Stake {
        uint128 balance;
        uint128 pendingYield;
        uint256 pendingRevDis;
        uint256 yieldPerTokenPaid;
        uint256 revDisPerTokenPaid;
    }

    /// @dev Calculates accumulated revenue distribution for given staked bond using
    /// the latest values.
    function earnedRevDis(Stake storage _stakedBond, uint256 _revDisPerToken) internal view returns (uint256) {
        return
            ((_stakedBond.balance * (_revDisPerToken - _stakedBond.revDisPerTokenPaid)) / Constants.BASE_MULTIPLIER) +
            _stakedBond.pendingRevDis;
    }

    /// @dev Calculates accumulated yield for given staked bond using
    /// the latest values.
    function earnedYield(Stake storage _stakedBond, uint256 _yieldPerToken) internal view returns (uint256) {
        return
            ((_stakedBond.balance * (_yieldPerToken - _stakedBond.yieldPerTokenPaid)) / Constants.BASE_MULTIPLIER) +
            _stakedBond.pendingYield;
    }
}
