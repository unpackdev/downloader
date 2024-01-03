pragma solidity 0.6.2;
pragma experimental ABIEncoderV2;


// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

interface IBalance {
    struct swap_t {
        uint256 reserve; //抵押token
        uint256 supply; //QIAN
    }

    function withdraw(
        address receiver,
        address token,
        uint256 reserve
    ) external;

    function deposit(
        address payer,
        address token,
        uint256 reserve
    ) external payable;

    function burn(
        address payer,
        address token,
        uint256 supply
    ) external;

    function mint(
        address receiver,
        address token,
        uint256 supply
    ) external;

    function exchange(
        address payer,
        address owner,
        address token,
        uint256 supply,
        uint256 reserve
    ) external;

    function reserve(address who, address token)
        external
        view
        returns (uint256);

    function supply(address who, address token) external view returns (uint256);

    function reserve(address token) external view returns (uint256);

    function supply(address token) external view returns (uint256);

    function swaps(address who, address token)
        external
        view
        returns (swap_t memory);

    function gswaps(address token) external view returns (swap_t memory);

    function gsupply() external view returns (uint256);
}

interface IEnv {
    function bade(address token) external view returns (uint256);
    function aade(address token) external view returns (uint256);
    function fade(address token) external view returns (uint256);
    function gade() external view returns(uint256);
    function line(address token) external view returns (uint256);
    function step() external view returns (uint256);
    function oracle() external view returns (address);
    function tokens() external view returns (address[] memory);
    function gtoken() external view returns (address);
    function hasToken(address token) external view returns(bool);
    function deprecatedTokens(address token) external view returns(bool);
    function lockdown() external view returns(bool);
}

interface IAsset {
    function deposit(
        address payer,
        address token,
        uint256 reserve
    ) external payable returns (uint256);

    function withdraw(
        address payable receiver,
        address token,
        uint256 reserve
    ) external returns (uint256);

    function balances(address token) external view returns (uint256);

    function decimals(address token) external view returns (uint256);
}

interface IPrice {
    function value(address token) external view returns (uint256, bool);
}

interface IBurnable {
    function burn(address who, uint256 supply) external;
}

interface IMintable {
    function mint(address who, uint256 supply) external;
}

interface IBroker {
    function publish(bytes32 topic, bytes calldata data) external;
}

interface IOrderbase {
    function holder(uint256 index) external view returns (address, address);
    function index(address owner, address token) external view returns (uint256);
    function owners(address token, uint256 begin, uint256 end) external view returns (address[] memory);
    function owners(address token) external view returns (address[] memory);
    function tokens(address owner) external view returns (address[] memory);
    function size() external view returns (uint256);
    function insert(address owner, address token) external returns (uint256);
}

/**
 * @title VersionedInitializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 *
 * @author Aave, inspired by the OpenZeppelin Initializable contract
 */
