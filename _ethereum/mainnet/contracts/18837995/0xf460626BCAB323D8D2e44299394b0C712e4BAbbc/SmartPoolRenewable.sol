// SPDX-License-Identifier: MIT
// File: smartPoolV2.sol

// complier 7.5

// Farmageddon Renewable Pool Contract.

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol

pragma solidity ^0.8.0;

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
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: bsc-library/contracts/IBEP20.sol

pragma solidity ^0.8.0;

interface IBEP20 {
    
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

interface NFT {
    function balanceOf(address account) external view returns (uint256);
    function name() external view returns (string calldata name);
}

// File: contracts/SmartChefInitializable.sol

pragma solidity ^0.8.0;

contract SmartPoolRenewable is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    
    // The address of the smart chef factory
    address public SMART_CHEF_FACTORY;
    
    // Whether a limit is set for users
    bool public hasUserLimit;

    // Whether it is initialized
    bool public isInitialized;

    // Accrued token per share
    uint256 public accTokenPerShare;

    // The block number when CAKE mining ends.
    uint256 public bonusEndBlock;

    // The block number when CAKE mining starts.
    uint256 public startBlock;

    // The block number of the last pool update
    uint256 public lastRewardBlock;

    // CAKE tokens created per block.
    uint256 public rewardPerBlock;

    // The precision factor
    uint256 public PRECISION_FACTOR;

    // The reward token
    IBEP20 public rewardToken;

    // The staked token
    IBEP20 public stakedToken;

    // the Needed NFTs
    NFT[] public NFTsNeeded;
    mapping(address => bool) public isNFTCollection;
    uint256[] public stakeAmounts;

    // Total Staked tokens
    uint256 public totalStaked;

    // Previous and Current pool reward balance
    uint256 public prevAndCurrentRewardsBalance;

    // Info of each user that stakes tokens (stakedToken)
    mapping(address => UserInfo) public userInfo;

    struct UserInfo {
        uint256 amount; // How many staked tokens the user has provided
        uint256 rewardDebt; // Reward debt
    }

