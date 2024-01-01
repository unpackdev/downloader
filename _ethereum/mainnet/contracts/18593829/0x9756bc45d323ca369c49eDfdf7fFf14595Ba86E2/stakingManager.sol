pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}


pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}



pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts\staking.sol

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;


contract stakingManager is Ownable {

    IERC20 public stakeToken; // Token to be staked and rewarded

    uint256 public tokensStaked; // Total tokens staked

    uint256 private lastRewardedBlock; // Last block number the user had their rewards calculated
    uint256 private accumulatedRewardsPerShare; // Accumulated rewards per share times REWARDS_PRECISION
    uint256 public rewardTokensPerBlock; // Number of reward tokens minted per block
    uint256 private constant REWARDS_PRECISION = 1e12; // A big number to perform mul and div operations
    uint256 public feeAmt = 25;

    uint256 public lockedTime; //To lock the tokens in contract for definite time.
    bool public harvestLock; //To lock the harvest/claim.
    bool public initialized;
    uint public endBlock; //At this block,the rewards generation will be stopped.

    // Staking user for a pool
    struct PoolStaker {
        uint256 amount; // The tokens quantity the user has staked.
        uint256 stakedTime; //the time at tokens staked
        uint256 lastUpdatedBlock;
        uint256 Harvestedrewards; // The reward tokens quantity the user  harvested
        uint256 rewardDebt; // The amount relative to accumulatedRewardsPerShare the user can't get as reward
    }

    //  staker address => PoolStaker
    mapping(address => PoolStaker) public poolStakers;

    mapping(address => uint) public userLockedRewards;
    uint256 public claimStart;

    address marketing;

    // Events
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event HarvestRewards(address indexed user, uint256 amount);
    event Compound(address indexed user, uint256 amount);

    constructor(address _marketing) public Ownable() {
        rewardTokensPerBlock = 45500000000000000000;
        lastRewardedBlock = block.number;
        marketing = _marketing;
        lockedTime = 86400 * 3;
        endBlock = block.number + 439560;
        claimStart = block.number + 20;
    }

    /**
     * @dev Deposit tokens to the pool
     */
    function deposit(uint256 _amount) external isInitialized {
        require(block.number < endBlock, "staking has been ended");
        require(_amount > 0, "Deposit amount can't be zero");

        PoolStaker storage staker = poolStakers[msg.sender];

        // Update pool stakers
        harvestRewards();

        // Update current staker
        staker.amount += _amount;
        staker.rewardDebt =
            (staker.amount * accumulatedRewardsPerShare) /
            REWARDS_PRECISION;
        staker.stakedTime = block.timestamp;
        staker.lastUpdatedBlock = block.number;

        // Update pool
        tokensStaked += _amount;

        // Deposit tokens
        emit Deposit(msg.sender, _amount);
        stakeToken.transferFrom(msg.sender, address(this), _amount);
    }

    function compound() external isInitialized {
        require(block.number < endBlock, "staking has been ended");
        PoolStaker storage staker = poolStakers[msg.sender];
        require(
            staker.stakedTime + lockedTime <= block.timestamp &&
                claimStart + lockedTime <= block.timestamp,
            "you are not allowed to withdraw before locked Time"
        );
        updatePoolRewards();

        // Update pool stakers
        uint256 rewardsToHarvest = ((staker.amount * accumulatedRewardsPerShare) / REWARDS_PRECISION) - staker.rewardDebt;
        if (rewardsToHarvest == 0) {
            return;
        }


        require(!harvestLock, "Cannot compound if locked");
            if (userLockedRewards[msg.sender] > 0) {
                rewardsToHarvest += userLockedRewards[msg.sender];
                userLockedRewards[msg.sender] = 0;
            }

            staker.amount += rewardsToHarvest;
            tokensStaked += rewardsToHarvest;
            staker.Harvestedrewards += rewardsToHarvest;
            staker.rewardDebt = (staker.amount * accumulatedRewardsPerShare) / REWARDS_PRECISION;
            emit Compound(msg.sender, rewardsToHarvest);

    }

    /**
     * @dev Withdraw all tokens from existing pool
     */
    function withdraw() external isInitialized {
        PoolStaker memory staker = poolStakers[msg.sender];
        uint256 amount = staker.amount;
        require(
            staker.stakedTime + lockedTime <= block.timestamp &&
                claimStart + lockedTime <= block.timestamp,
            "you are not allowed to withdraw before locked Time"
        );
        require(amount > 0, "Withdraw amount can't be zero");

        // Pay rewards
        harvestRewards();

        //delete staker
        delete poolStakers[msg.sender];

        // Update pool
        tokensStaked -= amount;

        uint256 fee = amount * feeAmt / 1000;

        // Withdraw tokens
        emit Withdraw(msg.sender, amount - fee);
        stakeToken.transfer(marketing, fee);
        stakeToken.transfer(msg.sender, amount - fee);
    }

    /**
     * @dev Harvest user rewards
     */
    function harvestRewards() public isInitialized {
        _harvestRewards(msg.sender);
    }

    /**
     * @dev Harvest user rewards
     */
    function _harvestRewards(address _user) private {
        updatePoolRewards();
        PoolStaker storage staker = poolStakers[_user];
        uint256 rewardsToHarvest = ((staker.amount *
            accumulatedRewardsPerShare) / REWARDS_PRECISION) -
            staker.rewardDebt;
        if (rewardsToHarvest == 0) {
            return;
        }

        staker.Harvestedrewards += rewardsToHarvest;
        staker.rewardDebt =
            (staker.amount * accumulatedRewardsPerShare) /
            REWARDS_PRECISION;
        if (!harvestLock) {
            if (userLockedRewards[_user] > 0) {
                rewardsToHarvest += userLockedRewards[_user];
                userLockedRewards[_user] = 0;
            }
            uint256 fee = rewardsToHarvest * feeAmt / 1000;
            emit HarvestRewards(_user, rewardsToHarvest - fee);
            stakeToken.transfer(marketing, fee);
            stakeToken.transfer(_user, rewardsToHarvest - fee);
        } else {
            userLockedRewards[_user] += rewardsToHarvest;
        }
    }

    /**
     * @dev Update pool's accumulatedRewardsPerShare and lastRewardedBlock
     */
    function updatePoolRewards() private {
        if (tokensStaked == 0) {
            lastRewardedBlock = block.number;
            return;
        }
        uint256 blocksSinceLastReward = block.number > endBlock
            ? endBlock - lastRewardedBlock
            : block.number - lastRewardedBlock;
        uint256 rewards = blocksSinceLastReward * rewardTokensPerBlock;
        accumulatedRewardsPerShare =
            accumulatedRewardsPerShare +
            ((rewards * REWARDS_PRECISION) / tokensStaked);
        lastRewardedBlock = block.number > endBlock ? endBlock : block.number;
    }

    /**
     *@dev To get the number of rewards that user can get
     */
    function getRewards(address _user) public view returns (uint) {
        if (tokensStaked == 0) {
            return 0;
        }
        uint256 blocksSinceLastReward = block.number > endBlock
            ? endBlock - lastRewardedBlock
            : block.number - lastRewardedBlock;
        uint256 rewards = blocksSinceLastReward * rewardTokensPerBlock;
        uint256 accCalc = accumulatedRewardsPerShare +
            ((rewards * REWARDS_PRECISION) / tokensStaked);
        PoolStaker memory staker = poolStakers[_user];
        return
            ((staker.amount * accCalc) / REWARDS_PRECISION) -
            staker.rewardDebt +
            userLockedRewards[_user];
    }

    function setHarvestLock(bool _harvestlock) external onlyOwner {
        harvestLock = _harvestlock;
    }

    function setStakeToken(address _stakeToken) external onlyOwner {
        require(!initialized, "Cannot change stake token");
        require(IERC20(_stakeToken).balanceOf(address(this)) > 0, "Insufficient funds");
        initialized = true;
        stakeToken = IERC20(_stakeToken);
    }

    function updateRewardsPerBlock(uint256 newRewards) external onlyOwner {
        require(newRewards > 0, "cannot set rewards to zero");
        rewardTokensPerBlock = newRewards;
    }

    function setLockedTime(uint _time) external onlyOwner {
        lockedTime = _time;
    }

    function setEndBlock(uint _endBlock) external onlyOwner {
        require(_endBlock > block.number, "cannot end in the past");
        endBlock = _endBlock;
    }

    function setClaimStart(uint _claimStart) external onlyOwner {
        claimStart = _claimStart;
    }

    function changeFee(uint256 newFee) external onlyOwner {
        require(newFee <= 100, "cannot charge more tax");
        feeAmt = newFee;
    }

    modifier isInitialized() {
        require(initialized, "ERROR");
        _;
    }

}