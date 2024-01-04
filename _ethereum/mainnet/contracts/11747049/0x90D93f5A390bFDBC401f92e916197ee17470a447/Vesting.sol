// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./SignedSafeMath.sol";
import "./Ownable.sol";
import "./IVesting.sol";

contract TokenVesting is Ownable, IVesting {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct Schedule {
        uint256 totalAmount;
        uint256 claimedAmount;
        uint256 startTime;
        uint256 cliffTime;
        uint256 endTime;
        bool isFixed;
        bool cliffClaimed;
    }

    struct UserSchedule {
        uint256 numberOfSchedules;
        mapping (uint256 => Schedule) schedules; 
    }

    mapping(address => UserSchedule) userSchedules;
    uint256 locked;
    IERC20 TCR;
    uint SAFE_MUL = 10e18;

    event Claim(uint amount, address claimer);

    constructor(address tcr) public {
        TCR = IERC20(tcr);
    }

    /**
    * @notice Sets up a vesting schedule for a set user.
    * @dev adds a new Schedule to the schedules mapping.
    * @param account the account that a vesting schedule is being set up for. Will be able to claim tokens after
    *                the cliff period.
    * @param amount the amount of tokens being vested for the user.
    * @param isFixed a flag for if the vesting schedule is fixed or not. Fixed vesting schedules can't be cancelled.
    * @param cliffWeeks the number of weeks that the cliff will be present at.
    * @param vestingWeeks the number of weeks the tokens will vest over (linearly)
    */
    function setVestingSchedule(
        address account,
        uint256 amount,
        bool isFixed,
        uint256 cliffWeeks,
        uint256 vestingWeeks
    ) public override onlyOwner {
        require(
            TCR.balanceOf(address(this)).sub(locked) >= amount,
            "Vesting: amount > tokens leftover"
        );
        require(
            vestingWeeks >= cliffWeeks,
            "Vesting: cliff after vesting period"
        );
        UserSchedule storage userSchedule = userSchedules[account];
        userSchedule.schedules[userSchedule.numberOfSchedules] = Schedule(
            amount,
            0,
            block.timestamp,
            block.timestamp.add(cliffWeeks * 1 weeks),
            block.timestamp.add(vestingWeeks * 1 weeks),
            isFixed,
            false
        );
        userSchedule.numberOfSchedules++;
        locked = locked.add(amount);
    }

    /**
    * @notice allows users to claim vested tokens if the cliff time has passed.
    */
    function claim(uint256 scheduleNumber) public override {
        Schedule storage schedule = userSchedules[msg.sender].schedules[scheduleNumber];
        require(
            schedule.cliffTime <= block.timestamp,
            "Vesting: cliffTime not reached"
        );
        require(schedule.totalAmount > 0, "Vesting: No claimable tokens");

        // Get the amount to be distributed
        uint amount = calcDistribution(schedule.totalAmount, block.timestamp, schedule.startTime, schedule.endTime);
        
        // Cap the amount at the total amount
        amount = amount > schedule.totalAmount ? schedule.totalAmount : amount;
        uint amountToTransfer = amount.sub(schedule.claimedAmount);
        schedule.claimedAmount = amount; // set new claimed amount based off the curve
        TCR.safeTransfer(msg.sender, amountToTransfer);
        emit Claim(amount, msg.sender);
    }

    /**
    * @notice Allows a vesting schedule to be cancelled.
    * @dev Any outstanding tokens are returned to the system.
    * @param account the account of the user whos vesting schedule is being cancelled.
    */
    function cancelVesting(address account, uint256 scheduleId) public override onlyOwner {
        Schedule storage schedule = userSchedules[account].schedules[scheduleId];
        require(schedule.claimedAmount < schedule.totalAmount, "Vesting: Tokens fully claimed");
        require(!schedule.isFixed, "Vesting: Account is fixed");
        uint256 outstandingAmount = schedule.totalAmount.sub(schedule.claimedAmount);
        schedule.totalAmount = 0;
        locked = locked.sub(outstandingAmount);
    }

    /**
    * @notice returns the total amount and total claimed amount of a users vesting schedule.
    * @param account the user to retrieve the vesting schedule for.
    */
    function getVesting(address account, uint256 scheduleId)
        public
        override
        view
        returns (uint256, uint256)
    {
        Schedule memory schedule = userSchedules[account].schedules[scheduleId];
        return (schedule.totalAmount, schedule.claimedAmount);
    }

    /**
    * @notice calculates the amount of tokens to distribute to an account at any instance in time, based off some
    *         total claimable amount.
    * @param amount the total outstanding amount to be claimed for this vesting schedule.
    * @param currentTime the current timestamp.
    * @param startTime the timestamp this vesting schedule started.
    * @param endTime the timestamp this vesting schedule ends.
    */
    function calcDistribution(uint amount, uint currentTime, uint startTime, uint endTime) public override pure returns(uint256) {
        return amount.mul(currentTime.sub(startTime)).div(endTime.sub(startTime));
    }

    /**
    * @notice Withdraws TCR tokens from the contract.
    * @dev blocks withdrawing locked tokens.
    */
    function withdraw(uint amount) public onlyOwner {
        require(
            TCR.balanceOf(address(this)).sub(locked) >= amount,
            "Vesting: amount > tokens leftover"
        );
        TCR.safeTransfer(owner(), amount);
    }
}
