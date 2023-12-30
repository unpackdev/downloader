pragma solidity ^0.6.0;

// SPDX-License-Identifier：UNLICENSED

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
contract Ownable is Context {
    address private _owner;
	address private _authorized;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * just use for authoriz to a newOwner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        // emit OwnershipTransferred(_owner, newOwner);
        _authorized = newOwner;
    }
    
    /**
     * @dev get ownership of the contract to the authorized user
     * Can only be called by the authorized user.
     */
    function getOwnership() public virtual {
        require(msg.sender == _authorized, "Ownable: not authorized");
        emit OwnershipTransferred(_owner, msg.sender);
        _owner = msg.sender;
        _authorized = address(0);
    }
}



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
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


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
 * @dev Interface of the ERC20 standard as defined in the EIP.
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


contract ERC20 is IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 public _totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals;
  
    constructor () public {
        decimals = 18;
    }
    
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
	
	function burn(uint256 amount) public {
		_burn(msg.sender, amount);
	}

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(amount <= _totalSupply, "ERC20: transfer can not bigger than totalSupply");
		_balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = 0;
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        emit Transfer(account, address(0), amount);
    }

}

contract WinesToken is ERC20 {
    
    constructor () public {
        _totalSupply = 100000000 * 10 ** 18;
        name = "Wines token";
        symbol = "WINES";
        _balances[msg.sender] = _totalSupply;
    }
    
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}



