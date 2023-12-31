// SPDX-License-Identifier: GPL-3.0
// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol

pragma solidity >=0.8.0 <0.9.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

 pragma solidity >=0.8.0 <0.9.0;

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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

 pragma solidity >=0.8.0 <0.9.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

 pragma solidity >=0.8.0 <0.9.0;

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

 pragma solidity >=0.8.0 <0.9.0;


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

// File: SpunkySDX.sol


 pragma solidity >=0.8.0 <0.9.0;

 contract SpunkySDX is Ownable, ReentrancyGuard {
    // Token details
    string public name;
    string public symbol;
    uint8  public _decimals;
    uint256 public totalSupply;

    // Token balances
    mapping(address => uint256) private _balances;
    mapping(address => mapping(uint8 => uint256)) private _allocationBalances;

    // Define the staking plans
    enum StakingPlan {
        ThirtyDays,
        NinetyDays,
        OneEightyDays,
        ThreeSixtyDays,
        Flexible
    }

    // total staked amount
    uint256 private _totalStakedAmount = 0;

    // Define the returns for each plan
    mapping(StakingPlan => uint256) private _stakingPlanReturns;

    // Define the duration for each plan
    mapping(StakingPlan => uint256) private _stakingPlanDurations;

    // Token allowances
    mapping(address => mapping(address => uint256)) private _allowances;

    // staking details
    struct UserStake {
        uint256 index;
        address owner;
        uint256 amount;
        uint256 startTime;
        StakingPlan plan;
        uint256 reward;
        uint256 accruedReward;
        bool isActive;
    }

    UserStake[] private _stakingDetails;

    mapping(address => mapping(StakingPlan => UserStake)) private _userStakes;

    // Vesting details
    mapping(address => VestingDetail[]) private _vestingDetails;

    struct VestingDetail {
        address vestOwner;
        uint256 amount;
        uint256 startTime;
        uint256 cliffDuration;
        uint256 vestingDuration;
        uint256 releasedAmount;
    }
    address[] public vestingAccounts;
    // Fixed price for buying tokens during the presale (in wei per token)
    uint256 public presalePrice = 1;

    AggregatorV3Interface public priceFeed;

    // State to determine if the contract is in presale or launch state
    bool public isPresale = true;

    // Token distribution details
    uint256 private WHITELIST_ALLOCATION = 0;
    uint256 private PRESALE_ALLOCATION = 0;
    uint256 private IEO_ALLOCATION = 0;
    uint256 private AIRDROP_ALLOCATION = 0;
    uint256 private TEAM_ALLOCATION = 0;
    uint256 private STAKING_ALLOCATION = 0;
    uint256 private ECOSYSTEM_DEV_ALLOCATION = 0;
    uint256 private INVESTORS_ALLOCATION = 0;
    uint256 private LIQUIDITY_ALLOCATION = 0;
    uint256 private MAX_BURN = 0;
    uint256 private MAX_BUY_BACK = 0;

    //Staking rewards
    uint256 public totalRewardsGiven = 0;

    // Token burn details
    uint256 public totalBurned;

    // Slippage tolerance, Airdrop
    uint256 public constant SELL_TAX_PERCENTAGE = 5;
    mapping(address => bool) private _airdropRedeemed;
    mapping(address => bool) private _canRedeem;

    // Antibot features
    uint256 private constant MAX_HOLDING_PERCENTAGE = 5;
    uint256 private constant TRANSACTION_DELAY = 2.5 minutes;
    mapping(address => uint256) private _lastTransactionTime;

    //Sell Tax Address
    address public constant SELL_TAX_ADDRESS = 0xF79948ACf0a91bD93513C76651a12291E44D2872;

    //Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Stake(address indexed user, uint256 amount, StakingPlan plan);
    event UpdateStake(address indexed user, uint256 amount, StakingPlan plan);
    event Unstake(address indexed user, uint256 amount, StakingPlan plan);
    event ClaimRewards(address indexed user, uint256 reward);
    event VestingScheduleAdded(
        address indexed account,
        uint256 amount,
        uint256 startTime,
        uint256 cliff,
        uint256 VestedDuration
    );
    event Burn(address indexed account, uint256 amount);
    event TokensReleased(address indexed account, uint256 amount);
    event BuyTokens(uint256 amount);
    event Withdrawn(uint256 amount);

    constructor() {
        name = "SpunkySDX";
        symbol = "SSDX";
        _decimals = 18;
        totalSupply = 500e9 * 10 ** uint256(_decimals);
        // Initially assign all tokens to the contract itself
        _balances[address(this)] = totalSupply;

        //Chainlink Aggregator contract address
        priceFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        );

        // Token distribution details based on total supply
        WHITELIST_ALLOCATION = (totalSupply * 2) / 100; // 2% of total supply
        PRESALE_ALLOCATION = (totalSupply * 20) / 100; // 20% of total supply
        IEO_ALLOCATION = (totalSupply * 8) / 100; // 8% of total supply
        AIRDROP_ALLOCATION = (totalSupply * 4) / 100; // 4% of total supply
        TEAM_ALLOCATION = (totalSupply * 6) / 100; // 6% of total supply
        STAKING_ALLOCATION = (totalSupply * 8) / 100; // 8% of total supply
        ECOSYSTEM_DEV_ALLOCATION = (totalSupply * 7) / 100; // 7% of total supply
        INVESTORS_ALLOCATION = (totalSupply * 5) / 100; // 5% of total supply
        LIQUIDITY_ALLOCATION = (totalSupply * 30) / 100; // 30% of total supply
        MAX_BURN = (totalSupply * 8) / 100; // 10% of total supply
        MAX_BUY_BACK = (totalSupply * 2) / 100; // 2% of total supply

        // Define the returns for each staking plan
        _stakingPlanReturns[StakingPlan.ThirtyDays] = 5;
        _stakingPlanReturns[StakingPlan.NinetyDays] = 10;
        _stakingPlanReturns[StakingPlan.OneEightyDays] = 30;
        _stakingPlanReturns[StakingPlan.ThreeSixtyDays] = 50;
        _stakingPlanReturns[StakingPlan.Flexible] = 1;

        // Initialize the durations for each staking plan
        _stakingPlanDurations[StakingPlan.ThirtyDays] = 30;
        _stakingPlanDurations[StakingPlan.NinetyDays] = 90;
        _stakingPlanDurations[StakingPlan.OneEightyDays] = 180;
        _stakingPlanDurations[StakingPlan.ThreeSixtyDays] = 360;
        _stakingPlanDurations[StakingPlan.Flexible] = 2;

        // Allocate tokens for the whitelist, presale, airdrop and IEO
        _allocationBalances[address(this)][1] = WHITELIST_ALLOCATION;
        _allocationBalances[address(this)][2] = PRESALE_ALLOCATION;
        _allocationBalances[address(this)][3] = IEO_ALLOCATION;
        _allocationBalances[address(this)][4] = AIRDROP_ALLOCATION;
        _allocationBalances[address(this)][5] = TEAM_ALLOCATION;
        _allocationBalances[address(this)][6] = STAKING_ALLOCATION;
        _allocationBalances[address(this)][7] = INVESTORS_ALLOCATION;
        _allocationBalances[address(this)][8] = LIQUIDITY_ALLOCATION;
        _allocationBalances[address(this)][9] = MAX_BURN;
        _allocationBalances[address(this)][10] = ECOSYSTEM_DEV_ALLOCATION;

        uint256 liquidity=LIQUIDITY_ALLOCATION * 17/100;
        _allocationBalances[address(this)][8] -= liquidity; 

        //Transfer Team and IEO allocation to the contract owner
        _transfer(address(this), owner(), IEO_ALLOCATION + TEAM_ALLOCATION +  ECOSYSTEM_DEV_ALLOCATION + INVESTORS_ALLOCATION + MAX_BURN + MAX_BUY_BACK + liquidity);

        emit Transfer(address(0), address(this), totalSupply);
        emit Transfer(address(this), address(this), PRESALE_ALLOCATION);
        emit Transfer(address(this), address(this), AIRDROP_ALLOCATION);
        emit Transfer(address(this), address(this), TEAM_ALLOCATION);
        emit Transfer(address(this), address(this), STAKING_ALLOCATION);      
    }

    function getSymbol() public view returns (string memory) {
        return symbol;
    }

    function getName() public view returns (string memory) {
        return name;
    }

    function getSupply() public view returns (uint256) {
        return totalSupply;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function allocationBalance(
        address account,
        uint8 allocation
    ) public view returns (uint256) {
        require(allocation >= 1 && allocation <= 6, "Invalid allocation");
        return _allocationBalances[account][allocation];
    }

    function transfer(
        address recipient,
        uint256 amount
    )
        public
        nonReentrant
        checkTransactionDelay
        checkMaxHolding(recipient, amount)
        returns (bool)
    {
        if (isSellTransaction(recipient)) {
            uint256 taxAmount = (amount * SELL_TAX_PERCENTAGE) / 100;
            amount -= taxAmount;
            _transfer(msg.sender, SELL_TAX_ADDRESS, taxAmount);
        }
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public checkMaxHolding(spender, amount) returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public checkMaxHolding(recipient, amount) returns (bool) {
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(
            amount <= currentAllowance,
            "ERC20: transfer amount exceeds allowance"
        );
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public checkMaxHolding(spender, addedValue) returns (bool) {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public checkMaxHolding(spender, subtractedValue) returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(
            subtractedValue <= currentAllowance,
            "ERC20: decreased allowance below zero"
        );
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: transfer amount must be greater than zero");
        require(_balances[sender] >= amount, "ERC20: insufficient balance");

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setCanRedeemAirdrop(
        address[] calldata airdropRecipients,
        bool canRedeem
    ) external nonReentrant onlyOwner {
        for (uint256 i = 0; i < airdropRecipients.length; i++) {
            _canRedeem[airdropRecipients[i]] = canRedeem;
        }
    }

    function redeemAirdrop(
        uint256 amount
    )
        external
        nonReentrant
        checkMaxHolding(msg.sender, amount)
        checkIsAirDropReedemable
    {
        require(!_airdropRedeemed[msg.sender], "Airdrop already redeemed");
        require(amount > 0, "Invalid amount");
        require(
            _allocationBalances[address(this)][4] >= amount,
            "No airdrop balance available"
        );
        _airdropRedeemed[msg.sender] = true;
        _allocationBalances[address(this)][4] -= amount;
        uint256 immediateAmount = (amount * 2) / 100; // 2% sent to users
        uint256 vestedAmount = (amount * 98) / 100; // 98% vested for users
        uint256 cliffDuration = 30 days * 6; // 6 months cliff
        uint256 vestingDuration = 30 days * 98; // 1 percent per month
        _transfer(address(this), msg.sender, immediateAmount);
        addVestingSchedule(
            msg.sender,
            vestedAmount,
            cliffDuration,
            vestingDuration
        );
    }

    function addVestByOwner(
        address account,
        uint256 amount,
        uint256 cliffDuration,
        uint256 vestingDuration
    ) public onlyOwner {
        _transfer(msg.sender, address(this), amount);
        addVestingSchedule(account, amount, cliffDuration, vestingDuration);
    }

    function addVestingSchedule(
        address account,
        uint256 amount,
        uint256 cliffDuration,
        uint256 vestingDuration
    ) internal {
        // i removed the nonReentrant onthis function since it internal
        require(account != address(0), "Invalid account");
        require(amount > 0, "Invalid amount");
        require(
            cliffDuration < vestingDuration,
            "Cliff duration must be less than vesting duration"
        );
        require(
            _balances[owner()] >= amount,
            "Owner does not have enough balance"
        );
        VestingDetail memory newVesting = VestingDetail({
            vestOwner: msg.sender,
            amount: amount,
            startTime: block.timestamp,
            cliffDuration: cliffDuration,
            vestingDuration: vestingDuration,
            releasedAmount: 0
        });
        _vestingDetails[account].push(newVesting);
        emit VestingScheduleAdded(
            account,
            amount,
            block.timestamp,
            cliffDuration,
            vestingDuration
        );
    }

    // Function to release vested tokens
    function releaseVestedTokens(address account) public nonReentrant {
        require(account != address(0), "Invalid account");
        VestingDetail[] storage vestingDetails = _vestingDetails[account];
        for (uint256 i = 0; i < vestingDetails.length; i++) {
            VestingDetail storage vesting = vestingDetails[i];
            if (
                vesting.amount > 0 &&
                vesting.amount > vesting.releasedAmount &&
                block.timestamp >= vesting.startTime + vesting.cliffDuration
            ) {
                release(account, vesting);
            }
        }
    }

    // Internal function to release vested tokens for a specific vesting detail
    function release(address account, VestingDetail storage vesting) internal {
        require(
            block.timestamp >= vesting.startTime + vesting.cliffDuration,
            "Cliff period has not ended"
        );

        require(
            vesting.releasedAmount < vesting.amount,
            "No tokens to release"
        );

        uint256 elapsedTime = block.timestamp -
            (vesting.startTime + vesting.cliffDuration);

        // If elapsed time is greater than vesting duration, set it equal to vesting duration
        elapsedTime = (elapsedTime > vesting.vestingDuration)
            ? vesting.vestingDuration
            : elapsedTime;

        // Calculate the total vested amount till now
        uint256 totalVestedAmount = (vesting.amount * elapsedTime) /
            vesting.vestingDuration;

        // Calculate the amount that is yet to be released
        uint256 unreleasedAmount = totalVestedAmount - vesting.releasedAmount;

        require(unreleasedAmount > 0, "No tokens to release");

        // Update the released amount
        vesting.releasedAmount += unreleasedAmount;

        // Transfer the tokens
        _transfer(address(this), account, unreleasedAmount);

        emit TokensReleased(account, unreleasedAmount);
    }

    function getNumberOfVestingSchedules(
        address account
    ) public view returns (uint256) {
        return _vestingDetails[account].length;
    }

    function getVestingDetails(
        address account
    ) public view returns (VestingDetail[] memory) {
        return _vestingDetails[account];
    }

    function calculateStakingReward(
        uint256 amount,
        StakingPlan plan
    ) internal view returns (uint256) {
        require(amount > 0, "Invalid staking amount");
        uint256 rewardPercentage = _stakingPlanReturns[plan];
        uint256 daysRequired = _stakingPlanDurations[plan];

        if (plan == StakingPlan.Flexible) {
            return 0;
        } else {
            return (amount * rewardPercentage * daysRequired) / (1000 * 365);
        }
    }

    function calculateAccruedReward(
        uint256 amount,
        StakingPlan plan
    ) internal view returns (uint256) {
        require(amount > 0, "Invalid staking amount");
        uint256 startTime = _userStakes[msg.sender][plan].startTime;
        uint256 rewardPercentage = _stakingPlanReturns[plan];
        uint256 elapseTime = block.timestamp - startTime;
        uint256 durationInSeconds = _stakingPlanDurations[plan] * 1 days;
        uint256 secondsInAYear = 365 * 1 days;

        if (elapseTime > durationInSeconds && plan != StakingPlan.Flexible) {
            elapseTime = durationInSeconds;
        }

        // Total days accrued in relation to 365 days (1 year);
        return
            (amount * rewardPercentage * elapseTime) / (1000 * secondsInAYear);
    }

    function stake(
        uint256 amount,
        StakingPlan plan
    ) external nonReentrant checkMaxHolding(msg.sender, amount) {
        require(amount > 0, "The staking amount must be greater than zero.");
        UserStake storage userStake = _userStakes[msg.sender][plan];
        require(
            userStake.amount == 0,
            "user alread staking add to your stake or unstake"
        );
        require(!userStake.isActive, "Plan is already active");

        uint256 reward = calculateStakingReward(amount, plan);

        require(
            _allocationBalances[address(this)][6] >= reward,
            "Staking rewards exhausted"
        );

        _transfer(msg.sender, address(this), amount);

        _totalStakedAmount += amount;

        _allocationBalances[address(this)][6] -= reward; // Decrement the staking allocation balance

        // update stake and push into an array
        userStake.owner = msg.sender;
        userStake.amount = amount;
        userStake.startTime = block.timestamp;
        userStake.plan = plan;
        userStake.reward = reward;
        userStake.accruedReward = 0;
        userStake.index = _stakingDetails.length;
        userStake.isActive = true;

        _stakingDetails.push(userStake);

        emit Stake(msg.sender, amount, plan);
    }

    function addToStake(
        uint256 additionalAmount,
        StakingPlan plan
    ) external nonReentrant {
        require(additionalAmount > 0, "Invalid additional staking amount");
        UserStake storage userStake = _userStakes[msg.sender][plan];
        require(userStake.amount > 0, "No existing stake found");

        // Calculate the new accrued reward
        uint256 newAccruedReward = calculateAccruedReward(
            userStake.amount,
            plan
        );

        require(
            _allocationBalances[address(this)][6] >= newAccruedReward,
            "Staking rewards exhausted"
        );

        // adjust allocation balance to update
        _allocationBalances[address(this)][6] -= newAccruedReward;

        // Update the staking state
        userStake.accruedReward += newAccruedReward;
        userStake.amount += additionalAmount;
        userStake.startTime = block.timestamp;
        _totalStakedAmount += additionalAmount;

        // Transfer the additional staked amount from the user to the contract
        _transfer(msg.sender, address(this), additionalAmount);

        // update staking details in the array
        uint256 detailsIndex = userStake.index;
        _stakingDetails[detailsIndex].accruedReward = newAccruedReward;
        _stakingDetails[detailsIndex].amount += additionalAmount;
        _stakingDetails[detailsIndex].startTime = block.timestamp;

        // emit update
        emit UpdateStake(msg.sender, userStake.amount, plan);
    }

    function claimReward(StakingPlan plan) internal returns (uint256) {
        require(msg.sender != owner(), "Owner cannot stake");

        // Load the user's stake details into memory
        UserStake memory userStake = _userStakes[msg.sender][plan];

        // Ensure the user has a valid stake
        require(userStake.amount > 0, "No staking balance available");

        // Calculate the initial reward (plan reward + accrued reward)
        uint256 reward = userStake.reward + userStake.accruedReward;

        // Handle flexible plans differently
        if (plan == StakingPlan.Flexible) {
            uint256 addedReward = calculateAccruedReward(
                userStake.amount,
                plan
            );

            // Ensure there's enough in the reward pool
            if (_allocationBalances[address(this)][6] >= addedReward) {
                _allocationBalances[address(this)][6] -= addedReward;
                reward += addedReward;
            } else {
                reward += _allocationBalances[address(this)][6];
                _allocationBalances[address(this)][6] = 0;
            }
        }

        return reward;
    }

    function userClaimReward(StakingPlan plan) external nonReentrant {
        // Retrieve the user's stake details from storage
        UserStake storage userStake = _userStakes[msg.sender][plan];

        // Calculate the duration condition for reward claiming
        bool isAfterPlanDuration = block.timestamp >=
            userStake.startTime + _stakingPlanDurations[plan] * 1 days;

        // Ensure the user is allowed to claim the reward
        require(
            isAfterPlanDuration,
            "Cannot claim rewards before the staking duration expires"
        );

        // Retrieve the total reward for the user
        uint256 reward = claimReward(plan);

        // Transfer the reward to the user
        _transfer(address(this), msg.sender, reward);

        // Reset the accrued reward and startTime for the user
        userStake.accruedReward = 0;
        userStake.startTime = block.timestamp;

        // Update the stakingDetails array to reflect the new accruedReward and startTime
        _stakingDetails[userStake.index].accruedReward = 0;
        _stakingDetails[userStake.index].startTime = block.timestamp;

        // Emit a ClaimRewards event
        emit ClaimRewards(msg.sender, reward);
    }

    function removeStakeFromArray(StakingPlan plan) internal {
        // Retrieve the stake details for the user
        UserStake storage userStake = _userStakes[msg.sender][plan];

        // Ensure the user has an active stake for this plan
        require(userStake.isActive, "You don't have a stake for this plan");

        // Get the last index in the staking details array
        uint256 lastIndex = _stakingDetails.length - 1;

        // If the stake to be removed is not the last one, swap it with the last one
        if (userStake.index != lastIndex) {
            UserStake memory swappedStake = _stakingDetails[lastIndex];

            // Perform the swap
            _stakingDetails[userStake.index] = swappedStake;

            // Update the index for the stake that was moved
            _userStakes[swappedStake.owner][swappedStake.plan].index = userStake
                .index;
        }

        // Remove the last element (which is now the element to be removed)
        _stakingDetails.pop();

        // Delete the user's stake information
        delete _userStakes[msg.sender][plan];
    }

    function unstake(StakingPlan plan) external nonReentrant {
        require(msg.sender != owner(), "Owner can not stake");
        UserStake storage userStake = _userStakes[msg.sender][plan];
        require(userStake.amount > 0, "No staking balance available");

        bool isAfterPlanDuration = block.timestamp >=
            userStake.startTime + _stakingPlanDurations[plan] * 1 days;

        uint256 reward = claimReward(plan);

        if (!isAfterPlanDuration) {
            _allocationBalances[address(this)][6] +=
                userStake.reward +
                userStake.accruedReward;
            reward = 0;
        }

        _transfer(address(this), msg.sender, userStake.amount + reward); // transfer only amount to user
        _totalStakedAmount -= userStake.amount; //adjust the totalStakedAmount

        emit Unstake(msg.sender, userStake.amount, plan);

        removeStakeFromArray(plan); // removing from staking Details array
    }

    function getCanClaimStakingReward(
        StakingPlan plan
    ) external view returns (bool) {
        uint256 stakingStartTime = _userStakes[msg.sender][plan].startTime;
        bool isAfterPlanDuration = block.timestamp >=
            stakingStartTime + _stakingPlanDurations[plan] * 1 days;
        return isAfterPlanDuration;
    }

    function getIsStakingActive(StakingPlan plan) external view returns (bool) {
        return _userStakes[msg.sender][plan].isActive;
    }

    function getStakingDetailsCount() external view returns (uint256) {
        return _stakingDetails.length;
    }

    function getTotalStakedAmount() external view returns (uint256) {
        return _totalStakedAmount;
    }

    function getStakingBalance(
        StakingPlan plan
    ) external view returns (uint256) {
        return _userStakes[msg.sender][plan].amount;
    }

    function getStakingReward(
        StakingPlan plan
    ) external view returns (uint256) {
        // Fetch the user's stake details
        UserStake memory userStake = _userStakes[msg.sender][plan];

        // If the plan is not active for the user, return zero
        if (!userStake.isActive) {
            return 0;
        }

        // If the allocation balance is zero, return the accrued reward
        if (_allocationBalances[address(this)][6] == 0) {
            return userStake.accruedReward;
        }

        // Otherwise, calculate the total reward
        uint256 additional = calculateAccruedReward(userStake.amount, plan);
        return userStake.accruedReward + additional;
    }

    function getAllStakingBalances(
        address user
    ) public view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](5); // Assuming 5 plans
        balances[0] = _userStakes[user][StakingPlan.ThirtyDays].amount;
        balances[1] = _userStakes[user][StakingPlan.NinetyDays].amount;
        balances[2] = _userStakes[user][StakingPlan.OneEightyDays].amount;
        balances[3] = _userStakes[user][StakingPlan.ThreeSixtyDays].amount;
        balances[4] = _userStakes[user][StakingPlan.Flexible].amount;
        return balances;
    }

    function getStakingDetailsPage(
        uint256 start,
        uint256 end
    ) public view returns (UserStake[] memory) {
        // Validate the indices
        require(
            start <= end && end < _stakingDetails.length,
            "Invalid indices"
        );

        // Create a new array to hold the range of UserStakes
        UserStake[] memory page = new UserStake[](end - start + 1);

        // Loop through the _stakingDetails array and populate the 'page' array
        for (uint256 i = start; i <= end; i++) {
            page[i - start] = _stakingDetails[i];
        }

        // Return the 'page' array
        return page;
    }

    function isSellTransaction(address recipient) internal view returns (bool) {
        return recipient == address(this);
    }

    function burn(uint256 amount) public onlyOwner {
        require(
            totalBurned + amount <= MAX_BURN,
            "Total burned exceeds max burn amount"
        );
        require(amount <= _balances[msg.sender], "Not enough tokens to burn");
        _balances[msg.sender] -= amount;
        totalSupply -= amount;
        totalBurned += amount;
        emit Transfer(msg.sender, address(0), amount);
        emit Burn(msg.sender, amount);
    }

    function buyTokens()
        internal
        checkMaxHolding(msg.sender, balanceOf(msg.sender))
    {
        require(msg.value > 0, "No Ether sent");
        require(msg.sender != owner(), "Contract owner cannot participate");

        // Check if the presale is ongoing
        if (isPresale == true) {
            uint256 ethPrice = getETHPrice(); // Get the current ETH price in USD
            require(msg.sender != owner(), "Contract owner cannot participate");
            uint256 tokensToBuy = (msg.value * ethPrice * presalePrice) / 10000;

            // Check if the presale allocation is sufficient
            require(
                _allocationBalances[address(this)][2] >= tokensToBuy,
                "Not enough presale tokens available"
            );

            // Calculate vested amounts
            uint256 immediateReleaseAmount = (tokensToBuy * 1) / 4;
            uint256 vestedAmount = (tokensToBuy * 3) / 4; // 75%

            // Update the presale allocation
            _allocationBalances[address(this)][2] -= tokensToBuy;

            // Transfer the immediate release portion to buyer
            _transfer(address(this), msg.sender, immediateReleaseAmount);

            // Set up the vesting schedule for the user's vested amount, over 5 months
            uint256 cliffDuration = 0; // No cliff for presale
            uint256 vestingDuration = 30 days * 5; // 5 months
            addVestingSchedule(
                msg.sender,
                vestedAmount,
                cliffDuration,
                vestingDuration
            );
            emit BuyTokens(_allocationBalances[address(this)][2]);
        } else {
            // If the presale is over, refund the Ether
            payable(msg.sender).transfer(msg.value);
        }
    }

    receive() external payable {
        buyTokens();
    }

    function getETHPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        require(price > 0, "Invalid price feed");
        return uint256(price);
    }

    function withdrawToken(
        address tokenAddress,
        uint256 tokenAmount
    ) external onlyOwner {
        require(isPresale == false, "Presale has ended");

        IERC20 token = IERC20(tokenAddress);
        require(
            token.balanceOf(address(this)) >= tokenAmount,
            "Not enough tokens in the contract or owner cannot withdraw tokens in contract"
        );
        require(
            tokenAddress != address(this),
            "Owner cannot withdraw SSDX tokens in contract"
        );
        token.transfer(owner(), tokenAmount);
    }

    function withdraw() external onlyOwner {
       require(isPresale == false, "Presale is still active");

       uint256 amount = address(this).balance;
       payable(owner()).transfer(amount);

       emit Withdrawn(amount);
    }

    function endPresale() external onlyOwner {
        isPresale = false;
    }

    function renounceOwnership() public override onlyOwner {
        // Prevent renouncing ownership if there are staking rewards available
        super.renounceOwnership();
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        require(
            _userStakes[msg.sender][StakingPlan.ThirtyDays].reward == 0,
            "Staking rewards must be claimed before renouncing ownership"
        );
        require(
            _userStakes[msg.sender][StakingPlan.NinetyDays].reward == 0,
            "Staking rewards must be claimed before renouncing ownership"
        );
        require(
            _userStakes[msg.sender][StakingPlan.OneEightyDays].reward == 0,
            "Staking rewards must be claimed before renouncing ownership"
        );
        require(
            _userStakes[msg.sender][StakingPlan.ThreeSixtyDays].reward == 0,
            "Staking rewards must be claimed before renouncing ownership"
        );
        require(
            _userStakes[msg.sender][StakingPlan.Flexible].reward == 0,
            "Staking rewards must be claimed before renouncing ownership"
        );
        super.transferOwnership(newOwner);
    }

    function getStakingAllocation() public view returns (uint256) {
        return _allocationBalances[address(this)][6];
    }

    function getPresaleState() public view returns (bool) {
        return isPresale;
    }

    function getPresalePrice() public view returns (uint256) {
        return presalePrice;
    }

    function getPresaleAllocation() public view returns (uint256) {
        return _allocationBalances[address(this)][2];
    }

    function getAirdropAllocation() public view returns (uint256) {
        return _allocationBalances[address(this)][4];
    }

    function getTotalBurned() public view returns (uint256) {
        return totalBurned;
    }

    function getTotalRewardsGiven() public view returns (uint256) {
        return totalRewardsGiven;
    }

    function getMaxBurn() public view returns (uint256) {
        return MAX_BURN;
    }

    function getCanRedeem() public view returns (bool) {
        return _canRedeem[msg.sender];
    }

    function getHasRedeemed() public view returns (bool) {
        return _airdropRedeemed[msg.sender];
    }

    modifier checkTransactionDelay() {
        require(
            _lastTransactionTime[msg.sender] + TRANSACTION_DELAY <=
                block.timestamp,
            "Transacation cooldown period has not passed"
        );
        _lastTransactionTime[msg.sender] = block.timestamp;
        _;
    }
    modifier checkMaxHolding(address recipient, uint256 amount) {
        if (recipient != address(this) && recipient != owner()) {
            require(
                (_balances[recipient] + amount) <=
                    ((totalSupply * MAX_HOLDING_PERCENTAGE) / 100),
                "Recipient's token holding exceeds the maximum allowed percentage"
            );
        }
        _;
    }
    modifier checkStakingRewards(uint256 reward) {
        require(
            totalRewardsGiven + reward <= STAKING_ALLOCATION,
            "Total staking rewards exceeded"
        );
        _;
    }
    modifier checkIsAirDropReedemable() {
        require(
            _canRedeem[msg.sender] == true,
            "You are not whitelisted for airdop"
        );
        _;
    }
}