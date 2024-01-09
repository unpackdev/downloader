// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC20.sol";
import "./IERC20.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./Context.sol";
import "./ITokenMinter.sol";
import "./ILocker.sol";
import "./ISdToken.sol";

/// @title Contract that accepts tokens and locks them
/// @author StakeDAO
contract Depositor {
	using SafeERC20 for IERC20;
	using Address for address;

	/* ========== STATE VARIABLES ========== */
	address public token;
	uint256 private constant MAXTIME = 4 * 364 * 86400;
	uint256 private constant WEEK = 7 * 86400;

	uint256 public lockIncentive = 10; //incentive to users who spend gas to lock token
	uint256 public constant FEE_DENOMINATOR = 10000;

	address public governance;
	address public immutable locker;
	address public immutable minter;
	uint256 public incentiveToken = 0;
	uint256 public unlockTime;
	bool public relock = true;

	/* ========== EVENTS ========== */
	event Deposited(address indexed user, uint256 indexed amount, bool lock);
	event IncentiveReceived(address indexed user, uint256 indexed amount);
	event TokenLocked(address indexed user, uint256 indexed amount);
	event DepositedFor(address indexed user, uint256 indexed amount);
	event GovernanceChanged(address indexed newGovernance);
	event SdTokenOperatorChanged(address indexed newSdToken);
	event FeesChanged(uint256 newFee);

	/* ========== CONSTRUCTOR ========== */
	constructor(
		address _token,
		address _locker,
		address _minter
	) {
		governance = msg.sender;
		token = _token;
		locker = _locker;
		minter = _minter;
	}

	/* ========== RESTRICTED FUNCTIONS ========== */
	function setGovernance(address _governance) external {
		require(msg.sender == governance, "!auth");
		governance = _governance;
		emit GovernanceChanged(_governance);
	}

	function setSdTokenOperator(address _operator) external {
		require(msg.sender == governance, "!auth");
		ISdToken(minter).setOperator(_operator);
		emit SdTokenOperatorChanged(_operator);
	}

	function setRelock(bool _relock) external {
		require(msg.sender == governance, "!auth");
		relock = _relock;
	}

	function setFees(uint256 _lockIncentive) external {
		require(msg.sender == governance, "!auth");

		if (_lockIncentive >= 0 && _lockIncentive <= 30) {
			lockIncentive = _lockIncentive;
			emit FeesChanged(_lockIncentive);
		}
	}

	/* ========== MUTATIVE FUNCTIONS ========== */

	/// @notice Locks the tokens held by the contract
	/// @dev The contract must have tokens to lock
	function _lockToken() internal {
		uint256 tokenBalance = IERC20(token).balanceOf(address(this));

		// If there is Token available in the contract transfer it to the locker
		if (tokenBalance > 0) {
			IERC20(token).safeTransfer(locker, tokenBalance);
			emit TokenLocked(msg.sender, tokenBalance);
		}

		uint256 tokenBalanceStaker = IERC20(token).balanceOf(locker);
		// If the locker has no tokens then return
		if (tokenBalanceStaker == 0) {
			return;
		}

		ILocker(locker).increaseAmount(tokenBalanceStaker);

		if (relock) {
			uint256 unlockAt = block.timestamp + MAXTIME;
			uint256 unlockInWeeks = (unlockAt / WEEK) * WEEK;

			if (unlockInWeeks - unlockTime > 2) {
				ILocker(locker).increaseUnlockTime(unlockAt);
				unlockTime = unlockInWeeks;
			}
		}
	}

	/// @notice Lock tokens held by the contract
	/// @dev The contract must have Token to lock
	function lockToken() external {
		_lockToken();

		// If there is incentive available give it to the user calling lockToken
		if (incentiveToken > 0) {
			ITokenMinter(minter).mint(msg.sender, incentiveToken);
			emit IncentiveReceived(msg.sender, incentiveToken);
			incentiveToken = 0;
		}
	}

	/// @notice Deposit & Lock Token
	/// @dev User needs to approve the contract to transfer the token
	/// @param _amount The amount of token to deposit
	/// @param _lock Whether to lock the token
	function deposit(uint256 _amount, bool _lock) public {
		require(_amount > 0, "!>0");

		// If User chooses to lock Token
		if (_lock) {
			IERC20(token).safeTransferFrom(msg.sender, locker, _amount);
			_lockToken();

			if (incentiveToken > 0) {
				_amount = _amount + incentiveToken;
				emit IncentiveReceived(msg.sender, incentiveToken);
				incentiveToken = 0;
			}
		} else {
			//move tokens here
			IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);
			//defer lock cost to another user
			uint256 callIncentive = (_amount * lockIncentive) / FEE_DENOMINATOR;
			_amount = _amount - callIncentive;
			incentiveToken = incentiveToken + callIncentive;
		}

		ITokenMinter(minter).mint(msg.sender, _amount);

		emit Deposited(msg.sender, _amount, _lock);
	}

	/// @notice Deposits all the token of a user & locks them based on the options choosen
	/// @dev User needs to approve the contract to transfer Token tokens
	/// @param _lock Whether to lock the token
	function depositAll(bool _lock) external {
		uint256 tokenBal = IERC20(token).balanceOf(msg.sender);
		deposit(tokenBal, _lock);
	}
}