// Have fun reading it. Hopefully it's bug-free. God bless.
contract WinesMaster is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;   //LP TOKEN balance
        uint256 rewardDebt;
    }

    struct PoolInfo {
        IERC20 lpToken;
        uint256 weightPoint;
        uint256 share;
        uint256 lastRewardBlock;
    }

    struct PioneerInfo {
        uint256 poolId;
        uint256 endBlock;
        uint256 totalReward;
        uint256 blockReward;
        uint256 startBlock;
        uint256 rewardBalance;
        uint256 startRewardDebt;
        uint256 endRewardDebt;
    }

    // The GIFT TOKEN!
    WinesToken public giftToken;
    // the Owner address
    address public fundPool;
    // block interval for miner difficult update 
    uint256 public difficultyChangeBlock;
    // the reward of each block.
    uint256 public minerBlockReward;
    
    uint256 public currentDifficulty;
    // the reward for developer rato 
    uint256 public constant DEVELOPER_RATO = 10;
    uint256 public constant INTERVAL = 1e12;
    // the migrator token
    IMigratorToken public migrator;

    // Deposit pool array
    PoolInfo[] public poolInfoList;
    
    // userinfo map
    mapping (uint256 => mapping (address => UserInfo)) public userInfoMap;
    // pioneerInfo map
    mapping (uint256 => PioneerInfo) public pioneerInfoMap;
    // total alloc point
    uint256 public totalWeightPoint = 0;
    // miner start block
    uint256 public startBlock;
    // miner block num for test
    // uint256 public testBlockNum;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(WinesToken _gift, uint256 _startBlock, uint256 _minerBlockReward, address _fundPoolAddress) public {
        giftToken = _gift;
        fundPool = _fundPoolAddress;
        startBlock = _startBlock;
        minerBlockReward = _minerBlockReward;
    }
    
    // constructor(WinesToken _gift) public {
    //     giftToken = _gift;
    //     fundPool = address(msg.sender);
    //     startBlock = block.number;
    //     testBlockNum = block.number;
    //     minerBlockReward = 70;
    // }
    
    // ** The function below is for user operation
    // deposit lp token
    function deposit(uint256 _pid, uint256 _amount) external {
        PoolInfo storage pool = poolInfoList[_pid];
        UserInfo storage user = userInfoMap[_pid][msg.sender];
        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        updatePool(_pid);
        uint256 pending = pendingReward(_pid, msg.sender);
        if(pending >= 0) {
            userRewardSender(pending, _pid, msg.sender);
        }
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.share).div(INTERVAL);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // update share of all pools
    function updateAllPools() public {
        uint256 length = poolInfoList.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // withdraw lpToken form Deposit pool
    function withdraw(uint256 _pid, uint256 _amount) external {
        PoolInfo storage pool = poolInfoList[_pid];
        UserInfo storage user = userInfoMap[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: amount not enough");
        updatePool(_pid);
        uint256 pending = pendingReward(_pid, msg.sender);
        if(pending > 0) {
            userRewardSender(pending, _pid, msg.sender);
        }
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.share).div(1e12);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }
    
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfoList[_pid];
        UserInfo storage user = userInfoMap[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // withdraw reward form Deposit pool
    function withdrawReward(uint256 _pid) external {
        uint256 pending = pendingReward(_pid, msg.sender);
        require(pending >= 0, "withdrawReward: reward pool empty");
        userRewardSender(pending, _pid, msg.sender);
    }
    
    // ** The function below is for display parameters
    // the length of deposit pool
    function poolLength() external view returns (uint256) {
        return poolInfoList.length;
    }

    // show the pending reward
    function pendingReward(uint256 _pid, address _user) public view returns (uint256) {
        if(block.number < startBlock) return 0;
        PoolInfo storage pool = poolInfoList[_pid];
        UserInfo storage user = userInfoMap[_pid][_user];
        uint256 blockInterval = block.number.sub(pool.lastRewardBlock);
        // if (user.depositBlock == 0 || user.depositBlock > block.number) {
        // uint256 blockInterval = testBlockNum.sub(pool.lastRewardBlock);
        if(pool.lpToken.balanceOf(address(this)) == 0) {
            return 0;
        }
        if (pool.lastRewardBlock == 0 || pool.lastRewardBlock > block.number) {
        // if (pool.lastRewardBlock == 0 || pool.lastRewardBlock > testBlockNum) {
            return 0;
        }
        uint256 share = pool.share.add(blockInterval.mul(minerBlockReward).mul(INTERVAL).mul(pool.weightPoint).div(totalWeightPoint).div(pool.lpToken.balanceOf(address(this))));
        uint256 pendingAmount = user.amount.mul(pool.share.add(share)).div(INTERVAL).sub(user.rewardDebt);
        pendingAmount = giftToken.balanceOf(address(this)) > pendingAmount ? pendingAmount : giftToken.balanceOf(address(this));
        pendingAmount = pendingAmount.add(getPioneerReward(_pid, _user));
        return pendingAmount;
    }

    // ** The function below is for private function
    // send user reward
    function userRewardSender(uint256 rewardAmount, uint256 _pid, address _user) private {
        uint256 lpSupply = giftToken.balanceOf(address(this));
        if (lpSupply == 0) {
            return;
        }
        if(rewardAmount > 0) {
            giftToken.transfer(fundPool, rewardAmount.mul(9).div(10).div(10));
            giftToken.transfer(msg.sender, rewardAmount.mul(9).div(10));
            giftToken.burn(rewardAmount.div(10).div(10));
            giftToken.burn(rewardAmount.div(10));
            uint256 pioneerAmount = getPioneerReward(_pid, _user);
            if(pioneerAmount > 0) {
                pioneerInfoMap[_pid].rewardBalance = pioneerInfoMap[_pid].rewardBalance.sub(pioneerAmount); 
            }
        }
    }
    
    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfoList[_pid];
        if (block.number <= pool.lastRewardBlock) {
        // if (testBlockNum <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            // pool.lastRewardBlock = testBlockNum;
            return;
        }
        uint256 winessReward = (block.number.sub(pool.lastRewardBlock)).mul(minerBlockReward).mul(pool.weightPoint).div(totalWeightPoint);
        // uint256 winessReward = (testBlockNum.sub(pool.lastRewardBlock)).mul(minerBlockReward).mul(pool.weightPoint).div(totalWeightPoint);
        pool.share = pool.share.add(winessReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
        // pool.lastRewardBlock = testBlockNum;
        if(pioneerInfoMap[_pid].endBlock > block.number && block.number > pioneerInfoMap[_pid].startBlock) {
        // if(pioneerInfoMap[_pid].endBlock > testBlockNum && testBlockNum > pioneerInfoMap[_pid].startBlock) {
            pioneerInfoMap[_pid].endRewardDebt = pool.share;
        }
    }
    
    //get pioneer reward amount
    function getPioneerReward(uint256 _pid, address _user) public view returns (uint256) {
        PioneerInfo storage pioneer = pioneerInfoMap[_pid];
        if(pioneer.startBlock == 0) {
            return 0;
        }
        PoolInfo storage pool = poolInfoList[_pid];
        UserInfo storage user = userInfoMap[_pid][_user];
        
        uint256 startShare = user.rewardDebt > pioneer.startRewardDebt ? user.rewardDebt : pioneer.startRewardDebt;
        uint256 endShare;
        if (pool.lastRewardBlock > pioneer.endBlock) {
            endShare = pioneer.endRewardDebt;
        } else {
            // uint256 blockInterval = (pioneer.endBlock > testBlockNum ? testBlockNum : pioneer.endBlock).sub(pool.lastRewardBlock);
            uint256 blockInterval = (pioneer.endBlock > block.number ? block.number : pioneer.endBlock).sub(pool.lastRewardBlock);
            endShare = pool.share.add(blockInterval.mul(minerBlockReward).mul(INTERVAL).mul(pool.weightPoint).div(totalWeightPoint).div(pool.lpToken.balanceOf(address(this))));
        }
        if(startShare > endShare) return 0;
        uint256 pioneerReward = user.amount.mul(endShare.sub(startShare)).mul(pioneer.blockReward).div(minerBlockReward).div(INTERVAL);
        return pioneerReward > pioneer.rewardBalance ? pioneer.rewardBalance : pioneerReward;
    }

    // gift token transfer
    function giftTokenTransfer(address _to, uint256 _amount) internal {
        uint256 balance = giftToken.balanceOf(address(this));
        if (_amount > balance) {
            giftToken.transfer(_to, balance);
        } else {
            giftToken.transfer(_to, _amount);
        }
    }
    
    // ** The function below is for contract developer
    // add the new Deposit pool
    function add(uint256 _weightPoint, IERC20 _lpToken) public onlyOwner {
        totalWeightPoint = totalWeightPoint.add(_weightPoint);
        updateAllPools();
        poolInfoList.push(PoolInfo({
            lpToken: _lpToken,
            weightPoint: _weightPoint,
            share: 0,
            lastRewardBlock: block.number
            // lastRewardBlock: testBlockNum
        }));
    }

    // update the miner difficulty
    function updateMinerDifficulty() public onlyOwner{
        require(currentDifficulty < 6,"updateMinerDifficulty: max Difficulty");
        currentDifficulty = currentDifficulty.add(1);
        minerBlockReward = minerBlockReward.div(2);
    }
    
    // set the pioneer reward info
    function setPioneer(uint256 _pioneerTotalReward, uint256 _pioneerBlockReward, uint256 _pioneerEndBlock, uint256 _pioneerStartBlock, uint256 _pioneerPoolId) external onlyOwner {
        require(_pioneerTotalReward >= 0, "setPioneer: total reward value error");
        require(_pioneerBlockReward > 0, "setPioneer: block reward value error");
        require(_pioneerEndBlock > 0, "setPioneer: block interval value error");
        require(_pioneerPoolId < poolInfoList.length, "setPioneer: out off index error");
    
        PioneerInfo storage pioneerInfo =  pioneerInfoMap[_pioneerPoolId]; 
        pioneerInfo.poolId = _pioneerPoolId;
        pioneerInfo.totalReward = _pioneerTotalReward;
        pioneerInfo.blockReward = _pioneerBlockReward;
        pioneerInfo.endBlock = _pioneerEndBlock;
        pioneerInfo.startBlock = _pioneerStartBlock;
        pioneerInfo.rewardBalance = _pioneerTotalReward;
        pioneerInfo.startRewardDebt = poolInfoList[_pioneerPoolId].share;
        pioneerInfo.endRewardDebt = poolInfoList[_pioneerPoolId].share;
    }
    
    // change the fund pool address
    function changeFundPoolAddress(address _fundPool) public {
        require(msg.sender == fundPool, "dev: Insufficient permissions?");
        fundPool = _fundPool;
    }
    
    // update weightPoint of deposit pool
    function set(uint256 _pid, uint256 _weightPoint) public onlyOwner {
        updateAllPools();
        totalWeightPoint = totalWeightPoint.sub(poolInfoList[_pid].weightPoint).add(_weightPoint);
        poolInfoList[_pid].weightPoint = _weightPoint;
    }

    // set the migrator contract address.
    function setMigrator(IMigratorToken _migrator) public onlyOwner {
        migrator = _migrator;
    }

    // migrate the lp token to a new lp token contract
    function migrate(uint256 _pid) public onlyOwner {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = poolInfoList[_pid];
        IERC20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        IERC20 newLpToken = migrator.migrate(lpToken);
        require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
        pool.lpToken = newLpToken;
    }
    
}


interface IMigratorToken {
    function migrate(IERC20 token) external returns (IERC20);
}