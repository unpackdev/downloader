// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

/**
 * @title Sale
 * @notice Sale where users deposit ether, and after a vesting period can claim the reward token.
 */
contract Sale is ReentrancyGuard, Pausable, Ownable {
    using SafeERC20 for IERC20;

    /// @notice Duration of sale
    uint256 public immutable DURATION;

    /// @notice address deposited funds are withdrawn to
    address public immutable BENEFICIARY;

    /// @notice token to swap for ether
    IERC20 public immutable REWARD_TOKEN;

    /// @notice IBCO finalization indicator
    bool public finalized = false;

    /// @notice timestamp that the sale begins
    uint256 public startTime = 99999999999;

    /// @notice accumalated deopsits in wei
    uint256 public depositsRaised;

    /// @notice accumalated REWARD_TOKENs claimed in wei
    uint256 public rewardsClaimed;

    /// @notice exchange rate of REWARD_TOKEN to ether
    /// Example:
    ///   let rate=1000, let deposit=2 ether;
    ///   rate*deposit = REWARD_TOKEN_quantity == 1000*2 = 2000 REWARD_TOKENs.
    uint256 public rate;

    /// @notice how much ETH in wei each wallet has deposited
    mapping(address => uint256) public deposits;

    /// @notice how much REWARD_TOKENs in wei each wallet has withdrawn
    mapping(address => uint256) private claimed;

    /// @notice watchdog for startTime
    bool private startTimeLock = false;

    /// @notice timestamp to start allowing claiming
    uint256 private claimTime = 99999999999;

    /**
     * @notice Indicates a deposit was made
     * @param account who deposited
     * @param amount amount deposited
     */
    event Deposit(address indexed account, uint256 amount);

    /**
     * @notice Indicates a claim was made
     * @param account who claimed
     * @param amount reward token amount claimed
     */
    event Claim(address indexed account, uint256 amount);

    /**
     * @notice Event for IBCO finalization
     * @dev Will only be called once
     * @param rate_ final reward token rate in REWARD_TOKEN to ether
     * @param time timestamp sale was finalized
     */
    event Finalize(uint256 rate_, uint256 time);

    /**
     * @notice Indicates a deposit was withdrawn
     * @param account who withdrawn their deposit
     * @param amount amount of eth withdrawn
     */
    event WithdrawDeposit(address indexed account, uint256 amount);

    // Errors
    error Unauthorized();

    /// @notice Provided address is invalid
    /// @param _address the invalid address
    error InvalidAddress(address _address);

    /// @notice Provided amount is invalid
    /// @param amount the invalid amount
    error InvalidAmount(uint256 amount);

    /// @notice Call is locked by watchdog
    error Locked();

    /// @notice Sale is not ended
    error NotEnded();

    /// @notice Sale is not started
    error NotStarted();

    /// @notice Claim time is not reached
    error NotClaimTime();

    /// @notice Sale is ended
    error Ended();

    /// @notice Transfer of ether or token has failed
    /// @param amount requested amount to transfer.
    error TransferFailure(uint256 amount);

    /// @notice Insufficient balance for transfer
    error InsufficientBalance();

    /// @notice IBCO not finalized
    error NotFinalized();

    /// @notice IBCO finalized
    error Finalized();

    constructor(
        uint256 _duration,
        address _beneficiary,
        address _rewardToken
    ) {
        DURATION = _duration;
        BENEFICIARY = _beneficiary;
        REWARD_TOKEN = IERC20(_rewardToken);
    }

    /*******************************************/
    /* external                                */
    /*******************************************/
    /**
     * @notice Public wrapper for #_deposit()
     */
    function deposit() external payable virtual {
        _deposit();
    }

    /**
     * @notice Withdraw eth you previously deposited
     * @param amount amount to withdraw from your deposits
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     */
    function withdrawDeposit(uint256 amount) external nonReentrant {
        _preValidateWithdrawDeposit(msg.sender, amount);
        _updateWithdrawDepositState(msg.sender, amount);

        // Send eth to msg.sender
        // This forwards all available gas
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) revert TransferFailure(amount);

        emit WithdrawDeposit(msg.sender, amount);
    }

    /**
     * @dev This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @notice Send the claimableRewardBalanceOf(msg.sender) to msg.sender
     */
    function claim() external nonReentrant {
        uint256 claimableBalance = claimableRewardBalanceOf(msg.sender);

        _preValidateClaim(msg.sender, claimableBalance);

        _updateClaimState(msg.sender, claimableBalance);

        // Transfer reward tokens
        REWARD_TOKEN.safeTransfer(msg.sender, claimableBalance);

        emit Claim(msg.sender, claimableBalance);
    }

    /**
     * @notice Computes the current amount of unclaimable tokens for a given user.
     * @param wallet Wallet address to check balance of
     * @return Number of tokens the supplied address cannot currently withdraw
     */
    function unclaimableRewardBalanceOf(address wallet) external view virtual returns (uint256) {
        if (block.timestamp > claimTime) {
            return 0;
        }

        return (deposits[wallet] * rate) - claimed[wallet];
    }

    /**
     * @notice Finalize IBCO. Can only be called once, and can be called by anyone.
     */
    function finalize() external {
        if (finalized) revert Locked();
        if (block.timestamp < startTime + DURATION) revert NotEnded();

        /// @notice Calculate the final token rate in REWARD_TOKEN to ether
        rate = REWARD_TOKEN.balanceOf(address(this)) / depositsRaised;

        // Set finalization lock
        finalized = true;

        emit Finalize(rate, block.timestamp);
    }

    /*******************************************/
    /* external onlyOwner                      */
    /*******************************************/
    /**
     * @notice Set startTime
     * @param _timestamp timestamp to start sale at
     */
    function setStartTime(uint256 _timestamp) external onlyOwner {
        if (startTimeLock) revert Locked();
        startTime = _timestamp;
    }

    /**
     * @notice Lock startTime from being changed
     */
    function lockStartTime() external onlyOwner {
        if (startTimeLock) revert Locked();
        startTimeLock = true;
    }

    /**
     * @notice Set claimTime
     * @param _timestamp timestamp to start allowing claiming
     */
    function setClaimTime(uint256 _timestamp) external onlyOwner {
        claimTime = _timestamp;
    }

    /**
     * @notice Withdraw funds to BENEFICIARY
     */
    function withdraw() external onlyOwner {
        if (!finalized) revert NotFinalized();

        uint256 bal = address(this).balance;
        if (bal <= 0) revert InsufficientBalance();

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = payable(BENEFICIARY).call{value: bal}("");
        if (!success) revert TransferFailure(bal);
    }

    /**
     * @notice Withdraw the reward tokens that are unclaimed 45 days after `claimTime`.
     */
    // TODO: maybe remove, or make more than 45 days
    function withdrawUnclaimedRewardTokens() external onlyOwner {
        uint256 rewardBalance = REWARD_TOKEN.balanceOf(address(this));

        if (block.timestamp <= claimTime + 45 days) revert Unauthorized();
        if (rewardBalance <= 0) revert InsufficientBalance();

        REWARD_TOKEN.safeTransfer(BENEFICIARY, rewardBalance);
    }

    /**
     * @dev Pause vital functions. To be used in an emergency.
     * Used in _preValidateDeposit and _preValidateClaim.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause vital functions.
     * Used in _preValidateDeposit and _preValidateClaim.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /*******************************************/
    /* public                                  */
    /*******************************************/
    /**
     * @notice Computes the current amount of claimable tokens for a given user.
     * Returns 0 if the sale is not yet claimTime.
     * Else, returns (deposits[wallet] * rate) - claimed[wallet].
     * @param wallet Wallet address to check balance of
     * @return Number of tokens the supplied address can currently withdraw
     */
    function claimableRewardBalanceOf(address wallet) public view virtual returns (uint256) {
        if (block.timestamp <= claimTime) {
            return 0;
        }

        return (deposits[wallet] * rate) - claimed[wallet];
    }

    /*******************************************/
    /* internal                                */
    /*******************************************/
    /**
     * @notice Deposit eth into the IBCO
     * @dev Must be wrapped by and public/external function.
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     */
    function _deposit() internal virtual nonReentrant {
        _preValidateDeposit(msg.sender, msg.value);

        _updateDepositState(msg.sender, msg.value);

        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @dev Validate incoming deposit.
     * @param _depositor Address performing the deposit
     * @param _depositAmount Value in wei involved in the deposit
     */
    function _preValidateDeposit(address _depositor, uint256 _depositAmount)
        internal
        view
        virtual
        whenNotPaused
    {
        if (_depositor == address(0)) revert InvalidAddress(_depositor);
        if (_depositAmount <= 0) revert InvalidAmount(_depositAmount);
        if (block.timestamp < startTime) revert NotStarted();
        if (block.timestamp > startTime + DURATION) revert Ended();

        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

    /**
     * @dev State updates for an incoming deposit.
     * @param _depositor Address depositing ether
     * @param _depositAmount Value in wei involved in the deposit
     */
    function _updateDepositState(address _depositor, uint256 _depositAmount) internal {
        depositsRaised = depositsRaised + _depositAmount;
        deposits[_depositor] = deposits[_depositor] + _depositAmount;
    }

    /**
     * @dev Validate incoming withdrawal of deposits.
     * @param _withdrawer Address performing the withdrawDeposit
     * @param _withdrawAmount Value in wei involved in the withdrawDeposit
     */
    function _preValidateWithdrawDeposit(address _withdrawer, uint256 _withdrawAmount)
        internal
        view
        virtual
        whenNotPaused
    {
        if (_withdrawer == address(0)) revert InvalidAddress(_withdrawer);
        if (_withdrawAmount <= 0) revert InvalidAmount(_withdrawAmount);
        if (finalized) revert Finalized();
        if (block.timestamp < startTime) revert NotStarted();
        if (block.timestamp > startTime + DURATION) revert Ended();
        if (address(this).balance == 0) revert InsufficientBalance();
        if (_withdrawAmount > deposits[_withdrawer]) revert InsufficientBalance();

        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

    /**
     * @dev State updates for a withdrawal of deposits.
     * @param _depositor Address performing the withdrawDeposit
     * @param _withdrawAmount Value in wei involved in the withdrawDeposit
     */
    function _updateWithdrawDepositState(address _depositor, uint256 _withdrawAmount) internal {
        depositsRaised = depositsRaised - _withdrawAmount;
        deposits[_depositor] = deposits[_depositor] - _withdrawAmount;
    }

    /**
     * @dev Validate incoming claim.
     * @param claimer Address performing the claim
     * @param claimAmount Value in wei involved in the claim
     */
    function _preValidateClaim(address claimer, uint256 claimAmount)
        internal
        view
        virtual
        whenNotPaused
    {
        if (!finalized) revert NotFinalized();
        if (claimer == address(0)) revert InvalidAddress(claimer);
        if (block.timestamp < claimTime) revert NotClaimTime();
        if (claimAmount <= 0) revert InsufficientBalance();

        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

    /**
     * @dev State updates for an incoming claim.
     * @param claimer Address claiming
     * @param claimAmount Value in wei involved in the deposit
     */
    function _updateClaimState(address claimer, uint256 claimAmount) internal {
        // Add to rewardsClaimed total tracker
        rewardsClaimed = rewardsClaimed + claimAmount;

        // Update claimed amount for claimer
        claimed[claimer] = claimed[claimer] + claimAmount;
    }
}
