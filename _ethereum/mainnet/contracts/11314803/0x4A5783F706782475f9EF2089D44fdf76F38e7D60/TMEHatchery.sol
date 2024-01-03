// File: @openzeppelin\contracts\math\SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// File: node_modules\@openzeppelin\contracts\GSN\Context.sol



pragma solidity ^0.6.0;

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

// File: @openzeppelin\contracts\access\Ownable.sol



pragma solidity ^0.6.0;

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

// File: @openzeppelin\contracts\utils\ReentrancyGuard.sol



pragma solidity ^0.6.0;

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

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol



pragma solidity ^0.6.0;

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

// File: node_modules\@openzeppelin\contracts\token\ERC20\IERC20.sol



// File: node_modules\@openzeppelin\contracts\math\SafeMath.sol


// File: node_modules\@openzeppelin\contracts\utils\Address.sol



pragma solidity ^0.6.2;

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
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

// File: @openzeppelin\contracts\token\ERC20\SafeERC20.sol



pragma solidity ^0.6.0;




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

// File: contracts\TMEAccessControl.sol

pragma solidity ^0.6.0;

// main staking contract
contract TMEAccessControl is Ownable{

  
    bool public pausedHatch;

    modifier whenNotPausedHatch() {
        require(!pausedHatch, "Hatching is paused!");
        _;
    }

    modifier whenPausedHatch {
        require(pausedHatch, "Hatching is not paused!");
        _;
    }

    function pauseHatch() public onlyOwner whenNotPausedHatch {
        pausedHatch = true;
    }

    function unpauseHatch() public onlyOwner whenPausedHatch {
        pausedHatch = false;
    }

    bool public pausedIncubate;

     modifier whenNotPausedIncubate() {
        require(!pausedIncubate, "Incubate is paused!");
        _;
    }

    modifier whenPausedIncubate {
        require(pausedIncubate, "Incubate is not paused!");
        _;
    }

    function pauseIncubate() public onlyOwner whenNotPausedIncubate {
        pausedIncubate = true;
    }

    function unpauseIncubate() public onlyOwner whenPausedIncubate {
        pausedIncubate = false;
    }

}

// File: contracts\ITAMAG.sol

pragma solidity ^0.6.0;

interface ITAMAG {
    function hatch(address player, uint256 trait, string memory tokenURI) external returns (uint256);
}

// File: @openzeppelin\contracts\utils\Counters.sol



pragma solidity ^0.6.0;


/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// File: contracts\TMETraitSource.sol

pragma solidity ^0.6.0;




contract TMETraitSource is Ownable{
    // using SafeMath for uint256;
    // using SafeMath for uint16;
    using Counters for Counters.Counter;

    struct TraitInfo {
        string name;
        uint8 bitWidth;
        uint8 offset;
        bool active;
    }

    TraitInfo[] public traits;
    Counters.Counter private numTraits;

    event TraitChange(string name, uint8 bitWidth, uint8 offset, bool active);
    event TraitAdded(string name, uint8 bitWidth, uint8 offset, bool active);
    event TraitActivate(uint256 index);
    event TraitDeactivate(uint256 index);

    function getNumTraits() public view returns (uint256){
        return numTraits.current();
    }
    
    // function getTraitAtIndex(uint256 index) public view returns (string memory name, uint8 bitWidth, uint8 offset, bool active){
    //     require(index < numTraits.current(), "invalid index");
    //     return (traits[index].name,
    //         traits[index].bitWidth,
    //         traits[index].offset,
    //         traits[index].active
    //     );
    // }
    function setTrait(uint256 index, string memory name, uint8 bitWidth, uint8 offset, bool active) public onlyOwner {
        require(index < numTraits.current(), "invalid index");
        traits[index].name = name;
        traits[index].bitWidth = bitWidth;
        traits[index].offset = offset;
        traits[index].active = active;
        emit TraitChange(name, bitWidth, offset, active);

    }
    function addTrait(string memory name, uint8 bitWidth, uint8 offset, bool active) public onlyOwner {
        TraitInfo memory t = TraitInfo(name, bitWidth, offset, active);
        traits.push(t);
        numTraits.increment();
        emit TraitAdded(name, bitWidth, offset, active);
    }
    function deactivateTrait(uint256 index) public onlyOwner {
        require(index < numTraits.current(), "invalid index");
        traits[index].active = false;
        emit TraitDeactivate(index);
    }
    function activateTrait(uint256 index) public onlyOwner {
        require(index < numTraits.current(), "invalid index");
        traits[index].active = true;
        emit TraitActivate(index);
    }
    
}

