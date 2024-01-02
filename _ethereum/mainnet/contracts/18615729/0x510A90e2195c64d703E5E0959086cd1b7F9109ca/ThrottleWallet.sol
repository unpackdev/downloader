// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./IERC20.sol";
import "./SafeERC20.sol";

contract ThrottleWallet {
    using SafeERC20 for IERC20;

    /**
     * @notice Data Structures
     */

    /**
     * @notice Withdrawal Statuses
     */
    enum WithdrawalStatus {
        Pending,
        Completed,
        Cancelled
    }

    /**
     * @notice Withdrawal Request struct
     * @param amount The amount of tokens to be withdrawn
     * @param target The address of the recipient
     * @param unlockTime The time at which the withdrawal can be completed
     * @param status The status of the withdrawal
     */
    struct WithdrawalRequest {
        uint256 amount;
        address target;
        uint256 unlockTime;
        WithdrawalStatus status;
    }

    /**
     * @notice Events
     */

    /**
     * @notice Emitted when a withdrawal is initiated.
     * @param nonce The nonce of the withdrawal
     * @param to The address of the recipient
     * @param amount The amount of tokens to be withdrawn
     * @param unlockTime The time at which the withdrawal can be completed
     */
    event WithdrawalInitiated(uint256 indexed nonce, address indexed to, uint256 amount, uint256 unlockTime);

    /**
     * @notice Emitted when a withdrawal is completed.
     * @param nonce The nonce of the withdrawal
     */
    event WithdrawalCompleted(uint256 indexed nonce);

    /**
     * @notice Emitted when a withdrawal is cancelled.
     * @param nonce The nonce of the withdrawal
     */
    event WithdrawalCancelled(uint256 indexed nonce);

    /**
     * @notice Emitted when the user role is changed.
     * @param previousUser The address of the previous user
     * @param newUser The address of the new user
     */
    event UserChanged(address indexed previousUser, address indexed newUser);

    /**
     * @notice Emitted when the admin role is changed.
     * @param previousAdmin The address of the previous admin
     * @param newAdmin The address of the new admin
     */
    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);

    /**
     * @notice Parameters
     * @dev Intentionally hardcoded
     */
    IERC20 public constant throttledToken = IERC20(0x320623b8E4fF03373931769A31Fc52A4E78B5d70); // RSR
    uint256 public constant throttlePeriod = 4 weeks;
    uint256 public constant amountPerPeriod = 1_000_000_000 * (10 ** 18); // (at most) 1B every 4 weeks, throttled
    uint256 public constant timelockDuration = 4 weeks;

    /**
     * @notice State
     */

    /**
     * @notice Withdrawal nonce
     */
    uint256 public nextNonce;

    /**
     * @notice Nonce to withdrawal request mapping
     */
    mapping(uint256 nonce => WithdrawalRequest request) public withdrawalRequests;

    /**
     * @notice Last withdrawal timestamp {s}
     */
    uint256 public lastWithdrawalAt;

    /**
     * @notice Last remaining limit {qRSR}
     */
    uint256 public lastRemainingLimit;

    /**
     * @notice Total pending withdrawals {qRSR}
     */
    uint256 public totalPending;

    /**
     * @notice Admin address
     */
    address public admin;

    /**
     * @notice User address
     */
    address public user;

    modifier onlyAdmin() {
        require(msg.sender == admin, "admin only");
        _;
    }

    modifier onlyUser() {
        require(msg.sender == user, "user only");
        _;
    }

    constructor(address _admin, address _user) {
        require(_admin != address(0), "admin must be set");
        require(_user != address(0), "user must be set");

        admin = _admin;
        user = _user;

        emit AdminChanged(address(0), _admin);
        emit UserChanged(address(0), _user);
    }

    /**
     * @notice Helper function to calculate the maximum amount available to withdraw (subject to timelock)
     * @return accumulatedWithdrawalAmount The maximum amount available to withdraw
     */
    function availableToWithdraw() public view returns (uint256) {
        uint256 timeSinceLastWithdrawal = block.timestamp - lastWithdrawalAt;
        uint256 accumulatedWithdrawalAmount = ((timeSinceLastWithdrawal * amountPerPeriod) / throttlePeriod) +
            lastRemainingLimit;

        if (accumulatedWithdrawalAmount > amountPerPeriod) {
            accumulatedWithdrawalAmount = amountPerPeriod;
        }

        uint256 availableBalance = throttledToken.balanceOf(address(this)) - totalPending;
        if (accumulatedWithdrawalAmount > availableBalance) {
            accumulatedWithdrawalAmount = availableBalance;
        }

        return accumulatedWithdrawalAmount;
    }

    /**
     * @notice Initiate Withdrawal with a specific amount and target.
     *         The amount is immediately blocked but can only be withdrawn
     *         after the timelock period has passed.
     * @param amount The amount of tokens to be withdrawn
     * @param target The address of the recipient
     * @return nonce The nonce of the withdrawal
     */
    function initiateWithdrawal(uint256 amount, address target) external onlyUser returns (uint256) {
        require(amount != 0, "amount must be greater than 0");
        require(target != address(0), "target cannot be 0x0");
        require(throttledToken.balanceOf(address(this)) >= totalPending + amount, "insufficient funds");

        uint256 accumulatedWithdrawalAmount = availableToWithdraw();

        require(amount <= accumulatedWithdrawalAmount, "amount must be <= max");

        lastWithdrawalAt = block.timestamp;
        lastRemainingLimit = accumulatedWithdrawalAmount - amount;

        uint256 _nonce = nextNonce++;
        withdrawalRequests[_nonce] = WithdrawalRequest({
            amount: amount,
            target: target,
            unlockTime: block.timestamp + timelockDuration,
            status: WithdrawalStatus.Pending
        });
        totalPending += amount;

        emit WithdrawalInitiated(_nonce, target, amount, block.timestamp + timelockDuration);

        return _nonce;
    }

    /**
     * @notice Allows completing a withdrawal after the timelock period has passed.
     *         Completing a withdrawal is permissionless.
     * @dev Does not impact the throttle.
     * @param _nonce The nonce of the withdrawal
     */
    function completeWithdrawal(uint256 _nonce) external {
        require(_nonce < nextNonce, "invalid nonce");

        WithdrawalRequest storage withdrawal = withdrawalRequests[_nonce];

        assert(withdrawal.amount != 0);
        require(withdrawal.unlockTime <= block.timestamp, "withdrawal is still locked");
        require(withdrawal.status == WithdrawalStatus.Pending, "withdrawal is not pending");

        totalPending -= withdrawal.amount;
        withdrawal.status = WithdrawalStatus.Completed;

        throttledToken.safeTransfer(withdrawal.target, withdrawal.amount);

        emit WithdrawalCompleted(_nonce);
    }

    /**
     * @notice Allows cancelling a withdrawal if it has not been completed already.
     *         Only the admin can cancel a withdrawal.
     * @dev The throttle is NOT recharged on cancellation.
     * @param _nonce The nonce of the withdrawal
     */
    function cancelWithdrawal(uint256 _nonce) external onlyAdmin {
        require(_nonce < nextNonce, "invalid nonce");

        WithdrawalRequest storage withdrawal = withdrawalRequests[_nonce];

        require(withdrawal.status == WithdrawalStatus.Pending, "withdrawal is not pending");

        totalPending -= withdrawal.amount;
        withdrawal.status = WithdrawalStatus.Cancelled;

        emit WithdrawalCancelled(_nonce);
    }

    /**
     * @notice Access Control: onlyAdmin
     * @dev Admin can change user role.
     * @param _newUser New user address
     */
    function changeUser(address _newUser) external onlyAdmin {
        require(_newUser != user, "new user can not be the same");

        emit UserChanged(user, _newUser);
        user = _newUser;
    }

    /**
     * @notice Access Control: onlyAdmin
     * @dev Admin role can NOT be changed (only renounced).
     */
    function renounceAdmin() external onlyAdmin {
        emit AdminChanged(admin, address(0));

        admin = address(0);
    }

    /**
     * @notice Rescue funds from contract
     * @dev Disallows rescuing throttled token, pass 0x0 as _token to rescue ETH.
     *      Intentionally uses `transfer` instead of `call` for ETH
     * @param _token The address of the token to be rescued
     */
    function rescueFunds(address _token) external {
        require(_token != address(throttledToken), "cannot rescue throttled token");

        address recipient = admin == address(0) ? user : admin;

        if (_token == address(0)) {
            payable(recipient).transfer(address(this).balance);
        } else {
            IERC20(_token).safeTransfer(recipient, IERC20(_token).balanceOf(address(this)));
        }
    }
}
