// contracts/TokenVesting.sol
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Math.sol";

import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

/**
 * @title TokenVesting
 */
contract TokenVestingV2 is UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
	using SafeERC20 for IERC20;
	struct VestingSchedule {
		// set to true when schedule is created
		bool initialized;
		// whether or not the vesting is revocable
		bool revocable;
		// whether or not the vesting has been revoked
		bool revoked;
		// beneficiary of tokens after they are released
		address beneficiary;
		// cliff time as unix timestamp
		uint32 cliff;
		// start time of the vesting period
		uint32 start;
		// duration of the vesting period in seconds
		uint32 duration;
		// duration of a slice period for the vesting in seconds
		uint32 slicePeriodSeconds;
		// total amount of tokens to be released at the end of the vesting
		uint128 amountTotal;
		// total amount of tokens to be released at the beginning of the vesting
		uint128 immediatelyReleasableAmount;
		// amount of tokens released
		uint128 released;
	}

	// address of the ERC20 token
	address internal _token;
	address internal _treasury;

	bytes32[] internal vestingSchedulesIds;
	mapping(bytes32 => VestingSchedule) internal vestingSchedules;
	uint256 internal vestingSchedulesTotalAmount;
	mapping(address => uint256) internal holdersVestingCount;

	// events
	event VestingScheduleCreated(address indexed _by, address indexed _beneficiary, bytes32 indexed _vestingScheduleId, VestingSchedule _schedule);
	event Released(address indexed _by, address indexed _to, bytes32 indexed _vestingScheduleId, uint256 _amount);
	event Revoked(address indexed _by, address indexed _beneficiary, bytes32 indexed _vestingScheduleId);
	event TreasuryUpdated(address indexed _by, address indexed _oldVal, address indexed _newVal);

	/**
	* @dev Reverts if no vesting schedule matches the passed identifier.
	*/
	modifier onlyIfVestingScheduleExists(bytes32 vestingScheduleId) {
		require(vestingSchedules[vestingScheduleId].initialized == true);
		_;
	}

	/**
	 * @dev Reverts if the vesting schedule does not exist or has been revoked.
	 */
	modifier onlyIfVestingScheduleNotRevoked(bytes32 vestingScheduleId) {
		require(vestingSchedules[vestingScheduleId].initialized == true);
		require(vestingSchedules[vestingScheduleId].revoked == false);
		_;
	}

	/**
	 * @dev UUPS initializer, initializes a vesting contract
	 *
	 * @param token_ address of the ERC20 token contract, non-zero, immutable
	 * @param treasury_ address of the wallet funding vesting contract, mutable
	 */
	function postConstruct(address token_, address treasury_) public virtual initializer {
		require(token_ != address(0x0));
		// note we don't verify treasury is not zero and allow it to be set up later
		_token = token_;
		_treasury = treasury_;

		__Ownable_init();
		__ReentrancyGuard_init();
	}

	// receive() external payable {}

	// fallback() external payable {}

	/**
	 * @dev Returns the number of vesting schedules associated to a beneficiary.
	 * @return the number of vesting schedules
	 */
	function getVestingSchedulesCountByBeneficiary(address _beneficiary) public view virtual returns (uint256) {
		return holdersVestingCount[_beneficiary];
	}

	/**
	 * @dev Returns the vesting schedule id at the given index.
	 * @return the vesting id
	 */
	function getVestingIdAtIndex(uint256 index) public view virtual returns (bytes32) {
		require(index < getVestingSchedulesCount(), "TokenVesting: index out of bounds");
		return vestingSchedulesIds[index];
	}

	/**
	 * @notice Returns the vesting schedule information for a given holder and index.
	 * @return the vesting schedule structure information
	 */
	function getVestingScheduleByAddressAndIndex(
		address holder,
		uint256 index
	) public view virtual returns (VestingSchedule memory) {
		return getVestingSchedule(computeVestingScheduleIdForAddressAndIndex(holder, index));
	}


	/**
	 * @notice Returns the total amount of vesting schedules.
	 * @return the total amount of vesting schedules
	 */
	function getVestingSchedulesTotalAmount() external view virtual returns (uint256) {
		return vestingSchedulesTotalAmount;
	}

	/**
	 * @dev Returns the address of the ERC20 token managed by the vesting contract.
	 */
	function getToken() public view virtual returns (address) {
		return address(_token);
	}

	/**
	 * @dev Returns the address of the wallet smart contract uses to fund vesting.
	 */
	function getTreasury() public view virtual returns (address) {
		return _treasury;
	}

	/**
	 * @dev Updates the wallet address used by the smart contract to fund vesting.
	 * @param treasury_ wallet address to set to fund vesting
	 */
	function setTreasury(address treasury_) public virtual onlyOwner {
		emit TreasuryUpdated(msg.sender, _treasury, treasury_);
		_treasury = treasury_;
	}

	/**
	 * @notice Creates a new vesting schedule for a beneficiary.
	 * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
	 * @param _start start time of the vesting period
	 * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
	 * @param _duration duration in seconds of the period in which the tokens will vest
	 * @param _slicePeriodSeconds duration of a slice period for the vesting in seconds
	 * @param _revocable whether the vesting is revocable or not
	 * @param _amount total amount of tokens to be released at the end of the vesting
	 * @param _immediatelyReleasableAmount total amount of tokens to be released at the beginning of the vesting
	 */
	function createVestingSchedule(
		address _beneficiary,
		uint32 _start,
		uint32 _cliff,
		uint32 _duration,
		uint32 _slicePeriodSeconds,
		bool _revocable,
		uint128 _amount,
		uint128 _immediatelyReleasableAmount
	) public virtual onlyOwner {
		require(_duration > 0, "TokenVesting: duration must be > 0");
		require(_amount > 0, "TokenVesting: amount must be > 0");
		require(_immediatelyReleasableAmount <= _amount, "TokenVesting: immediatelyReleasableAmount must be <= amount");
		require(_slicePeriodSeconds >= 1, "TokenVesting: slicePeriodSeconds must be >= 1");
		bytes32 vestingScheduleId = this.computeNextVestingScheduleIdForHolder(_beneficiary);
		uint32 cliff = _start + _cliff;
		vestingSchedules[vestingScheduleId] = VestingSchedule(
			true,
			_revocable,
			false,
			_beneficiary,
			cliff,
			_start,
			_duration,
			_slicePeriodSeconds,
			_amount,
			_immediatelyReleasableAmount,
			0
		);
		vestingSchedulesTotalAmount = vestingSchedulesTotalAmount + _amount;
		vestingSchedulesIds.push(vestingScheduleId);
		uint256 currentVestingCount = holdersVestingCount[_beneficiary];
		holdersVestingCount[_beneficiary] = currentVestingCount + 1;

		emit VestingScheduleCreated(msg.sender, _beneficiary, vestingScheduleId, vestingSchedules[vestingScheduleId]);
	}

	/**
	 * @notice Revokes the vesting schedule for given identifier.
	 * @param vestingScheduleId the vesting schedule identifier
	 */
	function revoke(
		bytes32 vestingScheduleId
	) public virtual onlyOwner onlyIfVestingScheduleNotRevoked(vestingScheduleId) {
		VestingSchedule storage vestingSchedule = vestingSchedules[vestingScheduleId];
		require(vestingSchedule.revocable == true, "TokenVesting: vesting is not revocable");
/*
		uint128 vestedAmount = _computeReleasableAmount(vestingSchedule);
		if (vestedAmount > 0) {
			release(vestingScheduleId, vestedAmount);
		}
*/
		uint256 unreleased = vestingSchedule.amountTotal - vestingSchedule.released;
		vestingSchedulesTotalAmount = vestingSchedulesTotalAmount - unreleased;
		vestingSchedule.revoked = true;

		emit Revoked(msg.sender, vestingSchedule.beneficiary, vestingScheduleId);
	}

	/**
	 * @notice Release vested amount of tokens.
	 * @param vestingScheduleId the vesting schedule identifier
	 * @param amount the amount to release
	 */
	function release(
		bytes32 vestingScheduleId,
		uint128 amount
	) public virtual nonReentrant onlyIfVestingScheduleNotRevoked(vestingScheduleId) {
		VestingSchedule storage vestingSchedule = vestingSchedules[vestingScheduleId];
		bool isBeneficiary = msg.sender == vestingSchedule.beneficiary;
		bool isOwner = msg.sender == owner();
		require(
			isBeneficiary || isOwner,
			"TokenVesting: only beneficiary and owner can release vested tokens"
		);
		uint256 vestedAmount = _computeReleasableAmount(vestingSchedule);
		require(vestedAmount >= amount, "TokenVesting: cannot release tokens, not enough vested tokens");
		vestingSchedule.released = vestingSchedule.released + amount;
		address payable beneficiaryPayable = payable(vestingSchedule.beneficiary);
		vestingSchedulesTotalAmount = vestingSchedulesTotalAmount - amount;
		IERC20(_token).safeTransferFrom(_treasury, beneficiaryPayable, amount);

		emit Released(msg.sender, beneficiaryPayable, vestingScheduleId, amount);
	}

	/**
	 * @dev Returns the number of vesting schedules managed by this contract.
	 * @return the number of vesting schedules
	 */
	function getVestingSchedulesCount() public view virtual returns (uint256) {
		return vestingSchedulesIds.length;
	}

	/**
	 * @notice Computes the vested amount of tokens for the given vesting schedule identifier.
	 * @return the vested amount
	 */
	function computeReleasableAmount(
		bytes32 vestingScheduleId
	) public view virtual onlyIfVestingScheduleExists(vestingScheduleId) returns (uint256) {
		VestingSchedule storage vestingSchedule = vestingSchedules[vestingScheduleId];
		return _computeReleasableAmount(vestingSchedule);
	}

	/**
	 * @notice Returns the vesting schedule information for a given identifier.
	 * @return the vesting schedule structure information
	 */
	function getVestingSchedule(bytes32 vestingScheduleId) public view virtual returns (VestingSchedule memory) {
		return vestingSchedules[vestingScheduleId];
	}

	/**
	 * @dev Computes the next vesting schedule identifier for a given holder address.
	 */
	function computeNextVestingScheduleIdForHolder(address holder) public view virtual returns (bytes32) {
		return computeVestingScheduleIdForAddressAndIndex(holder, holdersVestingCount[holder]);
	}

	/**
	 * @dev Returns the last vesting schedule for a given holder address.
	 */
	function getLastVestingScheduleForHolder(address holder) public view virtual returns (VestingSchedule memory) {
		return vestingSchedules[computeVestingScheduleIdForAddressAndIndex(holder, holdersVestingCount[holder] - 1)];
	}

	/**
	 * @dev Computes the vesting schedule identifier for an address and an index.
	 */
	function computeVestingScheduleIdForAddressAndIndex(
		address holder, uint256 index
	) public pure virtual returns (bytes32) {
		return keccak256(abi.encodePacked(holder, index));
	}

	/**
	 * @dev Computes the releasable amount of tokens for a vesting schedule.
	 * @return the amount of releasable tokens
	 */
	function _computeReleasableAmount(VestingSchedule memory vestingSchedule) internal view virtual returns (uint128) {
		uint256 currentTime = getCurrentTime();
		if (currentTime < vestingSchedule.start || vestingSchedule.revoked == true) {
			return 0;
		} else if (currentTime < vestingSchedule.cliff) {
			return vestingSchedule.immediatelyReleasableAmount - vestingSchedule.released;
		} else if (currentTime >= vestingSchedule.start + vestingSchedule.duration) {
			return vestingSchedule.amountTotal - vestingSchedule.released;
		} else {
			uint256 timeFromCliff = currentTime - vestingSchedule.cliff;
			uint256 secondsPerSlice = vestingSchedule.slicePeriodSeconds;
			uint256 vestedSlicePeriods = timeFromCliff / secondsPerSlice;
			uint256 vestedSeconds = vestedSlicePeriods * secondsPerSlice;
			uint256 vestedAmount = (vestingSchedule.amountTotal - vestingSchedule.immediatelyReleasableAmount)
				* vestedSeconds / (vestingSchedule.duration + vestingSchedule.start - vestingSchedule.cliff)
				+ vestingSchedule.immediatelyReleasableAmount
				- vestingSchedule.released;
			return uint128(vestedAmount);
		}
	}

	function getCurrentTime() internal virtual view returns (uint256) {
		return block.timestamp;
	}

	/**
	 * @inheritdoc UUPSUpgradeable
	 */
	function _authorizeUpgrade(address) internal virtual override onlyOwner {}
}
