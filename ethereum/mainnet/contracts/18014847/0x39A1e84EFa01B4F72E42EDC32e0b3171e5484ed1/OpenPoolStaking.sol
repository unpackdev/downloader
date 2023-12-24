// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @title SafeMathInt
 * @dev Math operations for int256 with overflow safety checks.
 */
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }


    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

/**
 * @title SafeMathUint
 * @dev Math operations with safety checks that revert on error
 */
library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}

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

/*

OpenPool Staking

A simple drip feed staking contract which takes deposits in OpenPool Lp token, and gives you a set 
Ethereum claimable amount per block while you are locked. 

This is a V1 Staking contract for OpenPool LP, this is unaudited software so use at your own risk. 
A V2 contract will be released 1-2 weeks after V1 and will be audited, users will be recommended 
to move to that pool, When the V2 contract is deployed this contract will be discontinued by shutting off 
staking deposits via the stake_lockdown function. Withdraws will remain open, and funds will be added while users are staked.

There is a Bad Actor mapping to tag users who potentially are looking to game the contract, we are watching, you will be seen.
Play Nice, you get one warning.

*/





contract OpenPoolStaking is Ownable, ReentrancyGuard {


    struct StakingDetails {
        uint256 amount;
        uint256 deposit_time;
        uint256 unlock_time;
        uint256 last_claim_time;
        bool participant;
    }

    using SafeMath for uint256;

    address public LP_token_address;
    IERC20 public LP_token;

    uint256 public locking_period;

    bool public claim_enabled = false;
    bool public lock_enabled = true;
    bool public stake_lockdown = true;

 

    uint256 public total_lp_tokens;
    uint256 public depositors;
    uint256 public eth_per_block;
    uint check_threshold = 500;

    bool public emergencyMeasures = false;

    uint256 minThreshold = 1000000000000000000;

    event RewardsAdded(uint256 deposit_amount, uint256 time);
    event RunningLowOnRewards(uint256 left_remaining, uint256 time);
    event Claimed(address account, uint256 amount_due, uint256 time);
    event LargeDeposit(address account, uint256 amount, uint256 time);

    mapping(address => StakingDetails) public stake_details;
    mapping(address => bool) public BadActor;

    constructor(address _pair, uint256 block_reward) {
        LP_token = IERC20(_pair);
        LP_token_address = _pair;

        eth_per_block = block_reward;
        locking_period = 604800;
    }

    receive() external payable {}

    function returnLPbalance() public view returns (uint256) {
        return LP_token.balanceOf(address(this));
    }

    function returnETHbalance() public view returns (uint256) {
        return address(this).balance;
    }

    function fetchEthPerBlock() internal view returns (uint256) {
        return eth_per_block;
    }

    function UpdateAllSettings(
        bool claim_state,
        bool lock_state,
        bool stake_lock_state
    ) public onlyOwner {
        enable_claim(claim_state);
        toggle_lock(lock_state);
        toggle_stake_lock(stake_lock_state);
    }

    function init() public onlyOwner {
        enable_claim(true);
        toggle_lock(true);
        toggle_stake_lock(false);
    }

    function emergencymeasuresstate(bool state) public onlyOwner {
        emergencyMeasures = state;
    }

    function DepositRewards() public payable onlyOwner {
        emit RewardsAdded(msg.value, block.timestamp);
    }

    function enable_claim(bool state) public onlyOwner {
        claim_enabled = state;
    }

    function declare_bad_actor(address account, bool state) public onlyOwner {
        BadActor[account] = state;
    }

    function changeEthPerBock(uint256 newvalue) public onlyOwner {
        eth_per_block = newvalue;
    }

    function changeLockingPeriod(uint256 newtime) public onlyOwner {
        require(newtime <= 500000, "Can't set lock longer then 2 months");
        locking_period = newtime;
    }

    // if there is a deposit lock for 2 weeks
    function toggle_lock(bool state) public onlyOwner {
        lock_enabled = state;
    }

    // deposits on/off
    function toggle_stake_lock(bool state) public onlyOwner {
        stake_lockdown = state;
    }

    function change_threshold(uint amount) public onlyOwner {
        check_threshold = amount;
    }

    // have to approve the vault on the pair contract first
    function Deposit_LP(uint256 amount) public nonReentrant {
        require(stake_lockdown == false, " cannot stake at this time ");
        require(!BadActor[msg.sender]);
        require(amount > 0);
        amount = amount * 10**18;
        if(amount > check_threshold){
            emit LargeDeposit(msg.sender, amount, block.timestamp);
        }
        if (stake_details[msg.sender].participant == true) {
            if(claim_enabled){
            internalClaim(msg.sender); }
            stake_details[msg.sender].amount += amount;
            LP_token.transferFrom(msg.sender, address(this), amount);
            total_lp_tokens += amount;
        } else {
            bool success = LP_token.transferFrom(
                msg.sender,
                address(this),
                amount
            );
            require(success);
            depositors += 1;

            stake_details[msg.sender].amount += amount;

            stake_details[msg.sender].participant = true;

            stake_details[msg.sender].deposit_time = block.timestamp;

            stake_details[msg.sender].last_claim_time = block.timestamp;

            stake_details[msg.sender].unlock_time =
                block.timestamp +
                locking_period;

            total_lp_tokens += amount;
        }
    }

    function WithdrawLP() public nonReentrant {
        require(stake_details[msg.sender].participant == true);
        require(!BadActor[msg.sender]);
        if (lock_enabled) {
            require(
                stake_details[msg.sender].deposit_time + locking_period <=
                    block.timestamp,
                "your still locked wait until block.timestamp is later then your lock period"
            );
        }

        if (stake_details[msg.sender].last_claim_time < block.timestamp) {
            if(claim_enabled){
            internalClaim(msg.sender);
            }
        }

        stake_details[msg.sender].participant = false;
        depositors -= 1;
        bool success = LP_token.transfer(
            msg.sender,
            stake_details[msg.sender].amount
        );
        require(success);
        total_lp_tokens -= stake_details[msg.sender].amount;
        stake_details[msg.sender].amount = 0;
        
    }

    function EmergencyUnstake() public nonReentrant {
        require(emergencyMeasures == true, "can only use in emergency state");
        require(stake_details[msg.sender].participant == true);
        require(!BadActor[msg.sender]);
        if (lock_enabled) {
            require(
                stake_details[msg.sender].deposit_time + locking_period <=
                    block.timestamp,
                "your still locked wait until block.timestamp is later then your lock period"
            );
        }
        stake_details[msg.sender].participant = false;
        depositors -= 1;
        bool success = LP_token.transfer(
            msg.sender,
            stake_details[msg.sender].amount
        );
        require(success);
        total_lp_tokens -= stake_details[msg.sender].amount;
        stake_details[msg.sender].amount = 0;
    }

    function internalClaim(address account) private {
        require(claim_enabled, " claim has not been enabled yet ");
        require(
            stake_details[account].participant == true,
            " not recognized as acive staker"
        );
        require(
            block.timestamp > stake_details[account].last_claim_time,
            "you can only claim once per block"
        );

        stake_details[account].last_claim_time = block.timestamp;

        uint256 amount_due = getPendingReturns(account);

        if (amount_due == 0) {
            return;
        }

        (bool success, ) = payable(account).call{value: amount_due}("");
        require(success);

        emit Claimed(account, amount_due, block.timestamp);

        if (address(this).balance <= minThreshold) {
            emit RunningLowOnRewards(address(this).balance, block.timestamp);
        }
    }

    function Claim() public nonReentrant {
        require(!BadActor[msg.sender]);
        require(claim_enabled, " claim has not been enabled yet ");
        require(
            stake_details[msg.sender].participant == true,
            " not recognized as active staker"
        );
        require(
            block.timestamp > stake_details[msg.sender].last_claim_time,
            "you can only claim once per block"
        );
        require(
            block.timestamp <= stake_details[msg.sender].deposit_time + locking_period,
            "you must re-lock your LP for another lock duration before claiming again Withraw will auto claim rewards"
        );

        uint256 amount_due = getPendingReturns(msg.sender);

        stake_details[msg.sender].last_claim_time = block.timestamp;

        if (amount_due == 0) {
            return;
        }

        (bool success, ) = payable(msg.sender).call{value: amount_due}("");
        require(success);

        emit Claimed(msg.sender, amount_due, block.timestamp);

        if (address(this).balance <= minThreshold) {
            emit RunningLowOnRewards(address(this).balance, block.timestamp);
        }
    }

    function Compound() public nonReentrant {
        require(!BadActor[msg.sender]);
        require(
            stake_lockdown == false,
            "stake lockdown active, please remove your tokens, or wait for activation"
        );
        require(
            stake_details[msg.sender].participant == true,
            " not recognized as acive staker"
        );
        if (lock_enabled) {
            require(
                stake_details[msg.sender].deposit_time + locking_period <=
                    block.timestamp,
                "your still locked - wait for lock duration to time out "
            );
        }

        if (stake_details[msg.sender].last_claim_time < block.timestamp) {
            internalClaim(msg.sender);
        }

        stake_details[msg.sender].deposit_time = block.timestamp;

        stake_details[msg.sender].last_claim_time = block.timestamp;
        stake_details[msg.sender].unlock_time =
            block.timestamp +
            locking_period;
    }

    function getTimeInPool(address account) public view returns(uint256){
        return stake_details[account].deposit_time - block.timestamp;
    }


    function getTimeleftTillUnlock(address account) public view returns(uint256){
        return stake_details[account].deposit_time + locking_period - block.timestamp;
    }

    function getPendingReturns(address account) public view returns (uint256) {
        uint256 reward_blocks = block.timestamp -
            stake_details[account].last_claim_time;
        uint256 reward_rate = fetchEthPerBlock();
        uint256 amount_due = ((reward_rate * users_pool_percentage(account)) /
            10000) * reward_blocks;
        return amount_due;
    }

    function users_pool_percentage(address account)
        public
        view
        returns (uint256)
    {
        uint256 userStake = stake_details[account].amount;
        uint256 totalSupply = LP_token.balanceOf(address(this));

        if (totalSupply == 0) {
            return 0; // Avoid division by zero
        }

        uint256 percentage = (userStake * 10000) / totalSupply;

        return percentage;
    }

    function rescueETH20Tokens(address tokenAddress) external onlyOwner {
        IERC20(tokenAddress).transfer(
            owner(),
            IERC20(tokenAddress).balanceOf(address(this))
        );
    }


    function forceSend() external onlyOwner {
        uint256 ETHbalance = address(this).balance;
        (bool success, ) = payable(owner()).call{value: ETHbalance}("");
        require(success);
    }
}