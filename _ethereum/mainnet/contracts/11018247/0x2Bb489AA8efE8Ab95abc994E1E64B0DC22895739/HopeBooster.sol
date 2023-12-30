pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
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

pragma solidity ^0.6.0;

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
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract DepositorRole is Context {
    using Roles for Roles.Role;

    event DepositorAdded(address indexed account);
    event DepositorRemoved(address indexed account);

    Roles.Role private _depositors;

    constructor () internal {
        _addDepositor(_msgSender());
    }

    modifier onlyDepositor() {
        require(isDepositor(_msgSender()), "DepositorRole: caller does not have the Depositor role");
        _;
    }

    function isDepositor(address account) public view returns (bool) {
        return _depositors.has(account);
    }

    function addDepositor(address account) public onlyDepositor {
        _addDepositor(account);
    }

    function renounceDepositor() public {
        _removeDepositor(_msgSender());
    }

    function _addDepositor(address account) internal {
        _depositors.add(account);
        emit DepositorAdded(account);
    }

    function _removeDepositor(address account) internal {
        _depositors.remove(account);
        emit DepositorRemoved(account);
    }
}

interface HopeNonTradable {
    function totalSupply() external view returns (uint256);

    function totalClaimed() external view returns (uint256);

    function addClaimed(uint256 _amount) external;

    function setClaimed(uint256 _amount) external;

    function transfer(address receiver, uint numTokens) external returns (bool);

    function transferFrom(address owner, address buyer, uint numTokens) external returns (bool);

    function balanceOf(address owner) external view returns (uint256);

    function mint(address _to, uint256 _amount) external;

    function burn(address _account, uint256 value) external;
}

interface GiverOfHope {
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        IERC20 token; // Address of token contract.
        uint256 hopesPerDay; // The amount of hopes per day generated for each token staked
        uint256 maxStake; // The maximum amount of tokens which can be staked in this pool
        uint256 lastUpdateTime; // Last timestamp that HOPEs distribution occurs.
        uint256 accHopePerShare; // Accumulated HOPEs per share, times 1e12. See below.
    }

    function userInfo(uint256 _pId, address _address) external view returns (UserInfo memory);
    function poolInfo(uint256 _pId) external view returns (PoolInfo memory);
    function poolLength() external view returns (uint256);
}


