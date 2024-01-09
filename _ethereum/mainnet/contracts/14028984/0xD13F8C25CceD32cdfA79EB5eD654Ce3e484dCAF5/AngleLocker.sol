// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Address.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./IVeANGLE.sol";
import "./IFeeDistributor.sol";
import "./IAngleGaugeController.sol";

/// @title AngleLocker
/// @author StakeDAO
/// @notice Locks the ANGLE tokens to veANGLE contract
contract AngleLocker {
	using SafeERC20 for IERC20;
	using Address for address;

	/* ========== STATE VARIABLES ========== */
	address public governance;
	address public angleDepositor;
	address public accumulator;

	address public constant angle = address(0x31429d1856aD1377A8A0079410B297e1a9e214c2);
	address public constant veAngle = address(0x0C462Dbb9EC8cD1630f1728B2CFD2769d09f0dd5);
	address public feeDistributor = address(0x7F82ff050128e29Fd89D85d01b93246F744E62A0);
	address public gaugeController = address(0x9aD7e7b0877582E14c17702EecF49018DD6f2367);

	/* ========== EVENTS ========== */
	event LockCreated(address indexed user, uint256 value, uint256 duration);
	event TokenClaimed(address indexed user, uint256 value);
	event Voted(uint256 _voteId, address indexed _votingAddress, bool _support);
	event VotedOnGaugeWeight(address indexed _gauge, uint256 _weight);
	event Released(address indexed user, uint256 value);
	event GovernanceChanged(address indexed newGovernance);
	event AngleDepositorChanged(address indexed newAngleDepositor);
	event AccumulatorChanged(address indexed newAccumulator);
	event FeeDistributorChanged(address indexed newFeeDistributor);
	event GaugeControllerChanged(address indexed newGaugeController);

	/* ========== CONSTRUCTOR ========== */
	constructor(address _accumulator) {
		governance = msg.sender;
		accumulator = _accumulator;
		IERC20(angle).approve(veAngle, type(uint256).max);
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
		require(msg.sender == governance || msg.sender == angleDepositor, "!(gov||proxy||AngleDepositor)");
		_;
	}

	/* ========== MUTATIVE FUNCTIONS ========== */
	/// @notice Creates a lock by locking ANGLE token in the veAngle contract for the specified time
	/// @dev Can only be called by governance or proxy
	/// @param _value The amount of token to be locked
	/// @param _unlockTime The duration for which the token is to be locked
	function createLock(uint256 _value, uint256 _unlockTime) external onlyGovernanceOrDepositor {
		IVeANGLE(veAngle).create_lock(_value, _unlockTime);
		emit LockCreated(msg.sender, _value, _unlockTime);
	}

	/// @notice Increases the amount of ANGLE locked in veANGLE
	/// @dev The ANGLE needs to be transferred to this contract before calling
	/// @param _value The amount by which the lock amount is to be increased
	function increaseAmount(uint256 _value) external onlyGovernanceOrDepositor {
		IVeANGLE(veAngle).increase_amount(_value);
	}

	/// @notice Increases the duration for which ANGLE is locked in veANGLE for the user calling the function
	/// @param _unlockTime The duration in seconds for which the token is to be locked
	function increaseUnlockTime(uint256 _unlockTime) external onlyGovernanceOrDepositor {
		IVeANGLE(veAngle).increase_unlock_time(_unlockTime);
	}

	/// @notice Claim the token reward from the ANGLE fee Distributor passing the token as input parameter
	/// @param _recipient The address which will receive the claimed token reward
	function claimRewards(address _token, address _recipient) external onlyGovernanceOrAcc {
		uint256 claimed = IFeeDistributor(feeDistributor).claim();
		emit TokenClaimed(_recipient, claimed);
		IERC20(_token).safeTransfer(_recipient, claimed);
	}

	/// @notice Withdraw the ANGLE from veANGLE
	/// @dev call only after lock time expires
	/// @param _recipient The address which will receive the released ANGLE
	function release(address _recipient) external onlyGovernanceOrDepositor {
		IVeANGLE(veAngle).withdraw();
		uint256 balance = IERC20(angle).balanceOf(address(this));

		IERC20(angle).safeTransfer(_recipient, balance);
		emit Released(_recipient, balance);
	}

	/// @notice Vote on Angle Gauge Controller for a gauge with a given weight
	/// @param _gauge The gauge address to vote for
	/// @param _weight The weight with which to vote
	function voteGaugeWeight(address _gauge, uint256 _weight) external onlyGovernance {
		IAngleGaugeController(gaugeController).vote_for_gauge_weights(_gauge, _weight);
		emit VotedOnGaugeWeight(_gauge, _weight);
	}

	function setGovernance(address _governance) external onlyGovernance {
		governance = _governance;
		emit GovernanceChanged(_governance);
	}

	function setAngleDepositor(address _angleDepositor) external onlyGovernance {
		angleDepositor = _angleDepositor;
		emit AngleDepositorChanged(_angleDepositor);
	}

	function setFeeDistributor(address _newYD) external onlyGovernance {
		feeDistributor = _newYD;
		emit FeeDistributorChanged(_newYD);
	}

	function setGaugeController(address _gaugeController) external onlyGovernance {
		gaugeController = _gaugeController;
		emit GaugeControllerChanged(_gaugeController);
	}

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
	) external onlyGovernanceOrDepositor returns (bool, bytes memory) {
		(bool success, bytes memory result) = to.call{ value: value }(data);
		return (success, result);
	}
}