    event AdminTokenRecovery(address tokenRecovered, uint256 amount);
    event Deposit(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event NewStartAndEndBlocks(uint256 startBlock, uint256 endBlock);
    event NewRewardPerBlock(uint256 rewardPerBlock);
    event RewardsStop(uint256 blockNumber);
    event Withdraw(address indexed user, uint256 amount);

    constructor(NFT[] memory _NFTs, uint256[] memory stakableAmounts) {
        SMART_CHEF_FACTORY = msg.sender;
        require(_NFTs.length == stakableAmounts.length,"NFTS, and amounts must be same quantity");
        NFTsNeeded = _NFTs;
        stakeAmounts = stakableAmounts;
        for(uint i=0; i<_NFTs.length; i++) {
            isNFTCollection[address(_NFTs[i])] = true;
        }
    }

  
    /**
    * @notice this function is to extend or renew the pool ==============================================================
    */

    function increaseAPR() external onlyOwner {
        _updatePool();
        uint256 totalNewReward = checkTotalNewRewards();
        require(bonusEndBlock > block.timestamp, "Pool has Ended, use startNewPool");
        require(totalNewReward > 0, "no NewRewards availavble, send tokens First");

        uint256 blocksLeft = bonusEndBlock - block.timestamp;
        uint256 addedRPB = totalNewReward / blocksLeft;
        rewardPerBlock += addedRPB;

        if (stakedToken == rewardToken) {           
            prevAndCurrentRewardsBalance = rewardToken.balanceOf(address(this)) - totalStaked;
        } else {
            // check how much new rewards are available
            prevAndCurrentRewardsBalance = rewardToken.balanceOf(address(this));
        }

        _updatePool();

    }

    function ExtendPool() external onlyOwner {
        require(bonusEndBlock > block.timestamp, "Pool has Ended, use startNewPool");
          
        _updatePool();
        uint256 totalNewReward = checkTotalNewRewards();
        require(totalNewReward > 0, "No funds to start new pool with");
        
        if (stakedToken == rewardToken) {           
            prevAndCurrentRewardsBalance = rewardToken.balanceOf(address(this)) - totalStaked;
        } else {
            // check how much new rewards are available
            prevAndCurrentRewardsBalance = rewardToken.balanceOf(address(this));
        }        
        
        // increase block count for pool
        uint256 timeExtended = totalNewReward / rewardPerBlock;
        bonusEndBlock = bonusEndBlock + (timeExtended);
        
    }

    function startNewPool( uint256 _startInDays, uint256 _poolLengthDays ) external onlyOwner {
        // make sure pool has ended
        require(bonusEndBlock < block.timestamp, "Pool has not ended, Try Extending");
        
         _updatePool();
        uint256 totalNewReward = checkTotalNewRewards();
        require(totalNewReward > 0, "No funds to start new pool with");
        
        // setup for calculations
        uint256 startInBlocks;
        uint256 totalBlocks;
        startInBlocks = _startInDays * 86400;
        totalBlocks = _poolLengthDays * 86400;

        if (stakedToken == rewardToken) {            
            prevAndCurrentRewardsBalance = rewardToken.balanceOf(address(this)) - totalStaked;
        } else {
            // check how much new rewards are available            
            prevAndCurrentRewardsBalance = rewardToken.balanceOf(address(this));
        }
        
        // set last reward block to new start block
        startBlock = (block.timestamp + startInBlocks);
        lastRewardBlock = startBlock;
        
        // set end block of new pool
        bonusEndBlock = startBlock + totalBlocks;
        
        // set new rewards per block based off the new information
        rewardPerBlock = totalNewReward / totalBlocks;
              
        // Make this contract initialized
        isInitialized = true;
    }

    function setupTokens(
        IBEP20 _stakedToken,
        IBEP20 _rewardToken
    ) external onlyOwner {
        require(!isInitialized, "Already initialized");

        stakedToken = _stakedToken;
        rewardToken = _rewardToken;

        hasUserLimit = true;
  
        uint256 decimalsRewardToken = uint256(rewardToken.decimals());
        require(decimalsRewardToken < 30, "Must be inferior to 30");

        PRECISION_FACTOR = uint256(10**(uint256(30).sub(decimalsRewardToken)));

        // set rewardscounter
        prevAndCurrentRewardsBalance = 0;
        totalStaked = 0;
    }

    function poolLimitPerUser(address user) public view returns (uint256 limit) {
        // check for NFTS then calculate max
        limit = 0;
        for(uint i=0; i<NFTsNeeded.length; i++) {
            uint256 bal = NFTsNeeded[i].balanceOf(user);
            limit += bal * stakeAmounts[i];
        }
    }

    /*
     * @notice Deposit staked tokens and collect reward tokens (if any)
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function deposit(uint256 _amount) external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        uint256 preBalance;
        uint256 postBalance;

        require(_amount.add(user.amount) <= poolLimitPerUser(msg.sender), "User amount above limit");
        
        _updatePool();

        if (user.amount > 0) {
            uint256 pending = user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);
            if (pending > 0) {
                rewardToken.transfer(address(msg.sender), pending);
                prevAndCurrentRewardsBalance -= pending; 
            }
        }

        if (_amount > 0) {
            preBalance = stakedToken.balanceOf(address(this));
            stakedToken.transferFrom(address(msg.sender), address(this), _amount);
            postBalance = stakedToken.balanceOf(address(this));
            
            user.amount = user.amount.add(postBalance - preBalance);
            
            totalStaked += (postBalance - preBalance);
        }

        user.rewardDebt = user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR);
        
        emit Deposit(msg.sender, _amount);
    }

    /*
     * @notice Withdraw staked tokens and collect reward tokens
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function withdraw(uint256 _amount) external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "Amount to withdraw too high");

        _updatePool();

        uint256 pending = user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);

        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            stakedToken.transfer(address(msg.sender), _amount);
            totalStaked -= _amount;
        }

        if (pending > 0) {
            rewardToken.transfer(address(msg.sender), pending);
            prevAndCurrentRewardsBalance -= pending; 
        }

        user.rewardDebt = user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR);
        
        emit Withdraw(msg.sender, _amount);
    }

    /*
     * @notice Withdraw staked tokens without caring about rewards rewards
     * @dev Needs to be for emergency.
     */
    function emergencyWithdraw() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        uint256 amountToTransfer = user.amount;
        totalStaked -= user.amount;
        user.amount = 0;
        user.rewardDebt = 0;

        if (amountToTransfer > 0) {
            stakedToken.transfer(address(msg.sender), amountToTransfer);
        }
        
        emit EmergencyWithdraw(msg.sender, user.amount);
    }

