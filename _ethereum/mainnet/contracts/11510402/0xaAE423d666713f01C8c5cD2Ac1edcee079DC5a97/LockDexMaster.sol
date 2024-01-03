pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

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

interface ILockDexPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

struct LockingPeriod {
    uint64 lockedEpoch;
    uint64 unlockEpoch;
    uint256 amount;
}

interface IMigratorLDX {
    // Perform LP token migration from legacy UniswapV2 to LockDex.
    // Take the current LP token address and return the new LP token address.
    // Migrator should have full access to the caller's LP token.
    // Return the new LP token address.
    //
    // XXX Migrator must have allowance access to UniswapV2 LP tokens.
    // LockDex must mint EXACTLY the same amount of LockDex LP tokens or
    // else something bad will happen. Traditional UniswapV2 does not
    // do that so be careful!
    function migrate(address token) external returns (address);
}

interface ILockDexReward {
    function payReward(address _lpToken, address _user, LockingPeriod[] memory _lockingPeriods, uint64 _lastRewardEpoch) external returns (uint);
    function pendingReward(address _lpToken, LockingPeriod[] memory _lockingPeriods, uint64 _lastRewardEpoch) external view returns (uint);
    function availablePair(address _lpToken) external view returns (bool);
}

// LockDexMaster is the master of LockDex. He can make LockDex and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once LDX is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract LockDexMaster is Ownable() {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event onDeposit(address indexed token, address indexed user, uint256 amount, uint64 lockedEpoch, uint64 unlockEpoch);
    event onWithdraw(address indexed token, address indexed user, uint256 amount);

    struct UserTokenInfo {
        uint256 deposited; // incremented on successful deposit
        uint256 withdrawn; // incremented on successful withdrawl
        LockingPeriod[] lockingPeriods; // added to on successful deposit
        uint64 lastRewardEpoch;
        uint256 totalRewardPaid; // total paid LDX reward
    }

    // map erc20 token to user address to release schedule
    mapping(address => mapping(address => UserTokenInfo)) tokenUserMap;

    struct LiquidityTokenomics {
        uint64[] epochs;
        mapping (uint64 => uint256) releaseMap; // map epoch -> amount withdrawable
    }

    // map erc20 token to release schedule
    mapping(address => LiquidityTokenomics) tokenEpochMap;

    // Fast mapping to prevent array iteration in solidity
    mapping(address => bool) public lockedTokenLookup;

    // A dynamically-sized array of currently locked tokens
    address[] public tokens;

    // smart contracts which can deposit
    mapping(address => bool) public greyList;

    // Fast mapping to prevent array iteration in solidity
    mapping(address => bool) public usersLookup;

    // A dynamically-sized array of users locked tokens
    address[] public users;

    // Blocked Pair
    mapping(address => bool) public blockedPair;

    // LockDexRouter02 address
    address public lockDexRouter02;

    // The reward contract.
    ILockDexReward public lockDexReward;

    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    IMigratorLDX public migrator;

    bool public started;

    function lockTokenForUser(address token, address user, uint256 amount, uint64 unlock_date) internal {
        require(unlock_date < 10000000000, 'Enter an unix timestamp in seconds, not miliseconds');
        uint64 _unlockEpoch = uint64(block.timestamp) < unlock_date ? unlock_date : 0;
        LiquidityTokenomics storage liquidityTokenomics = tokenEpochMap[token];

        if (!lockedTokenLookup[token]) {
            tokens.push(token);
            lockedTokenLookup[token] = true;
        }
        if (!usersLookup[user]) {
            users.push(user);
            usersLookup[user] = true;
        }

        if (liquidityTokenomics.releaseMap[_unlockEpoch] > 0) {
            liquidityTokenomics.releaseMap[_unlockEpoch] = liquidityTokenomics.releaseMap[_unlockEpoch].add(amount);
        } else {
            liquidityTokenomics.epochs.push(_unlockEpoch);
            liquidityTokenomics.releaseMap[_unlockEpoch] = amount;
        }
        UserTokenInfo storage uto = tokenUserMap[token][user];
        uto.deposited = uto.deposited.add(amount);
        LockingPeriod[] storage lockingPeriod = uto.lockingPeriods;
        lockingPeriod.push(LockingPeriod(uint64(block.timestamp), _unlockEpoch, amount));

        emit onDeposit(token, user, amount, uint64(block.timestamp), _unlockEpoch);
    }

    function depositToken(address token, uint256 amount, uint64 unlock_date) external {
        require(started, 'not started!');
        require(msg.sender == tx.origin || greyList[msg.sender], 'not grey listed!');
        require(blockedPair[token] == false, 'blocked!');
        require(amount > 0, 'Your attempting to trasfer 0 tokens');
        require(lockDexReward.availablePair(token) == true, "invalid pair");

        uint256 allowance = IERC20(token).allowance(msg.sender, address(this));
        require(allowance >= amount, 'You need to set a higher allowance');

        require(IERC20(token).transferFrom(msg.sender, address(this), amount), 'Transfer failed');
        lockTokenForUser(token, msg.sender, amount, unlock_date);
    }

    function mintAndLockTokenForUser(address token, address user, uint64 unlock_date) external returns(uint256) {
        require(msg.sender == lockDexRouter02, "not router!");

        ILockDexPair pair = ILockDexPair(token);
        uint256 oldBalance = pair.balanceOf(address(this));
        pair.mint(address(this));
        uint256 amount = pair.balanceOf(address(this)) - oldBalance;

        lockTokenForUser(token, user, amount, unlock_date);
        return amount;
    }

    function withdrawToken(address token, uint256 amount) external {
        require(amount > 0, 'Your attempting to withdraw 0 tokens');
        require(msg.sender == tx.origin || greyList[msg.sender], 'not grey listed!');
        payRewardForUser(token, msg.sender);

        UserTokenInfo storage uto = tokenUserMap[token][msg.sender];
        LockingPeriod[] storage periods = uto.lockingPeriods;
        LiquidityTokenomics storage liquidityTokenomics = tokenEpochMap[token];
        mapping (uint64 => uint256) storage releaseMap = liquidityTokenomics.releaseMap;
        uint64[] storage epochs = liquidityTokenomics.epochs;
        uint256 availableAmount = 0;
        uint64 currentEpoch = uint64(block.timestamp);

        for (uint i = 1; i <= periods.length; i += 1) {
            if (periods[i - 1].unlockEpoch <= currentEpoch) {
                LockingPeriod storage period = periods[i - 1];
                uint64 unlockEpoch = period.unlockEpoch;
                availableAmount += period.amount;
                releaseMap[unlockEpoch] = releaseMap[unlockEpoch].sub(period.amount);

                if (releaseMap[unlockEpoch] == 0 && availableAmount <= amount) {
                    for (uint j = 0; j < epochs.length; j += 1) {
                        if (epochs[j] == unlockEpoch) {
                            epochs[j] = epochs[epochs.length - 1];
                            epochs.pop();
                            break;
                        }
                    }
                }
                if (availableAmount > amount) {
                    period.amount = availableAmount.sub(amount);
                    releaseMap[unlockEpoch] = releaseMap[unlockEpoch].add(period.amount);
                    break;
                } else {
                    LockingPeriod storage lastPeriod = periods[periods.length - 1];
                    period.amount = lastPeriod.amount;
                    period.lockedEpoch = lastPeriod.lockedEpoch;
                    period.unlockEpoch = lastPeriod.unlockEpoch;
                    periods.pop();

                    if (availableAmount == amount) {
                        break;
                    } else {
                        i -= 1;
                    }
                }
            }
        }

        require(availableAmount >= amount, "insufficient withdrawable amount");
        uto.withdrawn = uto.withdrawn.add(amount);
        require(IERC20(token).transfer(msg.sender, amount), 'Transfer failed');

        emit onWithdraw(token, msg.sender, amount);
    }

    function getWithdrawableBalance(address token, address user) external view returns (uint256) {
        UserTokenInfo storage uto = tokenUserMap[token][address(user)];
        uint arrayLength = uto.lockingPeriods.length;
        uint256 withdrawable = 0;
        for (uint i = 0; i < arrayLength; i += 1) {
            LockingPeriod storage lockingPeriod = uto.lockingPeriods[i];
            if (lockingPeriod.unlockEpoch <= uint64(block.timestamp)) {
                withdrawable = withdrawable.add(lockingPeriod.amount);
            }
        }
        return withdrawable;
    }

    function getUserTokenInfo (address token, address user) external view returns (uint256, uint256, uint64, uint256) {
        UserTokenInfo storage uto = tokenUserMap[address(token)][address(user)];
        return (uto.deposited, uto.withdrawn, uto.lastRewardEpoch, uto.lockingPeriods.length);
    }

    function getUserLockingAtIndex (address token, address user, uint index) external view returns (uint64, uint64, uint256) {
        UserTokenInfo storage uto = tokenUserMap[address(token)][address(user)];
        LockingPeriod storage lockingPeriod = uto.lockingPeriods[index];
        return (lockingPeriod.lockedEpoch, lockingPeriod.unlockEpoch, lockingPeriod.amount);
    }

    function getTokenReleaseInfo (address token) external view returns (uint256, uint256) {
        LiquidityTokenomics storage liquidityTokenomics = tokenEpochMap[address(token)];
        ILockDexPair pair = ILockDexPair(token);
        uint balance = pair.balanceOf(address(this));
        return (balance, liquidityTokenomics.epochs.length);
    }

    function getTokenReleaseAtIndex (address token, uint index) external view returns (uint256, uint256) {
        LiquidityTokenomics storage liquidityTokenomics = tokenEpochMap[address(token)];
        uint64 epoch = liquidityTokenomics.epochs[index];
        uint256 amount = liquidityTokenomics.releaseMap[epoch];
        return (epoch, amount);
    }

    function lockedTokensLength() external view returns (uint) {
        return tokens.length;
    }

    function payRewardForUser(address token, address user) internal {
        if (blockedPair[token] == true) {
            return;
        }
        UserTokenInfo storage uto = tokenUserMap[token][user];
        LockingPeriod[] storage periods = uto.lockingPeriods;

        uint256 reward = lockDexReward.payReward(token, user, periods, uto.lastRewardEpoch);
        uto.lastRewardEpoch = uint64(block.timestamp);

        uto.totalRewardPaid += reward;
    }

    // pay ldx reward to user
    function payReward(address token) external {
        require(msg.sender == tx.origin || greyList[msg.sender], 'not grey listed!');
        payRewardForUser(token, msg.sender);
    }

    // pending ldx reward to user
    function pendingReward(address token, address user) external view returns (uint) {
        UserTokenInfo storage uto = tokenUserMap[token][user];
        LockingPeriod[] storage periods = uto.lockingPeriods;
        return lockDexReward.pendingReward(token, periods, uto.lastRewardEpoch);
    }

    // set grey list
    function setGreyList(address _contract, bool allow) external onlyOwner {
        greyList[_contract] = allow;
    }

    // Set the migrator contract. Can only be called by the owner.
    function setMigrator(IMigratorLDX _migrator) external onlyOwner {
        migrator = _migrator;
    }

    // Set the reward contract. Can only be called by the owner.
    function setReward(ILockDexReward _reward) external onlyOwner {
        lockDexReward = _reward;
    }

    // Migrate lp token to another lp contract. Can be called by anyone. We trust that migrator contract is good.
    function migrate(address lpToken) external {
        require(address(migrator) != address(0), "migrate: no migrator");
        require(lockedTokenLookup[lpToken], "not locked!");

        uint256 bal = IERC20(lpToken).balanceOf(address(this));
        address newLpToken;
        if (bal > 0) {
            IERC20(lpToken).safeApprove(address(migrator), bal);
            newLpToken = migrator.migrate(lpToken);
            require(bal == IERC20(newLpToken).balanceOf(address(this)), "migrate: bad");
        }
        for (uint i = 0; i < users.length; i += 1) {
            address user = users[i];
            tokenUserMap[newLpToken][user] = tokenUserMap[lpToken][user];
            delete tokenUserMap[lpToken][user];
        }

        tokenEpochMap[newLpToken] = tokenEpochMap[lpToken];
        mapping (uint64 => uint256) storage releaseMap = tokenEpochMap[newLpToken].releaseMap;
        uint64[] storage epochs = tokenEpochMap[newLpToken].epochs;
        for (uint j = 0; j < epochs.length; j += 1) {
            releaseMap[epochs[j]] = tokenEpochMap[lpToken].releaseMap[epochs[j]];
        }
        delete tokenEpochMap[lpToken];
        lockedTokenLookup[lpToken] = false;
        lockedTokenLookup[newLpToken] = true;

        for (uint i = 0; i < tokens.length; i += 1) {
            if (tokens[i] == lpToken) {
                tokens[i] = newLpToken;
            }
        }
    }

    function setRouter02(address _lockDexRouter02) external onlyOwner {
        lockDexRouter02 = _lockDexRouter02;
    }

    function blockPair(address _token, bool _blocked) external onlyOwner {
        blockedPair[_token] = _blocked;
    }

    function start() external onlyOwner {
        started = true;
    }
}