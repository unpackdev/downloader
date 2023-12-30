pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

/* ========== copied from OpenZeppelin ========== */

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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
contract ReentrancyGuard {
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

    constructor () internal {
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

/* ========== interface of uniswap ========== */

interface Uniswap {
    function WETH() external pure returns (address);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

/* ========== interface of mining pool ========== */

interface Pool {
    function poolCoin() external view returns(address);
    function poolName() external view returns(string memory);
    function deposit(uint) external;
    function withdraw(uint) external;
}

/* ========== controller contract ========== */

contract Controller is Ownable, ReentrancyGuard {
    using SafeMath  for uint;
    using SafeERC20 for IERC20;
    
    struct poolInfo {
        uint    pid;
        string  name;
        address coin;
        address pool;
    }  
    
    struct groupInfo {
        uint    gid;
        uint    pid;
        address agent;
        uint    duration;
        uint    minAmount;
        uint    totalAmount;        
        uint    members;
        uint    lpAmount;
        uint    harvestAmount;
        uint    startTime;
        uint8   status;
        uint    txFee;
    }

    poolInfo[]  public pools;
    groupInfo[] public groups;

    uint public agentFee = 300;
    uint public governanceFee = 200;
    uint public gasRate = 120;
    uint public protectTime = 43200; // 12 hours

    address public governance;
    address public uniswap = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    
    mapping (uint => mapping (address => uint)) userInvest; 
    mapping (address => uint[])                 userGroup;
    mapping (address => uint[])                 agentGroup;

    event SetPool(uint indexed _pid, address indexed _poolAddress);
    event CreateGroup(uint indexed _gid, uint indexed _pid, uint _amount, uint _duration, address indexed _agent);
    event Start(uint indexed _gid, address indexed _starter);
    event Stop(uint indexed _gid, address indexed _stoper);
    event Join(uint indexed _gid, address indexed _user, uint _amount);
    event Quit(uint indexed _gid, address indexed _user, uint _amount);
    
    constructor () public {
        governance = msg.sender;
    }

    modifier onlyOwnerOrGovernance {
        require(owner() == _msgSender() || governance == _msgSender(), "caller is not the owner or governance");
        _;
    }

    /* ========== Setting system parameters by admin ========== */
    
    function setGovernance(address _governance) public onlyOwner {
        require(_governance != address(0), "Controller: invalid governance address");
        governance = _governance;
    }
    
    function setFee(uint _agentFee, uint _governanceFee) public onlyOwnerOrGovernance {
        require(_agentFee.add(_governanceFee) <= 1000, "Controller: total fee cannot exceed 1000(10%)");
        agentFee = _agentFee;
        governanceFee = _governanceFee;
    }

    function setGasRate(uint _rate) public onlyOwnerOrGovernance {
        require(_rate >= 100 && _rate <= 200, "Controller: gas rate cannot exceed 200(2x)");
        gasRate = _rate;
    }

    function setProtectTime(uint _time) public onlyOwnerOrGovernance {
        require(_time >= 0, "Controller: protect time should be greater than 0");
        protectTime = _time;
    } 

    function setUniswap(address _uniswap) public onlyOwnerOrGovernance {
        require(_uniswap != address(0), "Controller: uniswap address should not be equal to 0");
        uniswap = _uniswap;
    }
    
    /* ========== Setting mining pool by admin ========== */

    function addPool(address _pool) public onlyOwnerOrGovernance {
        require(_pool != address(0), "Controller: pool address should not be equal to 0");
        
        uint id = pools.length;
        (string memory name, address coin) = _getPoolInfo(_pool);
        
        pools.push(poolInfo(id, name, coin, _pool));

        emit SetPool(id, _pool);
        
    }
    
    function setPool(uint _pid, address _pool) public onlyOwnerOrGovernance {
        require(_pid >= 0 && _pid < pools.length, "Controller: invalid pool id");
        require(_pool != address(0), "Controller: uniswap address should not be equal to 0");
        
        (string memory name, address coin) = _getPoolInfo(_pool);
        
        pools[_pid] = poolInfo(_pid, name,  coin, _pool);

        emit SetPool(_pid, _pool);
    }

    function _getPoolInfo(address _pool) internal view returns (string memory name, address coin) {
        name = Pool(_pool).poolName();
        coin = Pool(_pool).poolCoin();
    }

    /* ========== Manage group by agent ========== */

    function createGroup(uint _pid, uint _amount, uint _duration) public nonReentrant returns (uint _gid) {
        require(_pid >= 0 && _pid < pools.length, "Controller: invalid pool id");
        require(_amount > 0, "Controller: amount should be greater than 0");
        require(_duration >= 0, "Controller: duration should be greater than 0!");
        
        _gid = groups.length;
        groups.push(groupInfo(_gid, _pid, _msgSender(), _duration, _amount, 0, 0, 0, 0, 0, 0, 0));
        
        agentGroup[_msgSender()].push(_gid);

        emit CreateGroup(_gid, _pid, _amount, _duration, _msgSender());
    }

    // This function could be execute by anyone with bearing the gas fee
    function start(uint _gid) public nonReentrant { 
        uint gasleftBeforeStart = gasleft();       
        
        require(_gid >= 0 && _gid < groups.length, "Controller: invalid group id");
        require(groups[_gid].totalAmount >= groups[_gid].minAmount, "Controller: the funds didn't meet the minimum requirements");
         
        IERC20(pools[groups[_gid].pid].coin).safeApprove(pools[groups[_gid].pid].pool, 0);
        IERC20(pools[groups[_gid].pid].coin).safeApprove(pools[groups[_gid].pid].pool, groups[_gid].totalAmount);
        Pool(pools[groups[_gid].pid].pool).deposit(groups[_gid].totalAmount);
         
        groups[_gid].startTime = block.timestamp;
        groups[_gid].lpAmount = IERC20(pools[groups[_gid].pid].pool).balanceOf(address(this));
        groups[_gid].status = 1;

        groups[_gid].txFee = gasleftBeforeStart.sub(gasleft()).mul(tx.gasprice);

        emit Start(_gid, _msgSender());
    }

    // This function could be execute by anyone with bearing the gas fee
    // People who execute this function could get gas subsidies of start and stop in invest coin
    function stop(uint _gid) public nonReentrant {
        uint gasleftBeforeStart = gasleft();

        require(_gid >= 0 && _gid < groups.length, "Controller: invalid group id");
        require(block.timestamp >= groups[_gid].startTime.add(groups[_gid].duration), "Controller: the time has not reached the minimum deadline");
        if (block.timestamp < groups[_gid].startTime.add(groups[_gid].duration).add(protectTime)) {
            require(_msgSender() == groups[_gid].agent, "Controller: This method can only be called by the agent during protection time");
        }
        
        uint coinBefore = IERC20(pools[groups[_gid].pid].coin).balanceOf(address(this));
        Pool(pools[groups[_gid].pid].pool).withdraw(groups[_gid].lpAmount);
        
        uint coinHarvest = IERC20(pools[groups[_gid].pid].coin).balanceOf(address(this)).sub(coinBefore);
        
        uint agentShare = coinHarvest.sub(groups[_gid].totalAmount).mul(agentFee).div(10000);
        uint governanceShare = coinHarvest.sub(groups[_gid].totalAmount).mul(governanceFee).div(10000);
        IERC20(pools[groups[_gid].pid].coin).safeTransfer(groups[_gid].agent, agentShare);
        IERC20(pools[groups[_gid].pid].coin).safeTransfer(governance, governanceShare);
        
        groups[_gid].txFee = groups[_gid].txFee.add(gasleftBeforeStart.sub(gasleft()).mul(tx.gasprice));
        uint senderCoin = calculateFee(groups[_gid].txFee, pools[groups[_gid].pid].coin).mul(gasRate).div(100);
        IERC20(pools[groups[_gid].pid].coin).safeTransfer(_msgSender(), senderCoin);

        groups[_gid].harvestAmount = coinHarvest.sub(agentShare).sub(governanceShare).sub(senderCoin);
        groups[_gid].lpAmount = 0;
        groups[_gid].status = 2;

        emit Stop(_gid, _msgSender());
    }

    function calculateFee(uint _ethAmount, address _coin) internal view returns (uint) {
        address[] memory path = new address[](2);
        
        path[0] = _coin;
        path[1] = Uniswap(uniswap).WETH();

        uint[] memory amountInMin = Uniswap(uniswap).getAmountsIn(_ethAmount, path);
        return amountInMin[0];
    }

    /* ========== join and quit group by user ========== */
    function join(uint _gid, uint _amount) public payable nonReentrant returns (bool) {
        require(_gid >= 0 && _gid < groups.length, "Controller: invalid group id");
        require(groups[_gid].status == 0, "Controller: investment has started, you cannot join the group");
        require(_amount > 0, "Controller: amount should be greater than 0");
               
        IERC20(pools[groups[_gid].pid].coin).safeTransferFrom(_msgSender(), address(this), _amount);
        
        if (userInvest[_gid][_msgSender()] == 0) {
            groups[_gid].members = groups[_gid].members.add(1);
            userGroup[_msgSender()].push(_gid);
        }

        groups[_gid].totalAmount = groups[_gid].totalAmount.add(_amount);
        userInvest[_gid][_msgSender()] = userInvest[_gid][_msgSender()].add(_amount);

        emit Join(_gid, _msgSender(), _amount);
    }

    function quit(uint _gid) public nonReentrant {
        require(_gid >= 0 && _gid < groups.length, "Controller: invalid group id");
        require(userInvest[_gid][_msgSender()] > 0, "Controller: you're not in this group");
        require(groups[_gid].status != 1, "Controller: amount should be greater than 0");
        
        uint amount;
        
        if (groups[_gid].status == 0) {
            amount = userInvest[_gid][_msgSender()];
            IERC20(pools[groups[_gid].pid].coin).safeTransfer(_msgSender(), amount);
            
            groups[_gid].totalAmount = groups[_gid].totalAmount.sub(amount);
            groups[_gid].members = groups[_gid].members.sub(1);
        } else {
            amount = groups[_gid].harvestAmount.mul(userInvest[_gid][_msgSender()]).div(groups[_gid].totalAmount);
            IERC20(pools[groups[_gid].pid].coin).safeTransfer(_msgSender(), amount);
        }
        
        userInvest[_gid][_msgSender()] = 0;
        emit Quit(_gid, _msgSender(), amount);
    }
    
    /* ========== view function ========== */
    
    function poolLength() public view returns (uint) {
        return pools.length;
    }

    function groupLength() public view returns (uint) {
        return groups.length;
    }
    
    function getAgentGroups(address _agent) public view returns(uint[] memory) {
        return agentGroup[_agent];
    }
    
    function getUserGroups(address _user) public view returns (uint[] memory) {
        return userGroup[_user];
    }
    
    function getUserInvest(uint _gid, address _user) public view returns (uint) {
        require(_gid >= 0 && _gid < groups.length, "invalid _gid!");
        return userInvest[_gid][_user];
    }
    
    function withdrawable(uint _gid, address _user) public view returns (uint) {
        require(_gid >= 0 && _gid < groups.length, "invalid gid!");
        if (userInvest[_gid][_user] == 0) return 0;
        
        if (groups[_gid].status == 0) {
            return userInvest[_gid][_user];
        } else if (groups[_gid].status == 1) {
            return 0;
        } else if (groups[_gid].status == 2) {
            return groups[_gid].harvestAmount.mul(userInvest[_gid][_user]).div(groups[_gid].totalAmount);
        }
    }
}