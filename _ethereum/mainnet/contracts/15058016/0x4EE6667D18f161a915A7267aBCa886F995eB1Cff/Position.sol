// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.11;

import "./Constants.sol";

library Position {
    /// @param balance total underlying balance
    /// @param unlocked underlying value already unlocked
    /// @param rate value unlocked per second, up to ~1.84e19 tokens per second
    /// @param start when position starts unlocking
    /// @param end when position unlocking ends
    /// @param pendingRevDis pending revenue distribution share to be claimed
    /// @param revDisPerTokenPaid last revDisPerToken applied to the position
    struct Data {
        uint128 balance;
        uint128 unlocked;
        uint64 start;
        uint64 end;
        uint128 rate;
        uint128 pendingRevDis;
        uint256 revDisPerTokenPaid;
    }

    /// @param balance total underlying balance
    /// @param start when position starts unlocking
    /// @param end when position unlocking ends
    struct InitParams {
        uint128 balance;
        uint64 start;
        uint64 end;
    }

    /// @dev Vesting schedule uses the position unlock rate to determine how much
    /// underlying has vested (and is able to be unlocked) instead of the balance.
    /// @dev Holders are able to move back and forward their positions balances
    /// to the Bonds contract without sacrificing how many tokens can be unlocked per second.
    function vestedUnderlying(Data storage _position) internal view returns (uint256) {
        if (block.timestamp <= _position.start) {
            return 0;
        } else if (block.timestamp < _position.end) {
            return ((block.timestamp - _position.start) * _position.rate) - _position.unlocked;
        } else {
            return _position.balance;
        }
    }

    /// @dev Calculates accumulated revenue distribution for given position using
    /// the latest values.
    function earnedRevDis(Data storage _position, uint256 _revDisPerToken) internal view returns (uint256) {
        return
            ((_position.balance * (_revDisPerToken - _position.revDisPerTokenPaid)) / Constants.BASE_MULTIPLIER) +
            _position.pendingRevDis;
    }
}
