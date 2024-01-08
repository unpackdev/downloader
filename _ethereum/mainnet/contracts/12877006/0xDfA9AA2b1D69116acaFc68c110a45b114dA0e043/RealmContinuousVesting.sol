// contracts/RealmTeamVesting.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./AccessControlEnumerable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Pausable.sol";
import "./BokkyPooBahsDateTimeLibrary.sol";

contract RealmContinuousVesting is AccessControlEnumerable, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bytes32 public constant SCHEDULER_ROLE = keccak256("SCHEDULER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    event AllocationClaimed(address beneficiary, uint256 amount);

    struct Schedule {
        address beneficiary;
        uint256 startTimestamp;
        uint256 duration;
        uint256 totalReleaseAmount; // of all tokens for this schedule
        uint256 lastClaimedTimestamp;
    }

    IERC20 public token;
    mapping(address => Schedule) public vestingSchedules; // addressed by beneficiary
    address[] beneficiaries;

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `SCHEDULER_ROLE` and `PAUSER_ROLE`
     * to the account that deploys the contract. Safe Address is the GNOSIS safe (MultiSig) address which would used in order to control the schedules. 
     */
    constructor(address _tokenAddress, address _safeAddress, Schedule[] memory _schedules) {
        _setupRole(DEFAULT_ADMIN_ROLE, _safeAddress);
        _setupRole(SCHEDULER_ROLE, _safeAddress);
        _setupRole(PAUSER_ROLE, _safeAddress);

        for(uint i; i < _schedules.length; i++) {
            vestingSchedules[_schedules[i].beneficiary] = _schedules[i];
            beneficiaries.push(_schedules[i].beneficiary);
        }

        token = IERC20(_tokenAddress);
    }

    function addSchedule(Schedule calldata schedule) public {
        require(hasRole(SCHEDULER_ROLE, _msgSender()), "Must have scheduler role to add schedule. This must be our GNOSIS safe address only!");
        vestingSchedules[schedule.beneficiary] = schedule;
        beneficiaries.push(schedule.beneficiary);
    }

    function removeSchedule(address beneficiary) public {
        require(hasRole(SCHEDULER_ROLE, _msgSender()), "Must have scheduler role to remove schedule!");
        delete vestingSchedules[beneficiary];
    }

    function calculateAllocation(address beneficiary) public view returns(uint256) {
        Schedule memory schedule = vestingSchedules[beneficiary];

        require(schedule.startTimestamp != 0, "Schedule for beneficiary not found");
        require(schedule.startTimestamp <= block.timestamp, "Schedule hasn't started yet");

        if(schedule.lastClaimedTimestamp == 0) schedule.lastClaimedTimestamp = schedule.startTimestamp;

        // Claimed duration days till date of request. If duration days are greater then decided duration then set calimed to maximum duration days.
        // Also, check if lastclaimed and start time stamp is same then no tokens were vested thus setting to 0.
        uint256 claimedDurationdays = diffDays(schedule.startTimestamp, schedule.lastClaimedTimestamp);
        if(claimedDurationdays > schedule.duration) claimedDurationdays = schedule.duration;
        if(schedule.lastClaimedTimestamp == schedule.startTimestamp) claimedDurationdays = 0; 
        
        // Calculate total duration from the start.
        // If total duartion is greater then the schedule duration set total duraiton to scheule duration
        uint256 totalDurationdays = diffDays(schedule.startTimestamp, block.timestamp);
        if(totalDurationdays > schedule.duration) totalDurationdays = schedule.duration;

        // Calcuate the remaining duration days for vesting
        uint256 unclaimedDurationdays = totalDurationdays - claimedDurationdays;

        require(unclaimedDurationdays > 0, "Beneficiary doesn't have any unclaimed vesting duration");
        if(unclaimedDurationdays > schedule.duration) unclaimedDurationdays = schedule.duration;

        uint256 releaseAmount = (schedule.totalReleaseAmount * unclaimedDurationdays).div(schedule.duration);
        return releaseAmount;
    }
    
    // claim your vested allocation
    // should be able to allocate without multisig
    function claimAllocation() public whenNotPaused {
        address sender = _msgSender();
        Schedule storage schedule = vestingSchedules[sender];

        uint256 releaseAmount = calculateAllocation(sender);
        uint256 contractBalance = token.balanceOf(address(this));
        
        // since we have decimal of 10**18
        require(releaseAmount <= contractBalance, "Not enough tokens in contract for release amount");

        // send tokens / add allowance on token contract
        schedule.lastClaimedTimestamp = block.timestamp;
        
        //token.safeIncreaseAllowance(sender, releaseAmount);
        token.safeTransfer(sender, releaseAmount);
        emit AllocationClaimed(sender, releaseAmount);
    }
    
    function diffDays(uint fromTimestamp, uint toTimestamp) public pure returns (uint _days) {
        _days = BokkyPooBahsDateTimeLibrary.diffDays(fromTimestamp, toTimestamp);
    }

    /**
     * @dev Pauses all allocation claims (token payouts).
     * See {ERC1155Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public {
        require(hasRole(PAUSER_ROLE, _msgSender()), "Must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all allocation claims (token payouts).
     * See {Pausable-_unpause}.
     *
     * Requirements:
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public {
        require(hasRole(PAUSER_ROLE, _msgSender()), "Must have pauser role to unpause");
        _unpause();
    }
}
