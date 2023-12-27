// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

pragma solidity ^0.8.20;

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


// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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

// File: blasterreward.sol

/*
Blaster,The First Platform Designed To Optimize Blast Yields And Empower Users Through A Democratic And Transparent Ecosystem.
Integrating With Blast And Leveraging Lido's Staking Services, 
Blaster Offers A Unique Opportunity For Users To Maximize Their Earnings In A Safe And Inclusive Environment.

BLAST YIELD OPTIMIZER HELPS YOU EARN MORE

WEBSITE  :  https://blaster.bot/
TELEGRAM :  https://t.me/BLASTER_Portal
TWITTER/X:  https://twitter.com/BLASTER_2024

- Total supply： 100,000,000
- Tax: 0%
- LP BURNT AND CONTRACT RENOUNCED
$BLASTER Allocation
Liquidity Pool： 40%
Community Rewards：60% 
*/

pragma solidity ^0.8.20;



contract BlasterReward is Ownable {
    event e_Deposit(uint256 value, address from);
    event e_ClaimReward(uint256 value, address from);
    event e_Withdraw(uint256 value, address to);

    error UnauthorizedOracleAccount(address account);
    error UnauthorizedWithdrawAccount(address account);
    error WithdrawAccountIsNotSet();

    // Token for rewards
    address public RewardTokenAddress = address(0);
    uint256 private rewardPercent = 60;

    constructor(address rewardToken) Ownable(msg.sender) {
        require(rewardToken != address(0), "Invalid reward token address");
        RewardTokenAddress = rewardToken;
        require(
            IERC20(RewardTokenAddress).totalSupply() > 0,
            "Invalid reward token supply"
        );
    }

    function initialize() external onlyOwner {
        require(RewardPerDay == 0, "RewardPerDay is already set");
        require(
            IERC20(RewardTokenAddress).balanceOf(msg.sender) >=
                (IERC20(RewardTokenAddress).totalSupply() * rewardPercent) /
                    100,
            "Invalid reward token balance"
        );
        safeTransferFrom(
            RewardTokenAddress,
            msg.sender,
            address(this),
            (IERC20(RewardTokenAddress).totalSupply() * rewardPercent) / 100
        );

        RewardPerDay = balanceOfRewardToken() / 180;
        WithdrawAccount = msg.sender;
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "ERC20: TRANSFER_FROM_FAILED"
        );
    }

    // ============================ Deposit parameters start ============================
    // Deposit will be closed after 180 days(including deploy's day)

    uint256 public StartAt = _getTodayZero(block.timestamp);
    uint256 public EndAt = StartAt + 180 days;
    uint256 public RewardPerDay = 0;

    // totalDeposited records total deposited amount in wei
    uint256 public totalDeposited = 0;

    struct DepositeByDay {
        uint256 totalAmount;
        mapping(address => uint256) Deposites;
    }
    mapping(uint => DepositeByDay) public DepositesMap;
    // ============================ Deposite parameters end ============================


    mapping(address => uint256) public Rewarded;

    mapping(address => uint) public UserRewardedByDay;

    address public WithdrawAccount = address(0);

    // Reward part
    // ClaimRewards:
    // calculate reward amount by day
    function ClaimRewards() external returns (bool) {
        require(RewardPerDay > 0, "RewardPerDay is not set");
        require(totalDeposited > 0, "No deposites");
        (uint256 amount, uint gap) = CalculateReward();
        require(
            balanceOfRewardToken() - amount > 0,
            "Insufficient reward balance"
        );
        if (amount == 0) {
            return false;
        }
        Rewarded[msg.sender] += amount;
        UserRewardedByDay[msg.sender] = gap;

        _claimRewards(amount);

        return true;
    }

    // deposit at day 0, reward at day 1
    // day[i]'s reward = Σ(user's deposites to day[i-1]) * RewardPerDay / Σ(allUser'sDepositByDay to day[i-1])
    // i ∈ (0, 180]
    function CalculateReward() public view returns (uint256 reward, uint gap) {
        gap = _gapDays(block.timestamp, StartAt);
        if (gap > 180) {
            gap = 180;
        }
        uint256 totalDepositedByNow = 0; // total deposited amount from day 0 to day last
        uint256 userTotalDepositedByNow = 0; // user deposited amount from day 0 to day last
        if (UserRewardedByDay[msg.sender] >= 1) {
            for (uint8 i = 0; i < UserRewardedByDay[msg.sender]; i++) {
                userTotalDepositedByNow += DepositesMap[i].Deposites[
                    msg.sender
                ];
                if (DepositesMap[i].totalAmount > 0) {
                    totalDepositedByNow += DepositesMap[i].totalAmount;
                }
            }
        }

        reward = 0;
        for (
            uint8 i = uint8(UserRewardedByDay[msg.sender] + 1);
            i <= gap;
            i++
        ) {
            if (
                DepositesMap[i - 1].totalAmount == 0 && totalDepositedByNow == 0
            ) {
                continue;
            }
            if (DepositesMap[i - 1].totalAmount > 0) {
                totalDepositedByNow += DepositesMap[i - 1].totalAmount;
            }
            userTotalDepositedByNow += DepositesMap[i - 1].Deposites[
                msg.sender
            ];
            reward +=
                (userTotalDepositedByNow * RewardPerDay) /
                totalDepositedByNow;
        }
        return (reward, gap);
    }

    function _claimRewards(uint256 amount) private {
        _transferRewardToken(msg.sender, amount);

        emit e_ClaimReward(amount, msg.sender);

        return;
    }

    // Deposit part
    function Deposit() external payable checkEnd {
        require(msg.value > 0, "Invalid value");

        _recordDeposit(msg.value);

        emit e_Deposit(msg.value, msg.sender);

        return;
    }

    function _recordDeposit(uint256 amount) private {
        totalDeposited += amount;
        uint256 gap = _gapDays(block.timestamp, StartAt);
        DepositesMap[gap].totalAmount += amount;
        DepositesMap[gap].Deposites[msg.sender] += amount;
    }

    function balanceOfRewardToken() public view returns (uint256) {
        return IERC20(RewardTokenAddress).balanceOf(address(this));
    }

    function _transferRewardToken(
        address to,
        uint256 amount
    ) internal returns (bool) {
        return IERC20(RewardTokenAddress).transfer(to, amount);
    }

    function Withdraw(uint256 amount) external withdrawOrOwner returns (bool) {
        require(address(this).balance >= amount, "Insufficient balance");
        bool sent = false;
        if (owner() != address(0)) {
            (sent, ) = owner().call{value: amount}("");
        } else if (WithdrawAccount != address(0)) {
            (sent, ) = WithdrawAccount.call{value: amount}("");
        } else {
            revert WithdrawAccountIsNotSet();
        }
        require(sent, "Failed to withdraw Ether");

        emit e_Withdraw(amount, msg.sender);

        return true;
    }

    function renounceOwnership() public virtual override onlyOwner {
        require(WithdrawAccount != address(0), "WithdrawAccount is not set");

        _transferOwnership(address(0));
    }

    // getters
    function getDepositedAmountByDay(uint day) public view returns (uint256) {
        return DepositesMap[day].totalAmount;
    }

    function getDepositedAmountByDayAndAddress(
        uint day,
        address depositor
    ) public view returns (uint256) {
        return DepositesMap[day].Deposites[depositor];
    }

    // EndAt is set to 180 days after contract creation
    modifier checkEnd() {
        require(block.timestamp < EndAt, "End");
        _;
    }

    function _setWithdraw(address withdraw) public onlyOwner returns (bool) {
        WithdrawAccount = withdraw;
        return true;
    }

    function _checkWithdraw() internal view virtual {
        if (owner() != address(0) && owner() != _msgSender()) {
            revert UnauthorizedWithdrawAccount(_msgSender());
        }
        if (owner() == address(0) && WithdrawAccount != _msgSender()) {
            revert UnauthorizedWithdrawAccount(_msgSender());
        }
    }

    modifier withdrawOrOwner() {
        _checkWithdraw();
        _;
    }

    // date handling
    function _getTodayZero(uint timestamp) private pure returns (uint256) {
        return timestamp - (timestamp % 86400);
    }

    // gapDays returns gap days between timestamp and startAt
   
    function _gapDays(
        uint256 timestamp,
        uint256 startAt
    ) private pure returns (uint256) {
        require(timestamp >= startAt, "Invalid timestamp");
        return (_getTodayZero(timestamp) - startAt) / 86400;
    }

    function getDayGapFromStart() public view returns (uint256) {
        return _gapDays(block.timestamp, StartAt);
    }
}