contract HopeBooster is Ownable, DepositorRole {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 ropeAmount; // How many rope this user has here
        uint256 hopeAmount; // How many hope this user has here
        uint256 lastUpdate; // Timestamp of last update
    }

    // Info of each user that stakes LP tokens.
    mapping(address => UserInfo) public userInfo;

    // The ratio of token to burn (0%)
    uint16 public burnFee = 0;
    // The ratio of token to send to the treasury (10%)
    uint16 public treasuryFee = 100;
    uint16 public ratioMax = 1000;
    uint16 private ratioMaxHalf = 500;


    // Nb of ropes at which hopeIntermediateBonusMultiplier will be reached (Linear interpolation from 0 to there)
    uint256 public nbRopeIntermediateMultiplier = 30e18;
    // Nb of ropes at which hopeMaxBonusMultiplier will be reached (Linear interpolation from intermediate multiplier to there)
    uint256 public nbRopeMaxMultiplier = 100e18;

    // Bonus hope (5e4 = +50% bonus / 1e5 = +100% bonus) | Multiplier needs to be divided by 1e5
    uint256 public hopeIntermediateBonusMultiplier = 5e4;
    uint256 public hopeMaxBonusMultiplier = 1e5;

    HopeNonTradable public hope;
    IERC20 public rope;
    GiverOfHope public giverOfHope;
    address public treasuryAddr;

    uint256 private _totalRopesEarned;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Harvest(address indexed user, uint256 amount);

    constructor(IERC20 _ropeAddress, HopeNonTradable _hopeAddress, GiverOfHope _giverOfHopeAddress, address _treasuryAddr) public {
        rope = _ropeAddress;
        hope = _hopeAddress;
        giverOfHope = _giverOfHopeAddress;
        treasuryAddr = _treasuryAddr;
    }

    //////////////
    // Setters ///
    //////////////

    // Set the amount of ropes needed to reach the intermediate bonus multiplier
    function setNbRopeIntermediateMultiplier(uint256 _value) external onlyOwner {
        require(_value >= 0, "Value must be positive");
        nbRopeIntermediateMultiplier = _value;
    }

    // Set the amount of ropes needed to reach the max bonus multiplier
    function setNbRopeMaxMultiplier(uint256 _value) external onlyOwner {
        require(_value >= 0, "Value must be positive");
        nbRopeMaxMultiplier = _value;
    }

    // Set the intermediate bonus multiplier (ratio * 1e5)
    function setHopeIntermediateBonusMultiplier(uint256 _value) external onlyOwner {
        require(_value >= 0, "Value must be positive");
        hopeIntermediateBonusMultiplier = _value;
    }

    // Set the max bonus multiplier (ratio * 1e5)
    function setHopeMaxBonusMultiplier(uint256 _value) external onlyOwner {
        require(_value >= 0, "Value must be positive");
        hopeMaxBonusMultiplier = _value;
    }

    // Set new burnFee value (Percentage will be burnFee / ratioMax)
    function setBurnFee(uint16 _value) external onlyOwner {
        require(_value >= 0 && _value <= ratioMaxHalf && treasuryFee + _value <= ratioMaxHalf, "burnFee + treasuryFee > ratioMaxHalf");
        burnFee = _value;
    }

    // Set new treasuryFee value (Percentage will be burnFee / ratioMax)
    function setTreasuryFee(uint16 _value) external onlyOwner {
        require(_value >= 0 && _value <= ratioMaxHalf && burnFee + _value <= ratioMaxHalf, "burnFee + treasuryFee > ratioMaxHalf");
        treasuryFee = _value;
    }

    // Update treasury address by the previous treasury.
    function treasury(address _treasuryAddr) public {
        require(msg.sender == treasuryAddr, "Must be called from current treasury address");
        treasuryAddr = _treasuryAddr;
    }

    //////////////
    //////////////
    //////////////

    // Returns the total ropes earned
    // This is just purely used to display the total ropes earned by users on the frontend
    function totalRopesEarned() public view returns (uint256) {
        return _totalRopesEarned;
    }

    // Add ropes earned
    function _addRopesEarned(uint256 _amount) internal {
        _totalRopesEarned = _totalRopesEarned.add(_amount);
    }

    // Set ropes claimed to a custom value, for if we wanna reset the counter on new season release
    function setRopesEarned(uint256 _amount) public onlyOwner {
        require(_amount >= 0, "Cant be negative");
        _totalRopesEarned = _amount;
    }

    ///

    function getMultiplier(uint256 ropeAmount) public view returns (uint256) {
        if (ropeAmount == 0) {
            return 0;
        }

        if (ropeAmount > nbRopeMaxMultiplier) {
            return hopeMaxBonusMultiplier;
        } else if (ropeAmount > nbRopeIntermediateMultiplier) {
            uint256 remappedMax = nbRopeMaxMultiplier.sub(nbRopeIntermediateMultiplier);
            uint256 remappedAmount = ropeAmount.sub(nbRopeIntermediateMultiplier);
            return hopeIntermediateBonusMultiplier.add(remappedAmount.mul(hopeMaxBonusMultiplier.sub(hopeIntermediateBonusMultiplier)).div(remappedMax));
        } else {
            return ropeAmount.mul(hopeIntermediateBonusMultiplier).div(nbRopeIntermediateMultiplier);
        }
    }

    function getMultiplierOfAddress(address _addr) public view returns (uint256) {
        UserInfo storage user = userInfo[_addr];
        return getMultiplier(user.ropeAmount);
    }

    // View function to see pending HOPEs on frontend.
    function pendingHope(address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 hopePerDay = hopePerDayOfAddress(_user);
        uint256 multiplier = getMultiplier(user.ropeAmount);
        uint256 blockTime = block.timestamp;

        return blockTime.sub(user.lastUpdate).mul(hopePerDay.div(86400)).mul(multiplier).div(1e5);
    }

    function updateUser(address _user) public {
        UserInfo storage user = userInfo[_user];

        uint256 blockTime = block.timestamp;
        uint256 hopePerDay = hopePerDayOfAddress(_user);

        if (user.ropeAmount == 0 || hopePerDay == 0 || blockTime <= user.lastUpdate) {
            user.lastUpdate = blockTime;
            return;
        }

        uint256 hopeReward = pendingHope(_user);

        hope.mint(treasuryAddr, hopeReward.div(40)); // 2.5% HOPE for the treasury (Usable to purchase NFTs)
        hope.mint(address(this), hopeReward);

        user.hopeAmount = user.hopeAmount.add(hopeReward);
        user.lastUpdate = blockTime;
    }

    function hopePerDayOfAddress(address _addr) public view returns (uint256) {
        uint256  totalHopePerDay = 0;
        uint256 length = giverOfHope.poolLength();
        for (uint256 pid = 0; pid < length; ++pid) {
            uint256 hopesPerDay = giverOfHope.poolInfo(pid).hopesPerDay;
            uint256 amount = giverOfHope.userInfo(pid, _addr).amount;

            totalHopePerDay = totalHopePerDay.add(amount.mul(hopesPerDay));
        }

        return totalHopePerDay;
    }


    function deposit(address _addr, uint256 _amount, bool ignoreFee) external onlyDepositor {
        require(_amount > 0, "Amount deposited must be > 0");

        updateUser(_addr);

        uint256 _burnFee = 0;
        uint256 _treasuryFee = 0;

        if (!ignoreFee) {
            _burnFee = _amount.mul(burnFee).div(ratioMax);
            _treasuryFee = _amount.mul(treasuryFee).div(ratioMax);
        }

        uint256 userAmount = _amount.sub(_burnFee).sub(_treasuryFee);

        UserInfo storage user = userInfo[_addr];
        user.ropeAmount = user.ropeAmount.add(userAmount);
        _addRopesEarned(userAmount);

        if (_burnFee > 0) {
            rope.transferFrom(msg.sender, address(0x0), _burnFee);
        }

        if (_treasuryFee > 0) {
            rope.transferFrom(msg.sender, treasuryAddr, _treasuryFee);
        }

        rope.transferFrom(msg.sender, address(this), userAmount);

        emit Deposit(_addr, userAmount);
    }

    function withdraw() external {
        UserInfo storage user = userInfo[msg.sender];
        require(user.ropeAmount > 0, "Address balance is empty");

        updateUser(msg.sender);

        uint256 _ropeAmount = user.ropeAmount;
        uint256 _hopeAmount = user.hopeAmount;
        user.ropeAmount = 0;
        user.hopeAmount = 0;

        rope.transfer(msg.sender, _ropeAmount);
        hope.transfer(msg.sender, _hopeAmount);

        emit Withdraw(msg.sender, _ropeAmount);
        emit Harvest(msg.sender, _hopeAmount);
    }

    function harvest() external {
        UserInfo storage user = userInfo[msg.sender];
        require(user.hopeAmount > 0, "Address balance is empty");

        updateUser(msg.sender);

        uint256 _amount = user.hopeAmount;
        user.hopeAmount = 0;
        hope.transfer(msg.sender, _amount);

        emit Harvest(msg.sender, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() public {
        UserInfo storage user = userInfo[msg.sender];

        require(user.ropeAmount > 0, "Balance is empty");

        uint256 amount = user.ropeAmount;
        user.ropeAmount = 0;
        user.hopeAmount = 0;
        rope.transfer(msg.sender, amount);

        emit Withdraw(msg.sender, amount);
    }
}