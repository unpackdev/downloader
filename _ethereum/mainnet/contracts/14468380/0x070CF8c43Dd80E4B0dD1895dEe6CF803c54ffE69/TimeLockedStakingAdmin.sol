// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

import "./TimeLockedStaking.sol";

/// @title Admin contract to manage a TimeLockedStaking contract
contract TimeLockedStakingAdmin is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// @notice The underlying TimeLockedStaking contract
    TimeLockedStaking public immutable tls;

    constructor(TimeLockedStaking _tls) {
        tls = _tls;
    }

    /// @notice Transfers ownership of the underlying contract to a new account
    /// @param newOwner The new owner
    function transferTLSOwnership(address newOwner) public virtual onlyOwner {
        tls.transferOwnership(newOwner);
    }

    /// @notice Updates lock time
    /// @param _lockTime New lock time
    function setLockTime(uint256 _lockTime) external onlyOwner {
        tls.setLockTime((_lockTime));
    }

    /// @notice Admin-only to force unstake a user's tokens.
    /// @param _user The user to force withdraw
    /// @param _amount The amount to force withdraw
    function forceUnstake(address _user, uint256 _amount) external onlyOwner {
        tls.forceUnstake(_user, _amount);
    }

    /// @notice Admin-only to force unstake multiple users
    /// @param _users The users to force withdraw
    /// @param _amounts The amounts to force withdraw
    function batchForceUnstake(
        address[] memory _users,
        uint256[] memory _amounts
    ) external onlyOwner {
        require(_users.length == _amounts.length, "array lengths must match");
        for (uint256 i = 0; i < _users.length; i++) {
            tls.forceUnstake(_users[i], _amounts[i]);
        }
    }
}
