// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import "./IERC20.sol";
import "./SafeERC20.sol";

/*
    OtcEscrowApprovals.sol is a fork of:
    https://github.com/fei-protocol/fei-protocol-core/blob/339b2f71e9fda31df628d5e17dd3e4482c91d088/contracts/utils/OtcEscrow.sol

    It uses only ERC20 approvals, without transfering any tokens to this contract as part of the swap.
    It assumes both parties have approved it to spend the appropriate amounts ahead of calling swap().

    To revoke the swap, any party can remove the approval granted to this contract and the swap will fail.
*/
contract OtcEscrowApprovals {
    using SafeERC20 for IERC20;

    address public constant BALANCER_TREASURY = 0x10A19e7eE7d7F8a52822f6817de8ea18204F2e4f;
    address public constant AAVE_ECOSYSTEM_RESERVE = 0x25F2226B597E8F9514B3F68F00f494cF4f286491;
    address public constant AAVE_MAINNET_RESERVE_FACTOR = 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c;

    IERC20 public constant BAL = IERC20(0xba100000625a3754423978a60c9317c58a424e3D);
    IERC20 public constant AAVE = IERC20(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9);

    uint256 public constant BAL_AMOUNT = 200000e18;
    uint256 public constant AAVE_AMOUNT = 1690728e16;

    bool public hasSwapOccured;

    event Swap(uint256 balAmount, uint256 aaveAmount);

    error SwapAlreadyOccured();

    /// @dev Atomically trade specified amounts of BAL token and AAVE token
    /// @dev Anyone may execute the swap if sufficient token approvals are given by both parties
    function swap() external {
        // Check in case of infinite approvals and prevent a second swap
        if (hasSwapOccured) revert SwapAlreadyOccured();
        hasSwapOccured = true;

        // Transfer expected receivedToken from beneficiary
        BAL.safeTransferFrom(BALANCER_TREASURY, AAVE_MAINNET_RESERVE_FACTOR, BAL_AMOUNT);

        // Transfer sentToken to beneficiary
        AAVE.safeTransferFrom(AAVE_ECOSYSTEM_RESERVE, BALANCER_TREASURY, AAVE_AMOUNT);

        emit Swap(BAL_AMOUNT, AAVE_AMOUNT);
    }
}
