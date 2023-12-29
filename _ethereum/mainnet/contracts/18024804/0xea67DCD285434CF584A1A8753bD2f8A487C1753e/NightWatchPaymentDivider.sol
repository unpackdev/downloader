// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./SafeTransferLib.sol";
import "./ReentrancyGuard.sol";
import "./ERC20.sol";

/// @title Night Watch Payment Divider
/// @notice Night Watch Payment Divider contract
/// @author @YigitDuman
contract NightWatchPaymentDivider is ReentrancyGuard {
    error NoFunds();
    error NoZeroAddress();

    // Partner A and B addresses.
    address private immutable _partnerA;
    address private immutable _partnerB;

    constructor(address partnerA, address partnerB) {
        if (partnerA == address(0) || partnerB == address(0)) {
            revert NoZeroAddress();
        }

        _partnerA = partnerA;
        _partnerB = partnerB;
    }

    /*//////////////////////////////////////////////////////////////
                                WITHDRAW
    //////////////////////////////////////////////////////////////*/

    /// @notice Withdraws the funds from the contract.
    function withdraw(uint256 amount) external {
        uint256 balance = address(this).balance;

        // Revert if there are no funds
        if (balance == 0) {
            revert NoFunds();
        }

        // Limit the amount to the contract balance.
        if (amount > balance) {
            amount = balance;
        }

        // Split the funds between the partners with 65% and 35%.
        uint256 amount65 = (amount * 65) / 100;
        uint256 amount35 = amount - amount65;

        SafeTransferLib.safeTransferETH(_partnerA, amount65);
        SafeTransferLib.safeTransferETH(_partnerB, amount35);
    }

    /// @notice Withdraws the ERC20 funds from the contract.
    function withdrawERC20(uint256 amount, ERC20 token) external nonReentrant {
        uint256 balance = token.balanceOf(address(this));

        // Revert if there are no funds
        if (balance == 0) {
            revert NoFunds();
        }

        // Limit the amount to the contract balance.
        if (amount > balance) {
            amount = balance;
        }

        // Split the funds between the partners with 65% and 35%.
        uint256 amount65 = (amount * 65) / 100;
        uint256 amount35 = amount - amount65;

        token.transfer(_partnerA, amount65);
        token.transfer(_partnerB, amount35);
    }

    /*//////////////////////////////////////////////////////////////
                            PAYMENT FALLBACK
    //////////////////////////////////////////////////////////////*/

    receive() external payable {}

    fallback() external payable {}
}
