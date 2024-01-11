// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ICrvDepositor.sol";

contract StakeDaoAdapter {
    using SafeERC20 for IERC20;

    /* ========== CONSTRUCTOR  ========== */

    constructor() {}

    /* ========== PUBLIC METHOD ========== */

    /// @notice Deposit & Lock Token
    /// @dev User needs to approve the contract to transfer the token
    /// @param _depositor The depositor address
    /// @param _token Token to stake
    /// @param _lock Whether to lock the token
    /// @param _stake Whether to stake the token
    /// @param _user User to deposit for
    function deposit(
        address _depositor,
        address _token,
        bool _lock,
        bool _stake,
        address _user
    ) external {
        IERC20 stakingAsset = IERC20(_token);
        uint256 stakeAmount = stakingAsset.balanceOf(address(this));
        stakingAsset.safeApprove(_depositor, stakeAmount);
        ICrvDepositor(_depositor).deposit(stakeAmount, _lock, _stake, _user);
        stakingAsset.safeApprove(_depositor, 0);
    }
}
