// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";

/**
 * @title P33rEscrowV1
 * @author Jasper Gabriel
 * @dev P33R escrow contract; handles deposits, withdrawals, and refunds.
 * @notice This version is intended as a MVP. Originally derived from OpenZeppelin.
 *
 * OpenZeppelin Intended usage: This contract (and derived escrow contracts) should be a
 * standalone contract, that only interacts with the contract that instantiated
 * it. That way, it is guaranteed that all Ether will be handled according to
 * the `Escrow` rules, and there is no need to check for payable functions or
 * transfers in the inheritance tree. The contract that uses the escrow as its
 * payment method should be its owner, and provide public methods redirecting
 * to the escrow's deposit and withdraw.
 */
contract P33rEscrowV1 is Ownable, ReentrancyGuard {
    // REVIEW: Set maximum limit (shouldn't exceed 100%) and check computations
    uint256 public immutable _fee;

    // For future consideration: add _transactionsOf?
    mapping(bytes32 => Transaction) public _transactions;

    // ERC20 fee balance
    mapping(address => uint256) public _feeBalance;

    // REVIEW: "packing structs"
    struct Transaction {
        address depositor;
        address token;
        uint256 amount;
        uint256 timestamp;
        TransactionStatus status;
    }

    enum TransactionStatus {
        PENDING,
        SUCCESS,
        FAILED,
        WITHDRAWN,
        REFUNDED
    }

    event Deposited(
        bytes32 indexed referenceId,
        address indexed depositor,
        address token,
        uint256 amount,
        TransactionStatus status
    );

    event Withdrawn(
        bytes32 indexed referenceId,
        address indexed recipient,
        address token,
        uint256 amount,
        TransactionStatus status
    );

    event Refunded(
        bytes32 indexed referenceId,
        address indexed depositor,
        address token,
        uint256 amount,
        TransactionStatus status
    );

    event WithdrawnFee(
        address indexed recipient,
        address token,
        uint256 amount
    );

    event TransactionStatusUpdated(
        bytes32 indexed referenceId,
        TransactionStatus status
    );

    event Fallback(address indexed depositor, uint256 amount);

    error InvalidAmount();
    error NotExpired();

    /**
     * @dev Invalid transaction status. Current transaction status is `current`,
     * but required status to be `required`.
     *
     * @param current current status of transaction.
     * @param required required status of transaction.
     */
    error InvalidTransactionStatus(
        TransactionStatus current,
        TransactionStatus required
    );

    constructor(uint256 fee) {
        _fee = fee;
    }

    /**
     * @dev Deposits the sent token amount and creates a transaction.
     *
     * @param referenceId The reference id of the transaction.
     * @param depositor The source address of the funds.
     * @param token The address of specified ERC20 token.
     * @param amount The amount of specified ERC20 token in wei.
     *
     * Emits a {Deposited} event.
     */
    function deposit(
        bytes32 referenceId,
        address depositor,
        address token,
        uint256 amount
    ) external onlyOwner nonReentrant {
        if (amount == 0) revert InvalidAmount();

        _transactions[referenceId] = Transaction(
            depositor,
            token,
            amount,
            block.timestamp,
            TransactionStatus.PENDING
        );

        IERC20(token).transferFrom(depositor, address(this), amount);

        emit Deposited(
            referenceId,
            depositor,
            token,
            amount,
            TransactionStatus.PENDING
        );
    }

    /**
     * @dev Withdraws transaction token amount for a recipient, forwarding all gas to the
     * recipient.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param referenceId The reference id of the transaction.
     * @param recipient The address whose funds will be withdrawn and transferred to.
     *
     * Emits a {Withdrawn} event.
     */
    function withdraw(
        bytes32 referenceId,
        address recipient
    ) external onlyOwner nonReentrant {
        Transaction storage transaction = _transactions[referenceId];

        if (transaction.status != TransactionStatus.SUCCESS)
            revert InvalidTransactionStatus(
                transaction.status,
                TransactionStatus.SUCCESS
            );

        // Withdraw depositor balance minus fees
        uint256 fee = (transaction.amount * _fee) / 100;
        uint256 withdrawnAmount = transaction.amount - fee;
        address token = transaction.token;

        _feeBalance[token] += fee;
        transaction.amount = 0;
        updateTransactionStatus(referenceId, TransactionStatus.WITHDRAWN);

        IERC20(token).transfer(recipient, withdrawnAmount);

        emit Withdrawn(
            referenceId,
            recipient,
            token,
            withdrawnAmount,
            TransactionStatus.WITHDRAWN
        );
    }

    /**
     * @dev Refund transaction token amount for depositor.
     *
     * @param referenceId The reference id of the transaction.
     *
     * Emits a {Refunded} event.
     */
    function refund(bytes32 referenceId) external onlyOwner nonReentrant {
        Transaction storage transaction = _transactions[referenceId];

        if (transaction.status != TransactionStatus.FAILED)
            revert InvalidTransactionStatus(
                transaction.status,
                TransactionStatus.FAILED
            );

        address depositor = transaction.depositor;
        address token = transaction.token;
        uint256 refundedAmount = transaction.amount;

        transaction.amount = 0;
        updateTransactionStatus(referenceId, TransactionStatus.REFUNDED);

        IERC20(token).transfer(depositor, refundedAmount);

        emit Refunded(
            referenceId,
            depositor,
            token,
            refundedAmount,
            TransactionStatus.REFUNDED
        );
    }

    /**
     * @dev Refund transaction token amount for depositor after 24 hrs.
     *
     * @param referenceId The reference id of the transaction.
     *
     * Emits a {Refunded} event.
     */
    function refundAfterExpiry(bytes32 referenceId) external nonReentrant {
        Transaction storage transaction = _transactions[referenceId];

        // revert if transaction is not yet expired
        // expiry is 1 day after creation
        if (block.timestamp < transaction.timestamp + 1 days) {
            revert NotExpired();
        }
        // revert if transaction is not stuck at pending
        if (transaction.status != TransactionStatus.PENDING)
            revert InvalidTransactionStatus(
                transaction.status,
                TransactionStatus.PENDING
            );

        address depositor = transaction.depositor;
        address token = transaction.token;
        uint256 refundedAmount = transaction.amount;

        transaction.amount = 0;
        transaction.status = TransactionStatus.REFUNDED;

        IERC20(token).transfer(depositor, refundedAmount);

        emit Refunded(
            referenceId,
            depositor,
            token,
            refundedAmount,
            TransactionStatus.REFUNDED
        );
    }

    /**
     * @dev Withdraws accumulated fee for a token.
     *
     * @param recipient The source address of the funds.
     * @param token The address of specified ERC20 token.
     *
     * Emits a {WithdrawnFee} event.
     */
    function withdrawFee(
        address recipient,
        address token
    ) external onlyOwner nonReentrant {
        uint256 amount = _feeBalance[token];

        _feeBalance[token] = 0;

        IERC20(token).transfer(recipient, amount);

        emit WithdrawnFee(recipient, token, amount);
    }

    /**
     * @dev Updates status of transaction.
     *
     * @param referenceId The reference id of the transaction.
     * @param status The status of the transaction.
     *
     * Emits a {TransactionStatusUpdated} event.
     */
    function updateTransactionStatus(
        bytes32 referenceId,
        TransactionStatus status
    ) public onlyOwner {
        _transactions[referenceId].status = status;

        emit TransactionStatusUpdated(referenceId, status);
    }

    // REVIEW: consider fallback functions and ways to rescue unintended ERC20 transfers...
}
