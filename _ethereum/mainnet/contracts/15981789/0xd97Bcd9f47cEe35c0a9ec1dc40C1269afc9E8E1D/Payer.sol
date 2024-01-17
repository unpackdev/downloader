// SPDX-License-Identifier: GPL-3.0

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.17;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Math.sol";
import "./DebtQueue.sol";
import "./IPayer.sol";

/// @title Payer
/// @notice This is used to pay users from a balance of ERC20 tokens.
/// If there's not enough balance, a debt entry is saved and the debt will be paid when there's balance available
contract Payer is IPayer, Ownable {
    using SafeERC20 for IERC20;
    using DebtQueue for DebtQueue.DebtDeque;

    /**
     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      IMMUTABLES
     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /// @notice The ERC20 token used to pay users
    IERC20 public immutable paymentToken;

    /**
     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      STORAGE VARIABLES
     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /// @notice The total debt owed to users in `paymentToken` tokens
    uint256 public totalDebt;

    /// @notice A queue of debt entries waiting to be paid
    /// @dev The queue is FIFO
    DebtQueue.DebtDeque public queue;

    /**
     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      EVENTS
     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /// @notice Emitted when debt is paid back to the user
    event PaidBackDebt(address indexed account, uint256 amount, uint256 remainingDebt);

    /// @notice Emitted when a new debt entry is added
    event RegisteredDebt(address indexed account, uint256 amount);

    /// @notice Emitted when the contract owner withdraws the `paymentToken` balance
    event TokensWithdrawn(address indexed account, uint256 amount);

    /**
     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      ERRORS
     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    error CastError();

    /**
     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      CONSTRUCTOR
     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /// @param _owner The address of the contract owner, allowed to performed certain operations
    /// @param _paymentToken The address of the ERC20 token used for payments
    constructor(address _owner, address _paymentToken) {
        paymentToken = IERC20(_paymentToken);
        _transferOwnership(_owner);
    }

    /**
     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      EXTERNAL FUNCTIONS (ONLY OWNER)
     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /// @notice Pays a user a certain amount of tokens. Adds a debt entry if there's not enough tokens.
    /// @dev Only the owner is allowed to call this function
    /// @param account The address of the user to be paid
    /// @param amount The maximum amount of tokens to be paid
    function sendOrRegisterDebt(address account, uint256 amount) external onlyOwner {
        uint256 availableBalance = paymentToken.balanceOf(address(this));

        if (amount <= availableBalance) {
            // If there's enough balance to pay in full: send the entire amount
            paymentToken.safeTransfer(account, amount);
        } else if (availableBalance > 0) {
            // If there's some balance, but not enough to pay in full

            // 1. Pay what we can
            paymentToken.safeTransfer(account, availableBalance);

            // 2. Add a debt entry for the remaining amount
            registerDebt(account, amount - availableBalance);
        } else {
            // Zero balance, add a debt entry for the entire amount
            registerDebt(account, amount);
        }
    }

    /// @notice Withdraws the entire balance of `paymentToken` to the owner
    /// @dev Only the owner is allowed to call this function
    function withdrawPaymentToken() external onlyOwner {
        address to = msg.sender; // This is owner() because using `onlyOwner`
        uint256 amount = paymentToken.balanceOf(address(this));
        paymentToken.safeTransfer(to, amount);

        emit TokensWithdrawn(to, amount);
    }

    /**
     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      EXTERNAL FUNCTIONS (ANYONE CAN CALL)
     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /// @notice Pays back debt up to `amount` of `paymentToken`. Debt is paid in FIFO order.
    /// @param amount The maximum amount of tokens to send. This is expected to be the token balance of this contract
    /// @dev Assumes new entries are add to the 'back' of the queue, meaning oldest entries are at the 'front' of the queue
    function payBackDebt(uint256 amount) external {
        uint256 debtPaidBack = 0;

        // While there are tokens left, and debt entries exist
        while (amount > 0 && !queue.empty()) {
            // Get the oldest entry
            DebtQueue.DebtEntry storage debt = queue.front();

            // Cache storage values
            uint96 _debtAmount = debt.amount;
            address _debtAccount = debt.account;

            if (amount < _debtAmount) {
                // Not enough to cover entire debt, pay what you can and leave
                // cast is safe because `amount` < `_debtAmount` (uint96)
                uint96 remainingDebt = _debtAmount - uint96(amount);

                // Update remaining debt in queue
                debt.amount = remainingDebt;

                // Update debt paid back
                debtPaidBack += amount;

                // Pay user what we can
                paymentToken.safeTransfer(_debtAccount, amount);
                emit PaidBackDebt(_debtAccount, amount, remainingDebt);

                // No more tokens, leave
                break;
            } else {
                // Enough to cover entire debt entry, pay in full and remove from queue

                // Update amount of tokens left to pay back debt
                amount -= _debtAmount;

                // Update debt paid back
                debtPaidBack += _debtAmount;

                // Remove entry from queue
                queue.popFront();

                // Pay user the entire amount
                paymentToken.safeTransfer(_debtAccount, _debtAmount);

                emit PaidBackDebt(_debtAccount, _debtAmount, 0);
            }
        }

        // Update totalDebt
        if (debtPaidBack > 0) {
            totalDebt -= debtPaidBack;
        }
    }

    /**
     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      VIEW FUNCTIONS
     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /// @notice Returns the amount of debt owed to `account`
    /// @dev It takes into account there may be more that one debt entry for an account
    /// @param account The address of the account to check
    /// @return amount The amount of tokens the contract owes `account`
    function debtOf(address account) external view returns (uint256 amount) {
        uint256 queueLength = queue.length();
        for (uint256 i; i < queueLength; ++i) {
            DebtQueue.DebtEntry storage debtEntry = queue.at(i);
            if (debtEntry.account == account) {
                amount += debtEntry.amount;
            }
        }
    }

    /// @notice Returns the details of debt entry at index `index` in the queue
    /// @dev Index 0 is front of the queue
    /// @param index The index of the debt entry in the queue
    /// @return account The address of the account owed debt
    /// @return amount The amount of debt owed in `paymentToken` tokens
    function queueAt(uint256 index) external view returns (address account, uint256 amount) {
        DebtQueue.DebtEntry storage debtEntry = queue.at(index);
        return (debtEntry.account, debtEntry.amount);
    }

    /**
     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      INTERNAL FUNCTIONS
     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /// @notice Adds a new debt entry to the queue
    /// @dev Pushes to the back of the queue, to maintain FIFO order
    /// @param account The address of the account owed debt
    /// @param amount The amount of debt owed in `paymentToken` tokens
    function registerDebt(address account, uint256 amount) internal {
        queue.pushBack(DebtQueue.DebtEntry({ account: account, amount: toUint96(amount) }));
        totalDebt += amount;

        emit RegisteredDebt(account, amount);
    }

    /// @notice Safe casting to from uint256 to uint96
    function toUint96(uint256 value) internal pure returns (uint96) {
        if (value > type(uint96).max) revert CastError();
        return uint96(value);
    }
}