// File: contracts\ITMETraitOracle.sol

pragma solidity >=0.6.0;

interface ITMETraitOracle {
    // function getRandomN(uint256 targetBlock, address owner, uint256 startTimestamp, uint256 hatchId) external view returns (uint256);
    function registerSeedForIncubation(uint256 targetBlock, address owner, uint256 startTimestamp, uint256 incubationId) external;
    function getRandomN(uint256 targetBlock, uint256 hatchId) external view returns (uint256);
    function getColorRandomN(uint256 targetBlock, uint256 hatchId) external view returns (uint256);
}

// File: contracts\TMEHatchery.sol

pragma solidity ^0.6.0;










// main staking contract
contract TMEHatchery is Ownable, ReentrancyGuard, TMEAccessControl, TMETraitSource{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address signerAddress;

    ITAMAG public tamag;
    IERC20 public tme;
    ITMETraitOracle public traitOracle;

    struct Incubation {
        uint256 id;
        uint256 startBlock;
        uint256 targetBlock;
        address owner;
        uint256 startTimestamp;
        uint256 endTimestamp;
        bool hatched;
        bool failed;
        uint256 traits;
    }

    Incubation[] public incubations;
    mapping(address => uint8) public ownerToNumIncubations;
    mapping(address => uint8) public ownerToNumActiveIncubations;
    mapping(address => uint256[]) public ownerToIds;
    uint256 public maxActiveIncubationsPerUser = 2;

    uint256 public inbucateDurationInSecs = 24 * 3600;
    uint256 public blocksTilColor = 2880; // 12h / 15secs per block
    uint256 public secsPerBlock = 15;

    uint8 public SUCCESS_BIT_WIDTH = 8;
    uint8 public SUCCESS_OFFSET = 0;
    // 5% of 256 = 12.8, round down to 12.
    // 0 - 11 -> hatching failed.
    // exact failure chance = 12/256 = 4.68 percent
    // 12 - 255 inclusive = success
    // 0-11 inclusive = fail
    uint8 public HATCH_THRESHOLD = 12;

    uint256 tmePerIncubate = 1 ether;
    uint256 tmeReturnOnFail = 0 ether;

    address public BURN_ADDRESS = address(1);

    event IncubationStarted(address owner, uint256 startTime, uint256 endTime);
    event FailedHatch(address indexed owner, uint256 hatchId);
    event SuccessfulHatch(address indexed owner, uint256 hatchId);

    constructor(address _tme, address _tamag, address _signerAddress) public {
        tme = IERC20(_tme);
        tamag = ITAMAG(_tamag);
        signerAddress = _signerAddress;

        addTrait("CHEERFULNESS",5,0,true);
        addTrait("ENERGY",5,5,true);
        addTrait("METABOLISM",5,10,true);

        pauseIncubate();
    }

   

    // always results in incubation of 1 egg.
    function startIncubate() public whenNotPausedIncubate nonReentrant{
        require (tme.balanceOf(msg.sender) >= tmePerIncubate, "Not enough TME");
        require (maxActiveIncubationsPerUser == 0 || ownerToNumActiveIncubations[msg.sender] < maxActiveIncubationsPerUser, "Max active incubations exceed");
        require (tme.transferFrom(address(msg.sender), address(this), tmePerIncubate), "Failed to transfer TME");
        uint256 newId = incubations.length;
        uint256 targetBlock = block.number + inbucateDurationInSecs.div(secsPerBlock) - 20; //buffer to make sure target block is earlier than end timestamp
        uint256 endTime = block.timestamp + inbucateDurationInSecs;
        Incubation memory incubation = Incubation(
            newId,
            block.number,
            targetBlock,
            msg.sender,
            block.timestamp,
            endTime,
            false,
            false,
            0
        );
        traitOracle.registerSeedForIncubation(targetBlock, msg.sender, block.timestamp, newId);

        incubations.push(incubation);
        ownerToNumIncubations[msg.sender] += 1;
        ownerToIds[msg.sender].push(newId);
        ownerToNumActiveIncubations[msg.sender] += 1;

        // require(incubations[newId].id == newId, "Sanity check for using id as arr index");

        emit IncubationStarted(msg.sender, block.timestamp, endTime);
    }

    function getTotalIncubations() public view returns (uint256){
        return incubations.length;
    }
    
    function getColorBlockHash(uint256 id) public view returns (uint256) {
        require (id < incubations.length, "invalid id");

        Incubation memory toHatch = incubations[id];
        require (toHatch.startBlock + blocksTilColor < block.number, "wait more blocks");
        uint256 randomN = traitOracle.getColorRandomN(toHatch.startBlock + blocksTilColor, toHatch.id);
        
        return randomN;
    }
    // called by backend to find out hatch result
    function getResultOfIncubation(uint256 id) public view returns (bool, uint256){
        require (id < incubations.length, "invalid id");

        Incubation memory toHatch = incubations[id];
        require (toHatch.targetBlock < block.number, "not reached block");
        uint256 randomN = traitOracle.getRandomN(toHatch.targetBlock, toHatch.id);
        bool success = (_sliceNumber(randomN, SUCCESS_BIT_WIDTH, SUCCESS_OFFSET) >= HATCH_THRESHOLD);
        uint256 randomN2 = uint256(keccak256(abi.encodePacked(randomN)));
        uint256 traits = getTraitsFromRandom(randomN2);

        return (success, traits);
    }

    function getSuccessIncubation(uint256 id) public view returns (bool, uint256){
        require (id < incubations.length, "invalid id");

        Incubation memory toHatch = incubations[id];
        require (toHatch.targetBlock < block.number, "not reached block");
        uint256 randomN = traitOracle.getRandomN(toHatch.targetBlock, toHatch.id);
        bool success = (_sliceNumber(randomN, SUCCESS_BIT_WIDTH, SUCCESS_OFFSET) >= HATCH_THRESHOLD);

        return (success, randomN);
    }
    // a separate backend function running on the cloud prepares the tamag metadata, uploads on ipfs, and gives the tokenURI
    // authenticity of tokenURI is ensure with the v,r,s produced from the backend function
    function hatchAndClaim(uint256 id, string memory tokenURI, uint8 v, bytes32 r, bytes32 s) public whenNotPausedHatch nonReentrant{

        // make a hash = sha(id,tokenURI)
        // make sure hash is the content in the v,r,s signature.
        require (id < incubations.length, "invalid id");
        Incubation memory toHatch = incubations[id];
        require (toHatch.owner == msg.sender, "Only owner can call hatch");
        require (!toHatch.hatched, "Baby already hatched");
        require (toHatch.endTimestamp < block.timestamp, "Not time");

        (bool success, uint256 randomN) = getSuccessIncubation(toHatch.id);
        toHatch.hatched = true;

        if (ownerToNumActiveIncubations[toHatch.owner] > 0){
            ownerToNumActiveIncubations[toHatch.owner] -= 1;
        } 

        if (!success){
            toHatch.failed = true;
            // sanity check that frontend got same success result;
            // require (v==0 && r==0 && s==0, "Sanity check failed");
            emit FailedHatch(toHatch.owner, toHatch.id);
            incubations[id] = toHatch;
            if (tmeReturnOnFail > 0){
                tme.safeTransfer(toHatch.owner, tmeReturnOnFail);
            }
            tme.safeTransfer(BURN_ADDRESS, tmePerIncubate.sub(tmeReturnOnFail));

        } else {
            toHatch.failed = false;
            emit SuccessfulHatch(toHatch.owner, toHatch.id);
            tme.safeTransfer(BURN_ADDRESS, tmePerIncubate);

            uint256 randomN2 = uint256(keccak256(abi.encodePacked(randomN)));
            uint256 traits = getTraitsFromRandom(randomN2);
            toHatch.traits = traits;

            bytes32 hashInSignature = prefixed(keccak256(abi.encodePacked(toHatch.id,tokenURI)));
            address signer = ecrecover(hashInSignature, v, r, s);
            require(signer == signerAddress, "Msg needs to be signed by valid signer!");

            tamag.hatch(
                toHatch.owner,
                toHatch.traits,
                tokenURI
            );
            incubations[id] = toHatch;
        }

    }

    // assumes hash is always 32 bytes long as it is a keccak output
    function prefixed(bytes32 myHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", myHash));
    }

    function getTraitsFromRandom(uint256 randomN) public view returns (uint256) {
        // assumes traits are deconflicted in terms of positioning!
        uint256 mask = 0;
        for (uint16 i = 0; i < getNumTraits(); i++){
            mask |= uint256((2**uint256(traits[i].bitWidth)) - 1) << traits[i].offset;
        }
        return randomN & mask;
    }

    /// @dev given a number get a slice of any bits, at certain offset
    /// @param _n a number to be sliced
    /// @param _nbits how many bits long is the new number
    /// @param _offset how many bits to skip
    function _sliceNumber(uint256 _n, uint8 _nbits, uint8 _offset) private pure returns (uint8) {
        // mask is made by shifting left an offset number of times
        uint256 mask = uint256((2**uint256(_nbits)) - 1) << _offset;
        // AND n with mask, and trim to max of _nbits bits
        return uint8((_n & mask) >> _offset);
    }

    /* setters */
    function setSignerAddress(address _signerAddress) public onlyOwner {
        signerAddress = _signerAddress;
    }

    function setTmePerIncubate(uint256 amt) public onlyOwner {
        tmePerIncubate = amt;
    }
    function setTmeReturnOnFail(uint256 amt) public onlyOwner {
        tmeReturnOnFail = amt;
    }

    function setIncubateDurationInSecs(uint256 secs) public onlyOwner{
        inbucateDurationInSecs = secs;
    }

    function setSecsPerBlock(uint256 secs) public onlyOwner{
        secsPerBlock = secs;
    }

    function setBlocksTilColor(uint256 num) public onlyOwner{
        blocksTilColor = num;
    }

    function setSuccessInfo(uint8 bitWidth, uint8 offset) public onlyOwner{
        SUCCESS_BIT_WIDTH = bitWidth;
        SUCCESS_OFFSET = offset;
    }

    function setHatchThreshold(uint8 threshold) public onlyOwner{
        HATCH_THRESHOLD = threshold;
    }
    
    function setTME(address _a) public onlyOwner {
        tme = IERC20(_a);
    }
    function setTAMAG(address _a) public onlyOwner {
        tamag = ITAMAG(_a);
    }
    function setTraitOracle(address _a) public onlyOwner {
        traitOracle = ITMETraitOracle(_a);
    }
    function setMaxActiveIncubationsPerUser(uint256 num) public onlyOwner {
        maxActiveIncubationsPerUser = num;
    }
    
    // emergency function so things don't get stuck inside contract
    function emergencyWithdrawEth() public onlyOwner {
        uint256 b = address(this).balance;
        address payable a = payable(owner());
        a.transfer(b);
    }
    function emergencyWithdrawTME() public onlyOwner {
        uint256 tokenBalance = tme.balanceOf(address(this));
        tme.safeTransfer(owner(), tokenBalance);
    }
    
}