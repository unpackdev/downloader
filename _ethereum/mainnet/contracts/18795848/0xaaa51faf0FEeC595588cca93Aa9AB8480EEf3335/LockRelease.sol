// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Ownable2Step.sol";
import "./IERC20.sol";
import "./Votes.sol";

/**
 * @notice This contract creates token release schedules to linearly release those tokens over the defined duration.
 */
contract LockRelease is Votes, Ownable2Step {
    /** Represents a release schedule for a specific beneficiary. */
    struct Schedule {
        uint256 total; // total tokens that the beneficiary will receive over the duration
        uint256 released; // already released tokens to the beneficiary
    }

    address public immutable token; // address of the token being released
    uint128 public immutable start; // start timestamp of the release schedule
    uint128 public immutable duration; // duration of the release schedule in seconds

    /** Represents a release schedule for a specific beneficiary. */
    mapping(address => Schedule) private schedules;

    /** Emitted when a group of release schedules is created. */
    event ScheduleStarted(address[] beneficiaries, uint256[] amounts);

    /** Emitted when tokens are released to a recipient. */
    event TokensReleased(address indexed beneficiary, uint256 amount);

    error InvalidArrayLengths();
    error ZeroDuration();
    error InvalidBeneficiary();
    error InvalidToken();
    error InvalidAmount();
    error DuplicateBeneficiary();
    error NothingToRelease();

    /**
     * @notice Deploys the LockRelease contract and sets up all beneficiary release schedules.
     * @param _token address of the beneficiary
     * @param _start the timestamp that the release schedule begins releasing tokens at
     * @param _duration the time period in seconds that tokens are released over
     * @param _beneficiaries array of beneficiary addresses to create release schedules for
     * @param _amounts array of the amount of tokens to be locked and released for each beneficiary
     */
    constructor(
        address _owner,
        address _token,
        uint128 _start,
        uint128 _duration,
        address[] memory _beneficiaries,
        uint256[] memory _amounts
    ) EIP712("DecentLockRelease", "1") Ownable(_owner) {
        if (_token == address(0)) revert InvalidToken();
        if (_duration == 0) revert ZeroDuration();

        token = _token;
        start = _start;
        duration = _duration;

        _addSchedules(_beneficiaries, _amounts);
    }

    /**
     * @notice Add new schedules to the contract, utilizing existing token, start, and duration
     * @dev Tokens are pulled from msg.sender directly in this function call
     * @param _beneficiaries array of beneficiary addresses to create release schedules for
     * @param _amounts array of the amount of tokens to be locked and released for each beneficiary
     */
    function addSchedules(
        address[] memory _beneficiaries,
        uint256[] memory _amounts
    ) public onlyOwner {
        uint256 totalAmount = _addSchedules(_beneficiaries, _amounts);
        IERC20(token).transferFrom(msg.sender, address(this), totalAmount);
    }

    function _addSchedules(
        address[] memory _beneficiaries,
        uint256[] memory _amounts
    ) private returns (uint256 totalAmount) {
        if (_beneficiaries.length != _amounts.length)
            revert InvalidArrayLengths();

        for (uint16 i; i < _beneficiaries.length; ) {
            uint256 amount = _amounts[i];
            if (amount == 0) revert InvalidAmount();

            address beneficiary = _beneficiaries[i];
            if (beneficiary == address(0)) revert InvalidBeneficiary();
            if (getTotal(beneficiary) != 0) revert DuplicateBeneficiary();

            schedules[beneficiary] = Schedule(amount, 0);

            // mint the beneficiary voting units
            _transferVotingUnits(address(0), beneficiary, amount);

            // beneficiary delegates to themself
            _delegate(beneficiary, beneficiary);

            // increase total
            totalAmount += amount;

            unchecked {
                ++i;
            }
        }

        emit ScheduleStarted(_beneficiaries, _amounts);
    }

    /**
     * @notice Release all releasable tokens to the caller.
     */
    function release() external {
        uint256 releasable = getReleasable(msg.sender);

        if (releasable == 0) revert NothingToRelease();

        // Update released amount
        schedules[msg.sender].released += releasable;

        // Burn the released voting units
        _transferVotingUnits(msg.sender, address(0), releasable);

        // Transfer tokens to recipient
        IERC20(token).transfer(msg.sender, releasable);

        emit TokensReleased(msg.sender, releasable);
    }

    /**
     * @notice Returns the total tokens that will be released to the beneficiary over the duration.
     * @param beneficiary address of the beneficiary
     * @return uint256 total tokens that will be released to the beneficiary
     */
    function getTotal(address beneficiary) public view returns (uint256) {
        return schedules[beneficiary].total;
    }

    /**
     * @notice Returns the total tokens already released to the beneficiary.
     * @param beneficiary address of the beneficiary
     * @return uint256 total tokens already released to the beneficiary
     */
    function getReleased(address beneficiary) public view returns (uint256) {
        return schedules[beneficiary].released;
    }

    /**
     * @notice Returns the total tokens that have matured until now according to the release schedule.
     * @param beneficiary address of the beneficiary
     * @return uint256 total tokens that have matured
     */
    function getTotalMatured(
        address beneficiary
    ) public view returns (uint256) {
        if (block.timestamp < start) return 0;
        uint256 total = getTotal(beneficiary);
        if (block.timestamp >= start + duration) return total;
        return (total * (block.timestamp - start)) / duration;
    }

    /**
     * @notice Returns the total tokens that can be released now.
     * @param beneficiary address of the beneficiary
     * @return uint256 the total tokens that can be released now
     */
    function getReleasable(address beneficiary) public view returns (uint256) {
        return getTotalMatured(beneficiary) - getReleased(beneficiary);
    }

    /**
     * @notice Returns the current amount of votes that the account has.
     * @param account the address to check current votes for
     * @return uint256 the current amount of votes that the account has
     */
    function getVotes(address account) public view override returns (uint256) {
        return super.getVotes(account) + IERC5805(token).getVotes(account);
    }

    /**
     * @notice Returns the amount of votes that the account had at a specific moment in the past.
     * @param account the address to check current votes for
     * @param blockNumber the past block number to check the account's votes at
     * @return uint256 the amount of votes
     */
    function getPastVotes(
        address account,
        uint256 blockNumber
    ) public view virtual override returns (uint256) {
        return
            super.getPastVotes(account, blockNumber) +
            IERC5805(token).getPastVotes(account, blockNumber);
    }

    /**
     * @notice Returns the current number of voting units held by an account.
     * @param account the address to check voting units for
     * @return uint256 the amount of voting units
     */
    function _getVotingUnits(
        address account
    ) internal view override returns (uint256) {
        return getTotal(account) - getReleased(account);
    }
}