abstract contract VersionedInitializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    uint256 private lastInitializedRevision;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        uint256 revision = getRevision();
        require(
            initializing ||
                isConstructor() ||
                revision > lastInitializedRevision,
            "Contract instance has already been initialized"
        );

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            lastInitializedRevision = revision;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /// @dev returns the revision number of the contract.
    /// Needs to be defined in the inherited class as a constant.
    function getRevision() internal virtual pure returns (uint256);

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        uint256 cs;
        //solium-disable-next-line
        assembly {
            cs := extcodesize(address())
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[16] private ______gap;
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
    bool private _notEntered;

    // constructor() internal {
    //     // Storing an initial non-zero value makes deployment a bit more
    //     // expensive, but in exchange the refund on every call to nonReentrant
    //     // will be lower in amount. Since refunds are capped to a percetange of
    //     // the total transaction's gas, it is best to keep them low in cases
    //     // like this one, to increase the likelihood of the full refund coming
    //     // into effect.
    //     _notEntered = true;
    // }

    function initializeReentrancyGuard() internal {
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

contract Main is ReentrancyGuard, VersionedInitializable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    event Deposit(
        address indexed sender,
        address indexed token,
        uint256 reserve,
        uint256 sysbalance
    );
    event Withdraw(
        address indexed sender,
        address indexed token,
        uint256 reserve,
        uint256 sysbalance
    );
    event Mint(
        address indexed sender,
        address indexed token,
        uint256 supply,
        uint256 coinsupply
    );
    event Burn(
        address indexed sender,
        address indexed token,
        uint256 supply,
        uint256 coinsupply
    );
    event Open(
        address indexed sender,
        address indexed token,
        uint256 reserve,
        uint256 supply,
        uint256 sysbalance,
        uint256 coinsupply
    );
    event Exchange(
        address indexed sender,
        uint256 supply,
        address indexed token,
        uint256 reserve,
        uint256 sysbalance,
        uint256 coinsupply,
        address[] frozens,
        uint256 price
    );

    address public env;
    address public balance;
    address public coin;
    address public asset;
    address public broker;
    address public orderbase;

    function initialize(
        address _env,
        address _balance,
        address _asset,
        address _coin,
        address _broker,
        address _orderbase
    ) public initializer {
        initializeReentrancyGuard();
        env = _env;
        balance = _balance;
        asset = _asset;
        coin = _coin;
        broker = _broker;
        orderbase = _orderbase;
    }

    function getRevision() internal override pure returns (uint256) {
        return uint256(0x1);
    }

    function deposit(address token, uint256 reserve)
        public
        payable
        nonReentrant
    {
        uint256 _reserve = _deposit(token, reserve);
        IBroker(broker).publish(keccak256("deposit"), abi.encode(msg.sender, token, _reserve));
        IOrderbase(orderbase).insert(msg.sender, token);
        emit Deposit(
            msg.sender,
            token,
            _reserve,
            IAsset(asset).balances(token)
        );
    }

    function withdraw(address token, uint256 reserve) public nonReentrant {
        _withdraw(token, reserve);
        //注: 不需要放到 @_withdraw, 因为 exchange 会用到 @_withdraw, 且不要求 >= bade. 
        require(ade(msg.sender, token) >= IEnv(env).aade(token), "Main.withdraw.EID00063");
        IBroker(broker).publish(keccak256("withdraw"), abi.encode(msg.sender, token, reserve));
        emit Withdraw(
            msg.sender,
            token,
            reserve,
            IAsset(asset).balances(token)
        );
    }

    //增发
    function mint(address token, uint256 supply) public nonReentrant {
        _mint(token, supply);
        IBroker(broker).publish(keccak256("mint"), abi.encode(msg.sender, token, supply));
        emit Mint(msg.sender, token, supply, IERC20(coin).totalSupply());
    }

    //销毁
    function burn(address token, uint256 supply) public nonReentrant {
        _burn(token, supply);
        IBroker(broker).publish(keccak256("burn"), abi.encode(msg.sender, token, supply));
        emit Burn(msg.sender, token, supply, IERC20(coin).totalSupply());
    }

    //开仓
    function open(
        address token, //deposit token
        uint256 reserve,
        uint256 supply
    ) public payable nonReentrant {
        uint256 _reserve = _deposit(token, reserve);
        _mint(token, supply);
        IBroker(broker).publish(keccak256("open"), abi.encode(msg.sender, token, _reserve, supply));
        IOrderbase(orderbase).insert(msg.sender, token);
        emit Open(
            msg.sender,
            token,
            _reserve,
            supply,
            IAsset(asset).balances(token),
            IERC20(coin).totalSupply()
        );
    }

    //清算
    function exchange(
        uint256 supply, //QIAN
        address token,
        address[] memory frozens
    ) public nonReentrant {
        require(!IEnv(env).lockdown(), "Main.exchange.EID00030");
        require(supply != 0, "Main.exchange.EID00090");
        address[] memory _frozens = _refreshfrozens(token, frozens);
        require(_frozens.length != 0, "Main.exchange.EID00091");

        //fix: 缓存被冻结仓位的状态, 当兑换人自己的仓位也属于冻结仓位时, 避免由于其他仓位数据划转(到兑换人的仓位)而导致兑换人自己的仓位数据发生变化
        IBalance.swap_t[] memory swaps = new IBalance.swap_t[](_frozens.length);
        for (uint256 i = 0; i < _frozens.length; ++i) {
            //fix: Stack too deep, try removing local variables.
            (address _owner, address _token) = (_frozens[i], token);
            swaps[i] = IBalance(balance).swaps(_owner, _token);
        }

        uint256 _supply = supply;
        uint256 reserve = 0;
        for (uint256 i = 0; i < _frozens.length; ++i) {
            //fix: Stack too deep, try removing local variables.
            (address _owner, address _token) = (_frozens[i], token);

            uint256 rid = Math.min(swaps[i].supply, _supply);
            _supply = _supply.sub(rid);

            uint256 lot = rid.mul(swaps[i].reserve).div(swaps[i].supply);
            lot = Math.min(lot, swaps[i].reserve);

            IBalance(balance).exchange(msg.sender, _owner, _token, rid, lot);
            IBroker(broker).publish(
                keccak256("burn"),
                abi.encode(_owner, _token, rid)
            );
            reserve = reserve.add(lot);
            if (_supply == 0) break;
        }

        uint256 __supply = supply.sub(_supply);
        IBurnable(coin).burn(msg.sender, __supply);
        _withdraw(token, reserve);
        IBroker(broker).publish(
            keccak256("exchange"),
            abi.encode(msg.sender, __supply, token, reserve, _frozens)
        );
        emit Exchange(
            msg.sender,
            __supply,
            token,
            reserve,
            IAsset(asset).balances(token),
            IERC20(coin).totalSupply(),
            _frozens,
            _price(token)
        );
    }

    //充足率 (Adequacy ratio)

    //@who @token 对应的资产充足率
    function ade(address owner, address token) public view returns (uint256) {
        IBalance.swap_t memory swap = IBalance(balance).swaps(owner, token);
        if (swap.supply == 0) return uint256(-1);

        //uint256 coinprice = 1e18; (每"个"QIAN的价格)
        //(swap.reserve / 10**_dec(token)) * _price(token)
        //uint256 reservevalue = swap.reserve.mul(_price(token)).div(10**_dec(token));  //1e18
        //(swap.supply / 10**_dec(coin)) * coinprice;
        //uint256 coinvalue = swap.supply.mul(coinprice).div(10**_dec(coin)) //1e18
        //ade = (reservevalue/coinvalue) * 1e18 (充足率的表示单位)
        //uint256 ade = swap.reserve.mul(_price(token)).div(10**_dec(token)).mul(1e18).div(swap.supply.mul(1e18).div(10**_dec(coin)))
        //            = swap.reserve.mul(_price(token)).mul(1e18).div(10**_dec(token)).div(swap.supply.mul(1e18).div(10**_dec(coin)))
        //            = swap.reserve.mul(_price(token)).mul(10**_dec(coin)).div(10**_dec(token)).div(swap.supply)

        return
            swap
                .reserve
                .mul(_price(token))
                .mul(10**_dec(coin))
                .div(10**_dec(token))
                .div(swap.supply);
    }

    //@token 对应的资产充足率
    function ade(address token) public view returns (uint256) {
        IBalance.swap_t memory gswap = IBalance(balance).gswaps(token);
        if (gswap.supply == 0) return uint256(-1);
        return
            gswap
                .reserve
                .mul(_price(token))
                .mul(10**_dec(coin))
                .div(10**_dec(token))
                .div(gswap.supply);
    }

    //系统总资产充足率
    function ade() public view returns (uint256) {
        uint256 reserve_values = 0;
        address[] memory tokens = IEnv(env).tokens();
        for (uint256 i = 0; i < tokens.length; ++i) {
            reserve_values = reserve_values.add(
                IBalance(balance).reserve(tokens[i]).mul(_price(tokens[i])).div(
                    10**_dec(tokens[i])
                )
            );
        }
        uint256 gsupply_values = IBalance(balance).gsupply();
        if (gsupply_values == 0) return uint256(-1);
        return reserve_values.mul(10**_dec(coin)).div(gsupply_values);
    }

    /** innernal functions */

    function _burn(address token, uint256 supply) internal {
        //全局停机
        require(!IEnv(env).lockdown(), "Main.burn.EID00030");
        //被废弃的代币生成的QIAN仍然允许销毁.
        require(IEnv(env).hasToken(token), "Main.burn.EID00070");
        uint256 _supply = IBalance(balance).supply(msg.sender, token);
        require(_supply >= supply, "Main.burn.EID00080");
        IBurnable(coin).burn(msg.sender, supply);
        IBalance(balance).burn(msg.sender, token, supply);
    }

    function _deposit(address token, uint256 reserve) internal returns(uint256) {
        require(!IEnv(env).lockdown(), "Main.deposit.EID00030");
        //仅当受支持的代币才允许增加准备金(被废弃的代币不允许)
        require(IEnv(env).hasToken(token) && !IEnv(env).deprecatedTokens(token), "Main.deposit.EID00070");
        uint256 _reserve = IAsset(asset).deposit.value(msg.value)(
            msg.sender,
            token,
            reserve
        );
        IBalance(balance).deposit(msg.sender, token, _reserve);
        return _reserve;
    }

    function _mint(address token, uint256 supply) internal {
        require(!IEnv(env).lockdown(), "Main.mint.EID00030");
        require(IEnv(env).hasToken(token) && !IEnv(env).deprecatedTokens(token), "Main.mint.EID00071");

        uint256 _step = IEnv(env).step();
        require(supply >= _step, "Main.mint.EID00092");

        IMintable(coin).mint(msg.sender, supply);
        IBalance(balance).mint(msg.sender, token, supply);

        //后置充足率检测.
        require(ade(msg.sender, token) >= IEnv(env).bade(token), "Main.mint.EID00062");

        uint256 _supply = IBalance(balance).supply(token);
        uint256 _line = IEnv(env).line(token);
        require(_supply <= _line, "Main.mint.EID00093");
    }

    function _withdraw(address token, uint256 reserve) internal {
        require(!IEnv(env).lockdown(), "Main.withdraw.EID00030");
        require(IEnv(env).hasToken(token), "Main.withdraw.EID00070");
        uint256 _reserve = IBalance(balance).reserve(msg.sender, token);
        require(_reserve >= reserve, "Main.withdraw.EID00081");
        IBalance(balance).withdraw(msg.sender, token, reserve);
        IAsset(asset).withdraw(msg.sender, token, reserve);
        //充足率检测在外部调用处进行.
    }

    function _price(address token) internal view returns (uint256) {
        (uint256 value, bool valid) = IPrice(IEnv(env).oracle()).value(
            token
        );
        require(valid, "Main.price.EID00094");
        return value;
    }

    //仓位是否被冻结.
    function _isfade(address owner, address token)
        internal
        view
        returns (bool)
    {
        return ade(owner, token) < IEnv(env).fade(token);
    }

    //从@frozens过滤已经不再是冻结状态的仓位
    function _refreshfrozens(address token, address[] memory frozens)
        internal
        view
        returns (address[] memory)
    {
        uint256 n = 0;
        for (uint256 i = 0; i < frozens.length; ++i) {
            if (_isfade(frozens[i], token)) {
                frozens[n++] = frozens[i];
            }
        }
        address[] memory _frozens = new address[](n);
        for (uint256 i = 0; i < n; ++i) {
            _frozens[i] = frozens[i];
        }
        return _frozens;
    }

    function _dec(address token) public view returns (uint256) {
        return IAsset(asset).decimals(token);
    }
}