// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./IOnMint.sol";

/**
 * @title RewardVesting
 * @dev The vesting contract for the initial mint rewards
 */
contract RewardVesting is Ownable, IOnMint {
    using SafeMath for uint256;
    /// @notice Start block of rewards
    uint256 public rewardEarnStartBlock;

    /// @notice End block of rewards
    uint256 public rewardEarnEndBlock;

    /// @notice Reward vesting duration in days
    uint16 public rewardVestingDuration;

    /// @notice Start block of NFTs eligible for rewards
    uint256 public rewardEligibleStartBlock;

    /// @notice End block of NFTs eligibile for rewards
    uint256 public rewardEligibleEndBlock;

    /// @notice Total rewards per mint
    uint256 public rewardAmount;

    /// @notice Address of reward token
    IERC20 public rewardToken;

    /// @notice Grant definition
    struct Grant {
        uint256 startTime;
        uint256 amount;
        uint16 vestingDuration;
        uint16 vestingCliff;
        uint256 totalClaimed;
    }

    /// @notice Mapping of address to grants
    mapping (address => Grant) public tokenGrants;

    /// @notice Caller address that is allowed to add grants (in addition to owner)
    address public caller;

    /// @dev Used to translate vesting periods specified in days to seconds
    uint256 constant internal SECONDS_PER_DAY = 86400;

    /**
     * @notice Construct a new Vesting contract
     * @param _rewardToken Address of reward token
     * @param _caller Address of an additional allowed caller of addTokenGrant
     */
    constructor(address _rewardToken, address _caller) {
        require(_rewardToken != address(0), "RewardVesting::constructor: must be valid token address");
        require(_caller != address(0), "RewardVesting::constructor: must be valid address");
        rewardToken = IERC20(_rewardToken);
        caller = _caller;
        rewardToken.approve(owner(), type(uint256).max);
    }

    /**
     * @notice Emitted when reward parameters ({rewardEarnStartBlock}, rewardEarnEndBlock}, {rewardEligibleStartBlock},
     * {rewardEligibleEndBlock}, {rewardVestingDuration}, {rewardAmount}) are changed
     */
    event RewardParametersChanged(uint256 startBlock, uint256 endBlock, uint256 eligibleStartBlock,
        uint256 eligibleEndBlock, uint16 vestingDuration, uint256 amount);

    /// @notice Event emitted when a new grant is created
    event GrantAdded(address indexed recipient, uint256 indexed amount, uint256 startTime, uint16 vestingDurationInDays, uint16 vestingCliffInDays);
    
    /// @notice Event emitted when tokens are claimed by a recipient from a grant
    event GrantTokensClaimed(address indexed recipient, uint256 indexed amountClaimed);

    /**
     * @dev Sets current reward parameters
     * Requirements:
     *
     * - the caller must be owner
     */
    function setRewardParameters(uint256 startBlock, uint256 endBlock, uint256 eligibleStartBlock,
        uint256 eligibleEndBlock, uint16 vestingDuration, uint256 amount) public onlyOwner {

        require(endBlock >= startBlock, "RewardVesting: startBlock less than endBlock");
        require(eligibleEndBlock >= eligibleStartBlock, "RewardVesting: eligibleEndBlock less than eligibleStartBlock");
        require(vestingDuration > 0, "RewardVesting: duration must be > 0");
        require(vestingDuration <= 25*365, "RewardVesting: duration more than 25 years");

        rewardEarnStartBlock = startBlock;
        rewardEarnEndBlock = endBlock;
        rewardEligibleStartBlock = eligibleStartBlock;
        rewardEligibleEndBlock = eligibleEndBlock;
        rewardVestingDuration = vestingDuration;
        rewardAmount = amount;

        emit RewardParametersChanged(startBlock, endBlock, eligibleStartBlock, eligibleEndBlock,
            vestingDuration, amount);
    }

    /**
     * @dev Rescue any ERC-20 token the contract may hold
     *
     * @param _token ERC-20 token address
     *
     * Requirements:
     *
     * - the caller must be owner
     */
    function rescue(address _token) public onlyOwner {
        IERC20 token = IERC20(_token);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    /**
     * @notice Add a new token grant
     * @param recipient The address that is receiving the grant
     * @param startTime The unix timestamp when the grant will start
     * @param amount The amount of tokens being granted
     * @param vestingDurationInDays The vesting period in days
     * @param vestingCliffInDays The vesting cliff duration in days
     */
    function addTokenGrant(
        address recipient,
        uint256 startTime,
        uint256 amount,
        uint16 vestingDurationInDays,
        uint16 vestingCliffInDays
    ) 
        public
    {
        require(msg.sender == owner() || msg.sender == caller, "RewardVesting::addTokenGrant: not owner or caller");
        require(vestingCliffInDays <= 10*365, "RewardVesting::addTokenGrant: cliff more than 10 years");
        require(vestingDurationInDays > 0, "RewardVesting::addTokenGrant: duration must be > 0");
        require(vestingDurationInDays <= 25*365, "RewardVesting::addTokenGrant: duration more than 25 years");
        require(vestingDurationInDays >= vestingCliffInDays, "RewardVesting::addTokenGrant: duration < cliff");
        require(tokenGrants[recipient].amount == 0, "RewardVesting::addTokenGrant: grant already exists for account");
        
        uint256 amountVestedPerDay = amount.div(vestingDurationInDays);
        require(amountVestedPerDay > 0, "RewardVesting::addTokenGrant: amountVestedPerDay > 0");

        uint256 grantStartTime = startTime == 0 ? block.timestamp : startTime;

        Grant memory grant = Grant({
            startTime: grantStartTime,
            amount: amount,
            vestingDuration: vestingDurationInDays,
            vestingCliff: vestingCliffInDays,
            totalClaimed: 0
        });
        tokenGrants[recipient] = grant;
        emit GrantAdded(recipient, amount, grantStartTime, vestingDurationInDays, vestingCliffInDays);
    }

    /**
     * @notice Get token grant for recipient
     * @param recipient The address that has a grant
     * @return the grant
     */
    function getTokenGrant(address recipient) public view returns(Grant memory){
        return tokenGrants[recipient];
    }

    /**
     * @notice Calculate the vested and unclaimed tokens available for `recipient` to claim
     * @dev Due to rounding errors once grant duration is reached, returns the entire left grant amount
     * @dev Returns 0 if cliff has not been reached
     * @param recipient The address that has a grant
     * @return The amount recipient can claim
     */
    function calculateGrantClaim(address recipient) public view returns (uint256) {
        Grant storage tokenGrant = tokenGrants[recipient];

        // For grants created with a future start date, that hasn't been reached, return 0, 0
        if (block.timestamp < tokenGrant.startTime) {
            return 0;
        }

        // Check cliff was reached
        uint256 elapsedTime = block.timestamp.sub(tokenGrant.startTime);
        uint256 elapsedDays = elapsedTime.div(SECONDS_PER_DAY);
        
        if (elapsedDays < tokenGrant.vestingCliff) {
            return 0;
        }

        // If over vesting duration, all tokens vested
        if (elapsedDays >= tokenGrant.vestingDuration) {
            uint256 remainingGrant = tokenGrant.amount.sub(tokenGrant.totalClaimed);
            return remainingGrant;
        } else {
            uint256 vestingDurationInSecs = uint256(tokenGrant.vestingDuration).mul(SECONDS_PER_DAY);
            uint256 vestingAmountPerSec = tokenGrant.amount.div(vestingDurationInSecs);
            uint256 amountVested = vestingAmountPerSec.mul(elapsedTime);
            uint256 claimableAmount = amountVested.sub(tokenGrant.totalClaimed);
            return claimableAmount;
        }
    }

    /**
     * @notice Calculate the vested (claimed + unclaimed) tokens for `recipient`
     * @dev Returns 0 if cliff has not been reached
     * @param recipient The address that has a grant
     * @return Total vested balance (claimed + unclaimed)
     */
    function vestedBalance(address recipient) external view returns (uint256) {
        Grant storage tokenGrant = tokenGrants[recipient];

        // For grants created with a future start date, that hasn't been reached, return 0, 0
        if (block.timestamp < tokenGrant.startTime) {
            return 0;
        }

        // Check cliff was reached
        uint256 elapsedTime = block.timestamp.sub(tokenGrant.startTime);
        uint256 elapsedDays = elapsedTime.div(SECONDS_PER_DAY);
        
        if (elapsedDays < tokenGrant.vestingCliff) {
            return 0;
        }

        // If over vesting duration, all tokens vested
        if (elapsedDays >= tokenGrant.vestingDuration) {
            return tokenGrant.amount;
        } else {
            uint256 vestingDurationInSecs = uint256(tokenGrant.vestingDuration).mul(SECONDS_PER_DAY);
            uint256 vestingAmountPerSec = tokenGrant.amount.div(vestingDurationInSecs);
            uint256 amountVested = vestingAmountPerSec.mul(elapsedTime);
            return amountVested;
        }
    }

    /**
     * @notice The balance claimed by `recipient`
     * @param recipient The address that has a grant
     * @return the number of claimed tokens by `recipient`
     */
    function claimedBalance(address recipient) external view returns (uint256) {
        Grant storage tokenGrant = tokenGrants[recipient];
        return tokenGrant.totalClaimed;
    }

    /**
     * @notice Allows a grant recipient to claim their vested tokens
     * @dev Errors if no tokens have vested
     * @dev It is advised recipients check they are entitled to claim via `calculateGrantClaim` before calling this
     * @param recipient The address that has a grant
     */
    function claimVestedTokens(address recipient) external {
        uint256 amountVested = calculateGrantClaim(recipient);
        require(amountVested > 0, "RewardVesting::claimVested: amountVested is 0");

        Grant storage tokenGrant = tokenGrants[recipient];
        tokenGrant.totalClaimed = uint256(tokenGrant.totalClaimed.add(amountVested));
        
        require(rewardToken.transfer(recipient, amountVested), "RewardVesting::claimVested: transfer failed");
        emit GrantTokensClaimed(recipient, amountVested);
    }

    /**
     * @notice Calculate the number of tokens that will vest per day for the given recipient
     * @param recipient The address that has a grant
     * @return Number of tokens that will vest per day
     */
    function tokensVestedPerDay(address recipient) public view returns(uint256) {
        Grant storage tokenGrant = tokenGrants[recipient];
        return tokenGrant.amount.div(uint256(tokenGrant.vestingDuration));
    }

    /**
     * @dev Check if a reward has been earned and if so start vesting
     *
     * Requirements:
     *
     * - the caller must be {caller}
     */
    function onMint(address minter, address to, uint256, uint256 extra) public override {
        require(msg.sender == caller, "RewardVesting::onMint: not caller");
        
        if (minter == to && block.number >= rewardEarnStartBlock && block.number <= rewardEarnEndBlock &&
            extra >= rewardEligibleStartBlock && extra <= rewardEligibleEndBlock) {
            
            if (tokenGrants[to].amount == 0)
                addTokenGrant(to, 0, rewardAmount, rewardVestingDuration, 0);
        }
    }
}
