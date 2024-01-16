// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./IVeFXS.sol";
import "./IYieldDistributor.sol";
import "./IFraxGaugeController.sol";

/// @title FxsLocker
/// @author StakeDAO
/// @notice Locks the FXS tokens to veFXS contract
contract FxsLocker {
	using SafeERC20 for IERC20;

	/* ========== STATE VARIABLES ========== */
	address public governance;
	address public fxsDepositor;
	address public accumulator;

	address public constant fxs = address(0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0);
	address public constant veFXS = address(0xc8418aF6358FFddA74e09Ca9CC3Fe03Ca6aDC5b0);
	address public yieldDistributor = address(0xc6764e58b36e26b08Fd1d2AeD4538c02171fA872);
	address public gaugeController = address(0x44ade9AA409B0C29463fF7fcf07c9d3c939166ce);

	/* ========== EVENTS ========== */
	event LockCreated(address indexed user, uint256 value, uint256 duration);
	event FXSClaimed(address indexed user, uint256 value);
	event VotedOnGaugeWeight(address indexed _gauge, uint256 _weight);
	event Released(address indexed user, uint256 value);
	event GovernanceChanged(address indexed newGovernance);
	event FxsDepositorChanged(address indexed newFxsDepositor);
	event AccumulatorChanged(address indexed newAccumulator);
	event YieldDistributorChanged(address indexed newYieldDistributor);
	event GaugeControllerChanged(address indexed newGaugeController);

	/* ========== CONSTRUCTOR ========== */
	constructor(address _accumulator) {
		governance = msg.sender;
		accumulator = _accumulator;
		IERC20(fxs).approve(veFXS, type(uint256).max);
	}

	/* ========== MODIFIERS ========== */
	modifier onlyGovernance() {
		require(msg.sender == governance, "!gov");
		_;
	}

	modifier onlyGovernanceOrAcc() {
		require(msg.sender == governance || msg.sender == accumulator, "!(gov||acc)");
		_;
	}

	modifier onlyGovernanceOrDepositor() {
		require(msg.sender == governance || msg.sender == fxsDepositor, "!(gov||fxsDepositor)");
		_;
	}

	/* ========== MUTATIVE FUNCTIONS ========== */
	/// @notice Creates a lock by locking FXS token in the veFXS contract for the specified time
	/// @dev Can only be called by governance
	/// @param _value The amount of token to be locked
	/// @param _unlockTime The duration for which the token is to be locked
	function createLock(uint256 _value, uint256 _unlockTime) external onlyGovernance {
		IveFXS(veFXS).create_lock(_value, _unlockTime);
		IYieldDistributor(yieldDistributor).checkpoint();
		emit LockCreated(msg.sender, _value, _unlockTime);
	}

	/// @notice Increases the amount of FXS locked in veFXS
	/// @dev The FXS needs to be transferred to this contract before calling
	/// @param _value The amount by which the lock amount is to be increased
	function increaseAmount(uint256 _value) external onlyGovernanceOrDepositor {
		IveFXS(veFXS).increase_amount(_value);
		IYieldDistributor(yieldDistributor).checkpoint();
	}

	/// @notice Increases the duration for which FXS is locked in veFXS for the user calling the function
	/// @param _unlockTime The duration in seconds for which the token is to be locked
	function increaseUnlockTime(uint256 _unlockTime) external onlyGovernanceOrDepositor {
		IveFXS(veFXS).increase_unlock_time(_unlockTime);
		IYieldDistributor(yieldDistributor).checkpoint();
	}

	/// @notice Claim the FXS reward from the FXS Yield Distributor at 0xc6764e58b36e26b08Fd1d2AeD4538c02171fA872
	/// @param _recipient The address which will receive the claimedFXS reward
	function claimFXSRewards(address _recipient) external onlyGovernanceOrAcc {
		IYieldDistributor(yieldDistributor).getYield();
		emit FXSClaimed(_recipient, IERC20(fxs).balanceOf(address(this)));
		IERC20(fxs).safeTransfer(_recipient, IERC20(fxs).balanceOf(address(this)));
	}

	/// @notice Withdraw the FXS from veFXS
	/// @dev call only after lock time expires
	/// @param _recipient The address which will receive the released FXS
	function release(address _recipient) external onlyGovernance {
		IveFXS(veFXS).withdraw();
		uint256 balance = IERC20(fxs).balanceOf(address(this));

		IERC20(fxs).safeTransfer(_recipient, balance);
		emit Released(_recipient, balance);
	}

	/// @notice Vote on Frax Gauge Controller for a gauge with a given weight
	/// @param _gauge The gauge address to vote for
	/// @param _weight The weight with which to vote
	function voteGaugeWeight(address _gauge, uint256 _weight) external onlyGovernance {
		IFraxGaugeController(gaugeController).vote_for_gauge_weights(_gauge, _weight);
		emit VotedOnGaugeWeight(_gauge, _weight);
	}

	/// @notice Set new governance address
	/// @param _governance governance address
	function setGovernance(address _governance) external onlyGovernance {
		governance = _governance;
		emit GovernanceChanged(_governance);
	}

	/// @notice Set the FXS Depositor
	/// @param _fxsDepositor fxs deppositor address
	function setFxsDepositor(address _fxsDepositor) external onlyGovernance {
		fxsDepositor = _fxsDepositor;
		emit FxsDepositorChanged(_fxsDepositor);
	}

	/// @notice Set the yield distributor
	/// @param _newYD yield distributor address
	function setYieldDistributor(address _newYD) external onlyGovernance {
		yieldDistributor = _newYD;
		emit YieldDistributorChanged(_newYD);
	}

	/// @notice Set the gauge controller
	/// @param _gaugeController gauge controller address
	function setGaugeController(address _gaugeController) external onlyGovernance {
		gaugeController = _gaugeController;
		emit GaugeControllerChanged(_gaugeController);
	}

	/// @notice Set the accumulator
	/// @param _accumulator accumulator address
	function setAccumulator(address _accumulator) external onlyGovernance {
		accumulator = _accumulator;
		emit AccumulatorChanged(_accumulator);
	}

	/// @notice execute a function
	/// @param to Address to sent the value to
	/// @param value Value to be sent
	/// @param data Call function data
	function execute(
		address to,
		uint256 value,
		bytes calldata data
	) external onlyGovernance returns (bool, bytes memory) {
		(bool success, bytes memory result) = to.call{ value: value }(data);
		return (success, result);
	}
}
