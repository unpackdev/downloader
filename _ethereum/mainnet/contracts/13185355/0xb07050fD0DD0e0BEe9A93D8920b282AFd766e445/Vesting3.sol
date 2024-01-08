// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./SafeMathUpgradeable.sol";
// import "./SignedSafeMathUpgradeable.sol";
// import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IStakingPoolsVesting.sol";
import "./IUniswapV2RouterMinimal.sol";
import "./IERC20Minimal.sol";
import "./Initializable.sol";

// import "./console.sol";
contract TokenVestingV3 is OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    struct Schedule {
        // the total amount that has been vested
        uint256 totalAmount;
        // the total amount that has been claimed
        uint256 claimedAmount;
        uint256 startTime;
        uint256 cliffTime;
        uint256 endTime;
        uint256 cliffWeeks;
        // amount of vesting kko staked in the kko staking pool
        uint256 totalStakedKko;
        // the amount of eth lp tokens owned by the account
        uint256 kkoEthLpTokens;
        // tracks the amount of kko tokens that are in active LP
        uint256 kkoInLp;
    }

    mapping (address => mapping(uint => Schedule)) public schedules;
    mapping (address => uint) public numberOfSchedules;

    modifier onlyConfigured() {
        require(configured, "Vesting: only configured"); 
        _;
    }

    /// @dev total kko locked in the contract
    uint256 public valueLocked;
    IERC20Minimal private kko;
    IERC20Minimal private lpToken;
    IUniswapV2RouterMinimal private router;
    IStakingPoolsVesting private stakingPools;
    bool private configured;
    uint256 public kkoPoolsId;
    uint256 public kkoLpPoolsId;
    event Claim(uint amount, address claimer);

    mapping(address => bool) public blacklist;

    function initialize(address _kko, address _lpToken, address _router) public initializer {
        OwnableUpgradeable.__Ownable_init();
        kko = IERC20Minimal(_kko);
        lpToken = IERC20Minimal(_lpToken);
        router = IUniswapV2RouterMinimal(_router);
        // approve the router to spend kko
        require(kko.approve(_router, 2**256-1));
        require(lpToken.approve(_router, 2**256-1));
    }

    fallback() external payable {}

    function setStakingPools(address _contract, uint256 _kkoPoolsId, uint256 _kkoLpPoolsId) external onlyOwner {
        require(configured == false, "must not be configured");
        stakingPools = IStakingPoolsVesting(_contract);
        kkoPoolsId = _kkoPoolsId;
        kkoLpPoolsId = _kkoLpPoolsId;
        configured = true;
        // todo(bonedaddy): is this optimal? not sure
        // approve max uint256 value
        require(kko.approve(_contract, 2**256-1));
        require(lpToken.approve(_contract, 2**256-1));
    }

    /**
    * @notice Sets up a vesting schedule for a set user.
    * @notice at the moment this only supports staking of the kko staking
    * @dev adds a new Schedule to the schedules mapping.
    * @param account the account that a vesting schedule is being set up for. Will be able to claim tokens after
    *                the cliff period.
    * @param amount the amount of tokens being vested for the user.
    * @param cliffWeeks the number of weeks that the cliff will be present at.
    * @param vestingWeeks the number of weeks the tokens will vest over (linearly)
    */
    function setVestingSchedule(
        address account,
        uint256 amount,
        uint256 cliffWeeks,
        uint256 vestingWeeks,
        bool danger
    ) public onlyOwner onlyConfigured {
        if (danger == false) {
            require(
                kko.balanceOf(address(this)).sub(valueLocked) >= amount,
                "Vesting: amount > tokens leftover"
            );
        }

        require(
            vestingWeeks >= cliffWeeks,
            "Vesting: cliff after vesting period"
        );
        uint256 currentNumSchedules = numberOfSchedules[account];
        schedules[account][currentNumSchedules] = Schedule(
            amount,
            0,
            block.timestamp,
            block.timestamp.add(cliffWeeks * 1 weeks),
            block.timestamp.add(vestingWeeks * 1 weeks),
            cliffWeeks,
            0, // amount staked in kko pool
            0, // amount of lp tokens
            0 // amount of kko lp'd
        );
        numberOfSchedules[account] = currentNumSchedules + 1;
        valueLocked = valueLocked.add(amount);
    }

    /**
    * @notice Updates the vesting schedule of a user
    * @param account the account that a vesting schedule is being updated for.
    * @param scheduleNumber schedule to update.
    * @param cliffWeeks the number of weeks that the cliff will be present at.
    * @param vestingWeeks the number of weeks the tokens will vest over (linearly)
    */
    function updateVestingSchedule(
        address account,
        uint256 scheduleNumber,
        uint256 cliffWeeks,
        uint256 vestingWeeks
    ) public onlyOwner onlyConfigured {
        Schedule storage schedule = schedules[account][scheduleNumber];
        schedule.cliffTime = cliffWeeks * 1 weeks;
        schedule.endTime = vestingWeeks * 1 weeks;
        schedule.cliffWeeks = cliffWeeks;
    }

    /// @dev allows staking vesting KKO tokens in the kko single staking pool
    function stakeSingle(uint256 scheduleNumber, uint256 _amountToStake) public onlyConfigured {
        Schedule storage schedule = schedules[msg.sender][scheduleNumber];
        require(
            // ensure that the total amount of staked kko including the amount we are staking and lp'ing
            // is less than the total available amount
            schedule.totalStakedKko.add(_amountToStake).add(schedule.kkoInLp) <= schedule.totalAmount.sub(schedule.claimedAmount),
            "Vesting: total staked must be less than or equal to available amount (totalAmount - claimedAmount)"
        );
        schedule.totalStakedKko = schedule.totalStakedKko.add(_amountToStake);
        require(
            stakingPools.depositVesting(
                msg.sender,
                kkoPoolsId,
                _amountToStake
            ),
            "Vesting: depositVesting failed"
        );
    }

    function stakePool2(
        uint256 scheduleNumber, 
        uint256 _amountKko, 
        uint256 _amountEther,
        uint256 _amountTokenMin,
        uint256 _amountETHMin,
        uint _deadline
    ) public payable onlyConfigured {
        Schedule storage schedule = schedules[msg.sender][scheduleNumber];
        require(
            schedule.totalStakedKko.add(_amountKko).add(schedule.kkoInLp) <= schedule.totalAmount.sub(schedule.claimedAmount),
            "Vesting: total staked must be less than or equal to available amount (totalAmount - claimedAmount)"
        );
        require(msg.value == _amountEther, "Vesting: sending not supplying enough ether");
        schedule.kkoInLp = schedule.kkoInLp.add(_amountKko);
        // amountToken = The amount of token sent to the pool.
        // amountETH = The amount of ETH converted to WETH and sent to the pool.
        // liquidity = The amount of liquidity tokens minted.
        (uint amountToken, uint amountETH, uint liquidity) = router.addLiquidityETH{value: msg.value}(
            address(kko),
            _amountKko, // the amount of token to add as liquidity if the WETH/token price is <= msg.value/amountTokenDesired (token depreciates).
            _amountTokenMin, // Bounds the extent to which the WETH/token price can go up before the transaction reverts. Must be <= amountTokenDesired.
            _amountETHMin, // Bounds the extent to which the token/WETH price can go up before the transaction reverts. Must be <= msg.value.
            address(this),
            _deadline
        );
        // if we didnt add the fully amount requested, reduce the amount staked
        if (amountToken < _amountKko) {
            schedule.kkoInLp = schedule.kkoInLp.sub(amountToken);
        }
        schedule.kkoEthLpTokens = schedule.kkoEthLpTokens.add(liquidity);
        require(
            stakingPools.depositVesting(
                msg.sender,
                kkoLpPoolsId,
                liquidity
            ),
            "Vesting: depositVesting failed"
        );
        if (amountETH < _amountEther) {
            msg.sender.transfer(_amountEther.sub(amountETH));
        }
    }


    function exitStakePool2(
        uint256 scheduleNumber,
        uint256 _amountLpTokens,
        uint256 _amountTokenMin,
        uint256 _amountETHMin,
        uint _deadline    
    ) public payable onlyConfigured {
        Schedule storage schedule = schedules[msg.sender][scheduleNumber];
        require(
            _amountLpTokens <= schedule.kkoEthLpTokens,
            "Vesting: insufficient lp token balance"
        );

        (bool ok,) = stakingPools.withdrawOrClaimOrExitVesting(
            msg.sender,
            kkoLpPoolsId,
            0,
            true,
            true
        );
        require(ok, "Vesting exitStakePool2 failed");
        // amountToken is the amount of tokens received
        // amountETH is the maount of ETH received
        (uint256 amountToken, uint256 amountETH) = router.removeLiquidityETH(
            address(kko),
            schedule.kkoEthLpTokens,
            _amountTokenMin,
            _amountETHMin,
            address(this),
            _deadline
        );

        bool claimBlacklisted = blacklist[msg.sender];
        // due to lp fees they may be withdrawing more kko than they originally deposited
        // in this case we will send the difference directly to their wallet
        if (amountToken > schedule.kkoInLp) {
            uint256 difference = amountToken.sub(schedule.kkoInLp);
            schedule.kkoInLp = 0;
            if (claimBlacklisted == false) {
                require(kko.transfer(msg.sender, difference));
            }
        } else {
            schedule.kkoInLp = schedule.kkoInLp.sub(amountToken);
        }
        msg.sender.transfer(amountETH);
    }

    /// @dev used to exit from the single staking pool
    /// @dev this does not transfer the unstaked tokens to the msg.sender, but rather this contract
    function exitStakeSingle(uint256 scheduleNumber) public onlyConfigured {
        Schedule storage schedule = schedules[msg.sender][scheduleNumber];
        (bool ok, uint256 reward) = stakingPools.withdrawOrClaimOrExitVesting(
            msg.sender,
            kkoPoolsId,
            0, // we are exiting the pool so withdrawing all kko
            true,
            true
        );
        require(ok, "Vesting: exitStakeSingle failed");

        bool claimBlacklisted = blacklist[msg.sender];
        if (claimBlacklisted == false) {
            require(kko.transfer(msg.sender, reward));
        }
        uint256 totalStaked = schedule.totalStakedKko;
        // we're exiting this pool so set to 0
        schedule.totalStakedKko = schedule.totalStakedKko.sub(totalStaked);
    }

    /// @dev allows claiming staking rewards without exiting the staking pool
    function claimStakingRewards(uint256 _poolId) public onlyConfigured {
        require(_poolId == kkoPoolsId || _poolId == kkoLpPoolsId);

        bool claimBlacklisted = blacklist[msg.sender];
        require(claimBlacklisted == false, "Claim blacklisted");
        (bool ok, uint256 reward) = stakingPools.withdrawOrClaimOrExitVesting(
            msg.sender,
            _poolId,
            0, // we are solely claiming rewards
            false,
            false
        );
        require(ok);
        require(kko.transfer(msg.sender, reward));
    }

    /**
    * @notice allows users to claim vested tokens if the cliff time has passed.
    * @notice needs to handle claiming from kko and kkoeth-lp staking
    */
    function claim(uint256 scheduleNumber) public onlyConfigured {
        Schedule storage schedule = schedules[msg.sender][scheduleNumber];
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
        // set the previous amount claimed 
        uint prevClaimed = schedule.claimedAmount;
        schedule.claimedAmount = amount; // set new claimed amount based off the curve
        // if the amount that is unstaked is smaller than the amount being transffered
        // destake first
        require(
            // amountToTransfer < (schedule.claimedAmount - (schedule.totalStakedKkoPool2 + schedule.totalStakedKkoSingle)),
            amountToTransfer <= (schedule.totalAmount - prevClaimed),
            "Vesting: amount unstaked too small for claim please destake"
        );

        require(kko.transfer(msg.sender, amountToTransfer));
        // todo(bonedaddy): this might need some updating
        // as it doesnt factor in staking rewards
        emit Claim(amount, msg.sender);
    }

    /**
    * @notice returns the total amount and total claimed amount of a users vesting schedule.
    * @param account the user to retrieve the vesting schedule for.
    */
    function getVesting(address account, uint256 scheduleId)
        public
        view
        returns (uint256, uint256, uint256, uint256)
    {
        Schedule memory schedule = schedules[account][scheduleId];
        return (schedule.totalAmount, schedule.claimedAmount, schedule.kkoInLp, schedule.totalStakedKko);
    }

    /**
    * @notice calculates the amount of tokens to distribute to an account at any instance in time, based off some
    *         total claimable amount.
    * @param amount the total outstanding amount to be claimed for this vesting schedule.
    * @param currentTime the current timestamp.
    * @param startTime the timestamp this vesting schedule started.
    * @param endTime the timestamp this vesting schedule ends.
    */
    function calcDistribution(uint amount, uint currentTime, uint startTime, uint endTime) public pure returns(uint256) {
        return amount.mul(currentTime.sub(startTime)).div(endTime.sub(startTime));
    }

    /** 
    * @notice this doesn't handle withdrawing from staking pools
    * @notice Withdraws KKO tokens from the contract.
    * @dev blocks withdrawing locked tokens.
    * @notice if danger is set to true, then all amount checking is witdhrawn
    * @notice this could potentially have bad implications so use with caution
    */
    function withdraw(uint amount, bool danger) public onlyOwner {
        if (danger == false) {
            require(
                kko.balanceOf(address(this)).sub(valueLocked) >= amount,
                "Vesting: amount > tokens leftover"
            );
        }
        require(kko.transfer(msg.sender, amount));
    }

    /// used to update the amount of tokens an account is vesting
    function updateVestingAmount(
        address account,
        uint256 amount,
        uint256 scheduleNumber
    ) public onlyOwner onlyConfigured {
        Schedule storage schedule = schedules[account][scheduleNumber];
        uint256 prevAmountTotal =  schedule.totalAmount;
        schedule.totalAmount = amount;
        // we are decreasing the amount they are vesting
        uint256 difference = prevAmountTotal.sub(amount);
        // subtract the difference from value locked
        valueLocked = valueLocked.sub(difference);
        // transfer the difference back to the caller
        require(kko.transfer(msg.sender, difference));
    }

    function toggleBlacklist(
        address account
    ) public onlyOwner onlyConfigured {
        blacklist[account] = !blacklist[account];
    }
}