    /*
     * @notice Stop rewards
     * @dev Only callable by owner. Needs to be for emergency.
     */
    function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
        rewardToken.transfer(address(msg.sender), _amount);
        prevAndCurrentRewardsBalance -= _amount; 
    }
    
    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of tokens to withdraw
     * @dev This function is only callable by admin.
     * @dev All tokens left in the contract for 3 months become OWNERLESS and can be claimed.
     */ 
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        if (block.timestamp < bonusEndBlock + 7776000) {
            require(_tokenAddress != address(stakedToken), "Cannot be staked token(for 3 months)");
            require(_tokenAddress != address(rewardToken), "Cannot be reward token(for 3 months)");

            IBEP20(_tokenAddress).transfer(address(msg.sender), _tokenAmount);
 
        } else {
            IBEP20(_tokenAddress).transfer(address(msg.sender), _tokenAmount);
        }

        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    /*
     * @notice Stop rewards
     * @dev Only callable by owner
     */
    function stopReward() external onlyOwner {
        _updatePool();
        uint256 totalNewReward = checkTotalNewRewards();
        uint256 timeLeft = bonusEndBlock - block.timestamp;
        uint256 rewardsLeft = rewardPerBlock * timeLeft;

        if (stakedToken == rewardToken) {           
            prevAndCurrentRewardsBalance = rewardToken.balanceOf(address(this)) - totalStaked;
        } else {
            // check how much new rewards are available
            prevAndCurrentRewardsBalance = rewardToken.balanceOf(address(this));
        }
        prevAndCurrentRewardsBalance -= rewardsLeft;
        prevAndCurrentRewardsBalance -= totalNewReward;
        bonusEndBlock = block.timestamp;
    }

    /*
     * @notice Update reward per block
     * @dev Only callable by owner.
     * @param _rewardPerBlock: the reward per block
     */
    function updateRewardPerBlock(uint256 _rewardPerBlock) external onlyOwner {
        require(block.timestamp < startBlock, "Pool has started");
        rewardPerBlock = _rewardPerBlock;
        emit NewRewardPerBlock(_rewardPerBlock);
    }

    /**
     * @notice It allows the admin to update start and end blocks
     * @dev This function is only callable by owner.
     * @param _startBlock: the new start block
     * @param _bonusEndBlock: the new end block
     */
    function updateStartAndEndBlocks(uint256 _startBlock, uint256 _bonusEndBlock) external onlyOwner {
        require(block.timestamp < startBlock, "Pool has started");
        require(_startBlock < _bonusEndBlock, "New startBlock must be lower than new endBlock");
        require(block.timestamp < _startBlock, "New startBlock must be higher than current block");

        startBlock = _startBlock;
        bonusEndBlock = _bonusEndBlock;

        // Set the lastRewardBlock as the startBlock
        lastRewardBlock = startBlock;

        emit NewStartAndEndBlocks(_startBlock, _bonusEndBlock);
    }

    /*
     * @notice View function to see pending reward on frontend.
     * @param _user: user address
     * @return Pending reward for a given user
     */
    function pendingReward(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 stakedTokenSupply = totalStaked;
        if (block.timestamp > lastRewardBlock && stakedTokenSupply != 0) {
            uint256 multiplier = _getMultiplier(lastRewardBlock, block.timestamp);
            uint256 cakeReward = multiplier.mul(rewardPerBlock);
            uint256 adjustedTokenPerShare =
                accTokenPerShare.add(cakeReward.mul(PRECISION_FACTOR).div(stakedTokenSupply));
            return user.amount.mul(adjustedTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);
        } else {
            return user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);
        }
    }

    function checkExtraStakedTokens() public view returns(uint256 extraTokens){
        if (stakedToken == rewardToken) {
            extraTokens = (stakedToken.balanceOf(address(this)) - prevAndCurrentRewardsBalance - totalStaked);
        } else {
            extraTokens = (stakedToken.balanceOf(address(this)) - totalStaked);
        }
    }

    function checkTotalNewRewards() public view returns(uint256 totalNewReward){
        if (stakedToken == rewardToken) {
            totalNewReward = (rewardToken.balanceOf(address(this)) - prevAndCurrentRewardsBalance - totalStaked);            
        } else {
            totalNewReward = (rewardToken.balanceOf(address(this)) - prevAndCurrentRewardsBalance);
        }
    }

    /*
     * @notice Update reward variables of the given pool to be up-to-date.
     */
    function _updatePool() internal {
        if (block.timestamp <= lastRewardBlock) {
            return;
        }

        uint256 stakedTokenSupply = totalStaked;
    
        if (stakedTokenSupply == 0) {
            lastRewardBlock = block.timestamp;
            return;
        }

        uint256 multiplier = _getMultiplier(lastRewardBlock, block.timestamp);
        uint256 cakeReward = multiplier.mul(rewardPerBlock);
        accTokenPerShare = accTokenPerShare.add(cakeReward.mul(PRECISION_FACTOR).div(stakedTokenSupply));
        lastRewardBlock = block.timestamp;
    }

    /*
     * @notice Return reward multiplier over the given _from to _to block.
     * @param _from: block to start
     * @param _to: block to finish
     */
    function _getMultiplier(uint256 _from, uint256 _to) internal view returns (uint256) {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from);
        } else if (_from >= bonusEndBlock) {
            return 0;
        } else {
            return bonusEndBlock.sub(_from);
        }
    }

    function addNFTCollection(NFT _newCollection, uint256 amount) external onlyOwner {
        require(!isNFTCollection[address(_newCollection)], "Already Added");
        NFTsNeeded.push(_newCollection);
        stakeAmounts.push(amount);
        isNFTCollection[address(_newCollection)] = true;
    }

   function removeNFTCollection(NFT _oldCollection) external onlyOwner {
    address collectionAddress = address(_oldCollection);

    require(isNFTCollection[collectionAddress], "not Added yet");

    for (uint i = 0; i < NFTsNeeded.length; i++) {
        if (address(NFTsNeeded[i]) == collectionAddress) {
            NFTsNeeded[i] = NFTsNeeded[NFTsNeeded.length - 1];
            stakeAmounts[i] = stakeAmounts[stakeAmounts.length -1];
            NFTsNeeded.pop();
            stakeAmounts.pop();
            isNFTCollection[collectionAddress] = false;
            break; // Exit the loop after finding and removing the NFT collection
        }
    }
}


    function changeStakingLimitForNFT(NFT _collection, uint256 _newAmount) external onlyOwner {
        for(uint i=0; i<NFTsNeeded.length; i++) {
            if(NFTsNeeded[i] == _collection) {
                stakeAmounts[i] = _newAmount;
            }
        }
    }
    function NFTCollectionInfo() external view returns (string[] memory names, uint256[] memory amounts) {
       uint256 cLength = NFTsNeeded.length;
       names = new string[](cLength);
       amounts = new uint256[](cLength);

       for(uint i=0; i<cLength; i++) {
        names[i] = NFTsNeeded[i].name();
        amounts[i] = stakeAmounts[i];
       }
    }

  // Token removal Functions
  
    function withdawlBNB() external onlyOwner {
            payable(msg.sender).transfer(address(this).balance);
    }
    
    function RemoveExtraStakingTokens() external onlyOwner {
        _updatePool();
        uint256 extraTokens = checkExtraStakedTokens();
        require(extraTokens > 0, "No extra Tokens to Withdrawl");
        IBEP20(stakedToken).transfer(address(msg.sender), extraTokens);
    }
    
    function NEWRewardWithdraw() external onlyOwner {
        uint256 totalNewReward = checkTotalNewRewards();
        require(totalNewReward > 0, "No New Reward Tokens to Withdrawl");
        rewardToken.transfer(address(msg.sender), totalNewReward);
    }

    receive() external payable {}
}