// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

// ====================================================================
// ========================== Treasury.sol ============================
// ====================================================================

/**
 * @title Treasury
 * @dev Manages the fees paid to the protocol
 */

import "./Owned.sol";

import "./Address.sol";
import "./TransferHelper.sol";
import "./ReentrancyGuard.sol";

contract Treasury is Owned, ReentrancyGuard {
    // Events
    event SendEther(address to, uint256 amount);
    event SendToken(address token, address to, uint256 amount);

    constructor(address sweepAddress_) Owned(sweepAddress_) {}

    /* ========== Actions ========== */

    /**
     * @notice Receive Eth
     */
    receive() external payable {}

    /**
     * @notice Send Eth
     * @param receiver address
     * @param amount Eth amount
     */
    function sendEther(
        address receiver,
        uint256 amount
    ) external onlyGov nonReentrant {
        uint256 ethBalance = address(this).balance;
        if (amount > ethBalance) amount = ethBalance;

        TransferHelper.safeTransferETH(receiver, amount);

        emit SendEther(receiver, amount);
    }

    /**
     * @notice Recover ERC20 Token
     * @param token address
     * @param receiver address
     * @param amount SWEEP amount
     */
    function sendToken(
        address token,
        address receiver,
        uint256 amount
    ) external onlyGov nonReentrant {
        uint256 tokenBalance = IERC20(token).balanceOf(address(this));
        if (amount > tokenBalance) amount = tokenBalance;

        TransferHelper.safeTransfer(token, receiver, amount);

        emit SendToken(token, receiver, amount);
    }
}
