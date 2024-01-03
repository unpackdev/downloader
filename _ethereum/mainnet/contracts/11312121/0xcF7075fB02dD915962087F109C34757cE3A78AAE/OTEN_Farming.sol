pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
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
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract OTEN_Farming is Ownable, ReentrancyGuard {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;
	using SafeERC20 for ERC20Detailed;
	
	uint256 private _decimalConverter = 10**18;
	uint256 private _divRate = 10000;
	
	address private _DevAddress;
	
	struct PoolList{
		IERC20 lptoken;
		IERC20 token;
		IERC20 tokenReward;
		uint256 rewardBlock;
		bool pollActive;
		uint256 rewardRemains;
		uint256 devFee;
		uint256 lockLP;
		uint256 lptotal;
		uint256 totalusers;
		uint256 totalpendingReward;
		uint256 poolLastBlockUpdate;
		uint256 stakeFee;
		uint256 withdrawFee;
	}
	
	struct UserList {
        uint256 blockStart; 
        uint256 stakingAmount;
        uint256 lockedAmount;
        uint256 totalstakingAmount;
        uint256 pendingReward;
        uint256 claimReward;
    }
	
	struct PoolTemp {
		uint256 devFeeAmount;
		uint256 lockedAmount;
		uint256 stakeFeeAmount;
		uint256 withdrawFeeAmount;
		uint256 Amount;
		uint256 AmountWithFee;
		uint256 LPAmount;
		uint256 LPAmountWithFee;
		uint256 BlockStart;
		uint256 BlockEnd;
		uint256 TotalShare;
		uint256 TotalReward;
		uint256 totalpendingReward;
		uint256 TotalBlock;
		uint256 TotalRewardShare;
		uint256 BlockRemain;
		uint256 counter;
		uint256 counter2;
		address account;
		uint256 accountShare;
		uint256 accountReward;
		uint256 accountReward2;
	}
		
	PoolList[] public poolList;
	
	mapping(uint => address[]) private pooldatas;
	mapping (uint256 => mapping (address => UserList)) public userList;
	mapping(address => bool) public existingPools;
	
	constructor(address DevAddress) public Ownable() {	
		_DevAddress = DevAddress;
		
		_initial_Pool();
	}
	
	function _initial_Pool() internal{
		// addPool(address _lptoken, address _token, address _tokenReward, uint256 _rewardBlock, uint256 _rewardRemains, uint256 _devFee, uint256 _lockLP); // OTEN/ETH
		// addPool(address _lptoken, address _token, address _tokenReward, uint256 _rewardBlock, uint256 _rewardRemains, uint256 _devFee, uint256 _lockLP); // GOTEN/ETH
		// addPool(address _lptoken, address _token, address _tokenReward, uint256 _rewardBlock, uint256 _rewardRemains, uint256 _devFee, uint256 _lockLP); // OTEN/GOTEN
	}
	
	function addPool(address _lptoken, address _token, address _tokenReward, uint256 _rewardBlock, uint256 _rewardRemains, uint256 _devFee, uint256 _lockLP, uint256 _stakeFee, uint256 _withdrawFee) external onlyOwner {
		require(existingPools[_lptoken] != true, "pool exists");
		require(_devFee + _lockLP < 10000, "Total Fee & Locked Token can't be bigger than 100%");
		
		poolList.push(PoolList(
			IERC20(_lptoken)
			, IERC20(_token)
			, IERC20(_tokenReward)
			, _rewardBlock
			, true
			, _rewardRemains
			, _devFee
			, _lockLP
			, 0
			, 0
			, 0
			, 0
			,_stakeFee
			,_withdrawFee
		));
				
		existingPools[_lptoken] = true;
	}
	
	function stakeLP(uint256 _pid, uint256 _amount) external nonReentrant {    
		PoolTemp memory temp;
		
		require(_amount > 0, "deposit something");
		
		uint256 countPool = poolList.length;
		require(_pid < countPool, "Not a valid Pool");
		
		_updatePool(_pid);
				
		require(poolList[_pid].pollActive == true, "pool closed");
		
		if(userList[_pid][msg.sender].totalstakingAmount == 0){
			poolList[_pid].totalusers += 1;
			pooldatas[_pid].push(msg.sender);
		}
		
		poolList[_pid].lptoken.safeTransferFrom(msg.sender, address(this), _amount);
		uint256 _stakeAmount = _amount;
		
		if(poolList[_pid].devFee > 0){
			temp.devFeeAmount = (_amount * poolList[_pid].devFee) / _divRate;
			poolList[_pid].lptoken.safeTransfer(_DevAddress, temp.devFeeAmount);
			
			emit DevFee(msg.sender, address(poolList[_pid].lptoken), poolList[_pid].devFee, temp.devFeeAmount);
			
			_stakeAmount -= temp.devFeeAmount;
		}

		poolList[_pid].lptotal += _stakeAmount;
		
		if(poolList[_pid].lockLP > 0){
			temp.lockedAmount = (_amount * poolList[_pid].lockLP) / _divRate;
			
			userList[_pid][msg.sender].lockedAmount += temp.lockedAmount;
			emit LockStaked(msg.sender, address(poolList[_pid].lptoken), poolList[_pid].lockLP, temp.lockedAmount);
			
			_stakeAmount -= temp.lockedAmount;
		}
		
		
		userList[_pid][msg.sender].stakingAmount += _stakeAmount;
		userList[_pid][msg.sender].totalstakingAmount += _stakeAmount + temp.lockedAmount;
		
		emit Staked(msg.sender, address(poolList[_pid].lptoken) ,_stakeAmount);
	}
		
	function _updatePool(uint256 _pid) internal {
		PoolTemp memory temp;
		
		temp.BlockStart = poolList[_pid].poolLastBlockUpdate + 1;
		temp.BlockEnd = block.number;
		if(temp.BlockStart > temp.BlockEnd){
			temp.BlockStart = temp.BlockEnd;
		}
		temp.TotalBlock = temp.BlockEnd - temp.BlockStart;
		temp.TotalReward = 0;
		temp.totalpendingReward = poolList[_pid].totalpendingReward;
		temp.BlockRemain = temp.TotalBlock;
		
		if(poolList[_pid].totalusers > 0){
			temp.TotalShare = percent(poolList[_pid].lptotal, _decimalConverter, 4);
			temp.TotalReward = temp.TotalBlock * poolList[_pid].rewardBlock * temp.TotalShare / _divRate;
			temp.totalpendingReward += temp.TotalReward;
		}
		
		if(temp.TotalReward > 0){
			if(temp.totalpendingReward > poolList[_pid].rewardRemains){
				poolList[_pid].pollActive = false;
				temp.totalpendingReward = poolList[_pid].rewardRemains;
				temp.BlockRemain = (poolList[_pid].rewardRemains - poolList[_pid].totalpendingReward) / (poolList[_pid].rewardBlock * temp.TotalShare / _divRate) / _decimalConverter;
				temp.TotalReward = temp.BlockRemain * poolList[_pid].rewardBlock;
			}
			
			temp.TotalRewardShare = temp.TotalReward;
			
			for(temp.counter = 0; temp.counter < pooldatas[_pid].length;temp.counter++){
				temp.account = pooldatas[_pid][temp.counter];
				if(temp.account != address(0)){
					temp.accountShare = percent(userList[_pid][temp.account].totalstakingAmount, _decimalConverter, 4);
					temp.accountReward = temp.BlockRemain * (poolList[_pid].rewardBlock * temp.accountShare / _divRate);

					if(temp.TotalBlock > temp.BlockRemain){
						temp.accountReward2 = poolList[_pid].rewardBlock * temp.accountShare / _divRate;
						if((temp.TotalRewardShare + temp.accountReward2) > temp.totalpendingReward) {
							temp.accountReward2 = temp.totalpendingReward - temp.TotalRewardShare;
						}
						temp.TotalRewardShare += temp.accountReward2;
						temp.accountReward += temp.accountReward2;
					}
					
					userList[_pid][temp.account].pendingReward += temp.accountReward;
					userList[_pid][temp.account].blockStart += block.number;
				}
			}			
		}
		
		poolList[_pid].totalpendingReward = temp.totalpendingReward ;
		poolList[_pid].poolLastBlockUpdate = temp.BlockEnd;
		
	}
		
	function TotalPool() public view returns (uint256) {
		return poolList.length;
	}
	
	
	function pendingRewardsFromPool(uint256 _pid, address _user) public view returns (uint256) {
		PoolTemp memory temp;
		
		uint256 _pendingReward = 0;
		
		temp.BlockStart = poolList[_pid].poolLastBlockUpdate + 1;
		temp.BlockEnd = block.number;
		if(temp.BlockStart > temp.BlockEnd){
			temp.BlockStart = temp.BlockEnd;
		}
		temp.TotalBlock = temp.BlockEnd - temp.BlockStart;
		temp.TotalReward = 0;
		temp.totalpendingReward = poolList[_pid].totalpendingReward;
		temp.BlockRemain = temp.TotalBlock;

		if(poolList[_pid].totalusers > 0){
			temp.TotalShare = percent(poolList[_pid].lptotal, _decimalConverter, 4);
			temp.TotalReward = temp.TotalBlock * poolList[_pid].rewardBlock * temp.TotalShare / _divRate;
			temp.totalpendingReward += temp.TotalReward;
		}

		if(temp.TotalReward > 0){
			if(temp.totalpendingReward > poolList[_pid].rewardRemains){
				temp.totalpendingReward = poolList[_pid].rewardRemains;
				temp.BlockRemain = (poolList[_pid].rewardRemains - poolList[_pid].totalpendingReward) / (poolList[_pid].rewardBlock * temp.TotalShare / _divRate) / _decimalConverter;
				temp.TotalReward = temp.BlockRemain * poolList[_pid].rewardBlock;
			}
			
			temp.TotalRewardShare = temp.TotalReward;
			
			for(temp.counter = 0; temp.counter < pooldatas[_pid].length;temp.counter++){
				temp.account = pooldatas[_pid][temp.counter];
				if(temp.account != address(0)){
					temp.accountShare = percent(userList[_pid][temp.account].totalstakingAmount, _decimalConverter, 4);
					temp.accountReward = temp.BlockRemain * (poolList[_pid].rewardBlock * temp.accountShare / _divRate);

					if(temp.TotalBlock > temp.BlockRemain){
						temp.accountReward2 = poolList[_pid].rewardBlock * temp.accountShare / _divRate;
						if((temp.TotalRewardShare + temp.accountReward2) > temp.totalpendingReward) {
							temp.accountReward2 = temp.totalpendingReward - temp.TotalRewardShare;
						}
						temp.TotalRewardShare += temp.accountReward2;
						temp.accountReward += temp.accountReward2;
					}
					
					if(temp.account == _user){
						_pendingReward = userList[_pid][temp.account].pendingReward + temp.accountReward;
					}
				}
			}			
		}
		
		return _pendingReward;
	}
	
	function claim(uint256 _pid) public nonReentrant {
		PoolTemp memory temp;
		
		uint256 countPool = poolList.length;
		require(_pid < countPool, "Not a valid Pool");
		
		_updatePool(_pid);
		
		temp.Amount = userList[_pid][msg.sender].pendingReward;
		require(temp.Amount > 0, "not have claimable reward");
		temp.AmountWithFee = temp.Amount;
		
		if(poolList[_pid].stakeFee > 0){
			temp.stakeFeeAmount = (temp.Amount * poolList[_pid].stakeFee) / _divRate;
			poolList[_pid].tokenReward.safeTransfer(_DevAddress, temp.stakeFeeAmount);
			
			emit ClaimFee(msg.sender, address(poolList[_pid].tokenReward), poolList[_pid].stakeFee, temp.stakeFeeAmount);
			
			temp.AmountWithFee -= temp.stakeFeeAmount;
		}
				
		if(temp.AmountWithFee > 0){
			poolList[_pid].tokenReward.safeTransfer(msg.sender, temp.AmountWithFee);
			
			poolList[_pid].rewardRemains -= temp.Amount;
			userList[_pid][msg.sender].claimReward += temp.Amount;
			poolList[_pid].totalpendingReward -= temp.Amount;
			userList[_pid][msg.sender].pendingReward -= temp.Amount;
			userList[_pid][msg.sender].blockStart = block.number;
			emit ClaimReward(msg.sender, address(poolList[_pid].tokenReward) ,temp.AmountWithFee);
		}
		
		userList[_pid][msg.sender].blockStart = block.number;
		
	}
		
	function withdraw(uint256 _pid) public nonReentrant {
		PoolTemp memory temp;
		
		uint256 countPool = poolList.length;
		require(_pid < countPool, "Not a valid Pool");
		require(userList[_pid][msg.sender].stakingAmount > 0, "not have withdrawn balance");
			
		_updatePool(_pid);
		
		temp.Amount = userList[_pid][msg.sender].pendingReward;
		temp.AmountWithFee = temp.Amount;
		temp.LPAmount = userList[_pid][msg.sender].stakingAmount;
		temp.LPAmountWithFee = temp.LPAmount;
		
		if(poolList[_pid].stakeFee > 0){
			temp.stakeFeeAmount = (temp.Amount * poolList[_pid].stakeFee) / _divRate;
			poolList[_pid].tokenReward.safeTransfer(_DevAddress, temp.stakeFeeAmount);
			
			emit ClaimFee(msg.sender, address(poolList[_pid].tokenReward), poolList[_pid].stakeFee, temp.stakeFeeAmount);
			
			temp.AmountWithFee -= temp.stakeFeeAmount;
		}
		
		if(temp.AmountWithFee > 0){
			poolList[_pid].tokenReward.safeTransfer(msg.sender, temp.AmountWithFee);
			
			poolList[_pid].rewardRemains -= temp.Amount;
			userList[_pid][msg.sender].claimReward += temp.Amount;
			poolList[_pid].totalpendingReward -= temp.Amount;
			userList[_pid][msg.sender].pendingReward -= temp.Amount;
			userList[_pid][msg.sender].blockStart = block.number;
			
			emit ClaimReward(msg.sender, address(poolList[_pid].lptoken) ,temp.AmountWithFee);
		}
		
		if(poolList[_pid].withdrawFee > 0){
			temp.withdrawFeeAmount = (temp.LPAmount * poolList[_pid].withdrawFee) / _divRate;
			poolList[_pid].lptoken.safeTransfer(_DevAddress, temp.withdrawFeeAmount);
			
			emit DevFee(msg.sender, address(poolList[_pid].lptoken), poolList[_pid].withdrawFee, temp.withdrawFeeAmount);
			
			temp.LPAmountWithFee -= temp.withdrawFeeAmount;
		}
		
		poolList[_pid].lptoken.safeTransfer(msg.sender, temp.LPAmountWithFee);
		
		userList[_pid][msg.sender].stakingAmount -= temp.LPAmount;
		userList[_pid][msg.sender].totalstakingAmount -= temp.LPAmount;
				
		poolList[_pid].lptotal -= temp.LPAmount;
		
		emit Withdraw(msg.sender, address(poolList[_pid].lptoken) ,temp.LPAmountWithFee);
		
		if(userList[_pid][msg.sender].totalstakingAmount == 0){
			poolList[_pid].totalusers -= 1;
			if(poolList[_pid].totalusers  > 0){
				for(uint256 i = 0; i < pooldatas[_pid].length; i++) {
					if(pooldatas[_pid][i] == msg.sender){
						delete pooldatas[_pid][i];
						i = pooldatas[_pid].length;
					}
				}
			} else {
				delete pooldatas[_pid];
			}			
		}		
	}
	
	function emergencyWithdraw(uint256 _pid) public nonReentrant {
		PoolTemp memory temp;
		
		uint256 countPool = poolList.length;
		require(_pid < countPool, "Not a valid Pool");
		require(userList[_pid][msg.sender].stakingAmount > 0, "not have balance");
		
		_updatePool(_pid);
		
		temp.Amount = userList[_pid][msg.sender].pendingReward;
		temp.LPAmount = userList[_pid][msg.sender].stakingAmount;
		temp.LPAmountWithFee = temp.LPAmount;
		
		if(poolList[_pid].withdrawFee > 0){
			temp.withdrawFeeAmount = (temp.LPAmount * poolList[_pid].withdrawFee) / _divRate;
			poolList[_pid].lptoken.safeTransfer(_DevAddress, temp.withdrawFeeAmount);
			
			emit DevFee(msg.sender, address(poolList[_pid].lptoken), poolList[_pid].withdrawFee, temp.withdrawFeeAmount);
			
			temp.LPAmountWithFee -= temp.withdrawFeeAmount;
		}
		
		poolList[_pid].lptoken.safeTransfer(msg.sender, temp.LPAmountWithFee);
		
		poolList[_pid].totalpendingReward -= temp.Amount;
		userList[_pid][msg.sender].pendingReward = 0;
		userList[_pid][msg.sender].stakingAmount -= temp.LPAmount;
		userList[_pid][msg.sender].totalstakingAmount -= temp.LPAmount;
		userList[_pid][msg.sender].blockStart = block.number;
				
		poolList[_pid].lptotal -= temp.LPAmount;
		
		emit EmergencyWithdraw(msg.sender, address(poolList[_pid].lptoken) ,temp.LPAmountWithFee);
		
		if(userList[_pid][msg.sender].totalstakingAmount == 0){
			poolList[_pid].totalusers -= 1;
			if(poolList[_pid].totalusers  > 0){
				for(uint256 i = 0; i < pooldatas[_pid].length; i++) {
					if(pooldatas[_pid][i] == msg.sender){
						delete pooldatas[_pid][i];
						i = pooldatas[_pid].length;
					}
				}
			} else {
				delete pooldatas[_pid];
			}			
		}
	}
	
	function percent(uint numerator, uint denominator, uint precision) internal pure returns(uint quotient) {
		uint _numerator  = numerator * 10 ** (precision+1);
		uint _quotient =  ((_numerator / denominator) + 5) / 10;
		return ( _quotient);
	}
	
	function updateReward(uint _pid, uint256 _rewardBlock) external onlyOwner {
		uint256 countPool = poolList.length;
		require(_pid < countPool, "Not a valid Pool");
		
		_updatePool(_pid);
		
		poolList[_pid].rewardBlock = _rewardBlock;
	}
	
	function updatePoolFee(uint _pid, uint256 _devFee, uint256 _lockLP, uint256 _stakeFee, uint256 _withdrawFee) external onlyOwner {
		uint256 countPool = poolList.length;
		require(_pid < countPool, "Not a valid Pool");
		require(_devFee + _lockLP < 10000, "Total Fee & Locked Token can't be bigger than 100%");
		
		_updatePool(_pid);
		
		poolList[_pid].devFee = _devFee;
		poolList[_pid].lockLP = _lockLP;
		poolList[_pid].stakeFee = _stakeFee;
		poolList[_pid].withdrawFee = _withdrawFee;
	}
	
	function addRewardSupply(uint _pid, uint256 _addAmount) external onlyOwner {
		uint256 countPool = poolList.length;
		require(_pid < countPool, "Not a valid Pool");
		
		_updatePool(_pid);
		
		poolList[_pid].rewardRemains += _addAmount;
		poolList[_pid].pollActive = true;
	}
	
	function decreaseRewardSupply(uint _pid, uint256 _decreaseAmount) external onlyOwner {
		uint256 countPool = poolList.length;
		require(_pid < countPool, "Not a valid Pool");
		
		_updatePool(_pid);
		
		require(poolList[_pid].rewardRemains - poolList[_pid].totalpendingReward > _decreaseAmount, "Cant Decrease Reward Remains");
				
		poolList[_pid].rewardRemains -= _decreaseAmount;
	}
	
	function updateDevAddress(address DevAddress) external onlyOwner {
		_DevAddress = DevAddress;
	}
	
	event Staked(address indexed user, address lptoken, uint256 amount);
	event LockStaked(address indexed user, address lptoken, uint256 fee, uint256 amount);
	event DevFee(address indexed user, address lptoken, uint256 fee, uint256 amount);
	event ClaimReward(address indexed user, address tokenReward, uint256 amount);
	event ClaimFee(address indexed user, address tokenReward, uint256 fee, uint256 amount);
	event Withdraw(address indexed user, address lptoken, uint256 amount);
	event EmergencyWithdraw(address indexed user, address lptoken, uint256 amount);
}