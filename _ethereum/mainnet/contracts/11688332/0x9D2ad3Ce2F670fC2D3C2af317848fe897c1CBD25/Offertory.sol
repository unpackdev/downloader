// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
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
        return functionCallWithValue(target, data, 0, errorMessage);
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  function approve(address spender, uint256 value) external returns (bool success);
  function balanceOf(address owner) external view returns (uint256 balance);
  function decimals() external view returns (uint8 decimalPlaces);
  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
  function increaseApproval(address spender, uint256 subtractedValue) external;
  function name() external view returns (string memory tokenName);
  function symbol() external view returns (string memory tokenSymbol);
  function totalSupply() external view returns (uint256 totalTokensIssued);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

contract VRFRequestIDBase {

  function makeVRFInputSeed(bytes32 _keyHash, uint256 _userSeed,
    address _requester, uint256 _nonce)
    internal pure returns (uint256)
  {
    return  uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  function makeRequestId(
    bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

abstract contract VRFConsumerBase is VRFRequestIDBase {

  using SafeMath for uint256;
  
  function fulfillRandomness(bytes32 requestId, uint256 randomness)
    internal virtual;

  function requestRandomness(bytes32 _keyHash, uint256 _fee, uint256 _seed)
    internal returns (bytes32 requestId)
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, _seed));
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, _seed, address(this), nonces[_keyHash]);
    nonces[_keyHash] = nonces[_keyHash].add(1);
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;


  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  constructor(address _vrfCoordinator, address _link) public {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

contract RandomNumberConsumer is VRFConsumerBase {
    bytes32 internal keyHash;
    uint256 internal fee;
    
    uint256 private currentTarget = 0;
    uint256 private winner1 = 0;
    uint256 private winner2 = 0;
    uint256 private winner3 = 0;
    
    /**
     * Constructor inherits VRFConsumerBase
     * 
     * Network: Kovan
     * Chainlink VRF Coordinator address: 0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9
     * LINK token address:                0xa36085F69e2889c224210F603D836748e7dC0088
     * Key Hash: 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4
     */
    constructor() 
        VRFConsumerBase(
            0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, // VRF Coordinator
            0x514910771AF9Ca656af840dff83E8264EcF986CA  // LINK Token
        ) public
    {
        keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
        fee = 2 * 10 ** 18; // 2 LINK
    }
    
    /** 
     * Requests randomness from a user-provided seed
     */
    function getRandomNumber(uint256 userProvidedSeed) public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        currentTarget = userProvidedSeed;
        return requestRandomness(keyHash, fee, userProvidedSeed);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        requestId = 0;
        
        if(currentTarget == 1)
            winner1 = randomness;
        else if(currentTarget == 2)
            winner2 = randomness;
        else if(currentTarget == 3)
            winner3 = randomness;
    }
    
    function getWinners() external view returns (uint256, uint256, uint256) {
        return (winner1, winner2, winner3);
    }
    
    function getCurrentTarget() external view returns (uint256) {
        return currentTarget;
    }
 
    function initialize() external {
        currentTarget = 0;
        winner1 = 0;
        winner2 = 0;
        winner3 = 0;
    }
}

contract DateTime {
        /*
         *  Date and Time utilities for ethereum contracts
         *
         */
        struct _DateTime {
                uint16 year;
                uint8 month;
                uint8 day;
        }

        uint constant DAY_IN_SECONDS = 86400;
        uint constant YEAR_IN_SECONDS = 31536000;
        uint constant LEAP_YEAR_IN_SECONDS = 31622400;

        uint constant HOUR_IN_SECONDS = 3600;
        uint constant MINUTE_IN_SECONDS = 60;

        uint16 constant ORIGIN_YEAR = 1970;

        function isLeapYear(uint16 year) public pure returns (bool) {
                if (year % 4 != 0) {
                        return false;
                }
                if (year % 100 != 0) {
                        return true;
                }
                if (year % 400 != 0) {
                        return false;
                }
                return true;
        }

        function leapYearsBefore(uint year) public pure returns (uint) {
                year -= 1;
                return year / 4 - year / 100 + year / 400;
        }

        function getDaysInMonth(uint8 month, uint16 year) public pure returns (uint8) {
                if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
                        return 31;
                }
                else if (month == 4 || month == 6 || month == 9 || month == 11) {
                        return 30;
                }
                else if (isLeapYear(year)) {
                        return 29;
                }
                else {
                        return 28;
                }
        }

        function parseTimestamp(uint timestamp) public pure returns (_DateTime memory dt) {
                uint secondsAccountedFor = 0;
                uint buf;
                uint8 i;

                // Year
                dt.year = getYear(timestamp);
                buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

                secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
                secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

                // Month
                uint secondsInMonth;
                for (i = 1; i <= 12; i++) {
                        secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
                        if (secondsInMonth + secondsAccountedFor > timestamp) {
                                dt.month = i;
                                break;
                        }
                        secondsAccountedFor += secondsInMonth;
                }

                // Day
                for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
                        if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                                dt.day = i;
                                break;
                        }
                        secondsAccountedFor += DAY_IN_SECONDS;
                }
        }

        function getYear(uint timestamp) public pure returns (uint16) {
                uint secondsAccountedFor = 0;
                uint16 year;
                uint numLeapYears;

                // Year
                year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
                numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

                secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
                secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

                while (secondsAccountedFor > timestamp) {
                        if (isLeapYear(uint16(year - 1))) {
                                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
                        }
                        else {
                                secondsAccountedFor -= YEAR_IN_SECONDS;
                        }
                        year -= 1;
                }
                return year;
        }
}

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);
    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline) external payable returns (uint[] memory amounts);
    function getAmountsIn(
        uint amountOut,
        address[] memory path) external view returns (uint[] memory amounts);
}

abstract contract ContractGuard {
    using Address for address;

    modifier noContract(address account) {
        require(Address.isContract(account) == false, "Contracts are not allowed to interact with the Offertory");
        _;
    }
}

contract Offertory is Ownable, ReentrancyGuard, ContractGuard {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;

    RandomNumberConsumer public rnGenerator = new RandomNumberConsumer();
    DateTime dTime = new DateTime();
    
    IUniswapV2Router02 public immutable uniswapV2Router;
    address private immutable prophetContract;
    address[] private uniswapPairPath;
    
    address private dealerWallet;
    uint256 private minDealerDepositAmount = 100e9;
    uint256 private dealerDepositAmount;
    
    bool private gameInProgress;

    uint256 private lotteryStartTime;
    uint256 private lotteryEndTime;
    
    uint256 private ticketPrice = 100e9;
    uint256 private minPlayerCount = 10;
    uint256 private maxBuyableTicketCountInDay = 2;
    
    uint256 private winnerPrizePct1 = 60;
    uint256 private winnerPrizePct2 = 25;
    uint256 private winnerPrizePct3 = 15;
    
    uint256 private refundPct = 90;
    uint256 private announceFee = 10e9;
    uint256 private totalAmountToRefund;
    
    address private winner1Address;
    address private winner2Address;
    address private winner3Address;
    
    uint256 private prizeAmountAtAnnounce;
    
    uint256 private winnerMode = 1;
    
    mapping (address => uint256) private playerBalance;      // map for players balance
    address[] private players;
    TICKET_INFO[] private tickets;
    
    bool newGameStart;
    
    struct TICKET_INFO {
        address player;
        DateTime._DateTime date;
    }

    // Events
    event DealerWalletUpdated(address indexed dealerWallet);
    event MinDealerDepositAmountUpdated(uint256 minDealerDepositAmount);
    event LotteryStartTimeUpdated(uint256 lotteryStartTime);
    event LotteryEndTimeUpdated(uint256 lotteryEndTime);
    event WinnerPrizeUpdated(uint256 winnerPrizePct1, uint256 winnerPrizePct2, uint256 winnerPrizePct3);
    event TicketPriceUpdated(uint256 ticketPrice);
    event MinPlayerCountUpdated(uint256 minPlayerCount);
    event RefundPctUpdated(uint256 refundPct);
    event BoughtTicket(address indexed player, uint256 amount);
    event Claimed(address indexed player, uint256 amount);
    event PlayerGaveup(address indexed player, uint256 amount);
    event DealerDeposited(address indexed dealerWallet, uint256 amount);
    event AnnounceFeeUpdated(uint256 announceFee);
    event AnnouncedWinners(address indexed winner1, address indexed winner2, address indexed winner3);
    event MaxBuyableTicketCountInDayUpdated(uint256 maxBuyableTicketCountInDay);
    event WinnerModeUpdated(uint256 winnerMode);
    
    constructor (
                IUniswapV2Router02 _uniswapV2Router,
                address _prophetContract,
                address _dealerWallet,
                uint256 _ticketPrice,
                uint256 _minPlayerCount,
                uint256 _winnerPrizePct1,
                uint256 _winnerPrizePct2,
                uint256 _winnerPrizePct3,
                uint256 _refundPct,
                uint256 _announceFee) public {
                     
        uniswapV2Router = _uniswapV2Router;
        prophetContract = _prophetContract;
        
        uniswapPairPath = new address[](2);
        uniswapPairPath[0] = _uniswapV2Router.WETH();
        uniswapPairPath[1] = _prophetContract;
        
	setDealerWallet(_dealerWallet);
        setTicketPrice(_ticketPrice);
        setMinPlayerCount(_minPlayerCount);
        setWinnerPrizePct(_winnerPrizePct1, _winnerPrizePct2, _winnerPrizePct3);
        setRefundPct(_refundPct);
        setAnnounceFee(_announceFee);
    }
    
    function setDealerWallet(address _dealerWallet) public onlyOwner() nonReentrant noContract(msg.sender) {
        require(_dealerWallet != address(0), 'Prophet Lottery: dealerWallet is zero.');
        dealerWallet = _dealerWallet;
        emit DealerWalletUpdated(_dealerWallet);
    }

    function setMinDealerDepositAmount(uint256 _minDealerDepositAmount) public onlyOwner() nonReentrant noContract(msg.sender) {
        require(_minDealerDepositAmount >= 100e9, 'Prophet Lottery: minDealerDepositAmount is less than 100e9.');
        minDealerDepositAmount = _minDealerDepositAmount;
        emit MinDealerDepositAmountUpdated(_minDealerDepositAmount);
    }
    
    function setLotteryStartTime(uint256 _lotteryStartTime) public onlyOwner() nonReentrant noContract(msg.sender) {
        require(_lotteryStartTime >= now, 'Prophet Lottery: lotteryStartTime is ahead of now.');
        require(players.length == 0 || (!gameInProgress && now > lotteryEndTime + 3 days), 'Prophet Lottery: we can not start new game now.');
        lotteryStartTime = _lotteryStartTime;
        newGameStart = true;
        gameInProgress = false;
        emit LotteryStartTimeUpdated(_lotteryStartTime);
    }
    
    function setWinnerMode(uint256 _winnerMode) public onlyOwner() nonReentrant noContract(msg.sender) {
        require(_winnerMode == 1 || _winnerMode == 3, 'Prophet Lottery: winnerMode should be 1 or 3.');
        winnerMode = _winnerMode;
        emit WinnerModeUpdated(_winnerMode);
    }
    
    function setLotteryEndTime(uint256 _lotteryEndTime) public onlyOwner() nonReentrant noContract(msg.sender) {
        require(newGameStart , 'Prophet Lottery: game is not started yet.');
        require(_lotteryEndTime >= lotteryStartTime + 2 days && _lotteryEndTime <= lotteryStartTime + 30 days, 'Prophet Lottery: lotteryEndTime should be in 2 ~ 30 days since start.');
        require(_lotteryEndTime >= now, 'Prophet Lottery: lotteryEndTime is ahead of now.');
        lotteryEndTime = _lotteryEndTime;
        winner1Address = address(0);
        winner2Address = address(0);
        winner3Address = address(0);
        prizeAmountAtAnnounce = 0;
        dealerDepositAmount = 0;
        totalAmountToRefund = 0;
        rnGenerator.initialize();
        
        for(uint i=players.length; i>0; i--) {
            playerBalance[players[i-1]] = 0;
            players.pop();
        }
        
        for(uint i=tickets.length; i>0; i--) {
            tickets.pop();
        }
        
        gameInProgress = true;
        emit LotteryEndTimeUpdated(_lotteryEndTime);
    }
    
    function setWinnerPrizePct(uint256 _winnerPrizePct1, uint256 _winnerPrizePct2, uint256 _winnerPrizePct3) public onlyOwner() nonReentrant {
        require(_winnerPrizePct1.add(_winnerPrizePct2).add(_winnerPrizePct3) == 100, 'Prophet Lottery: sum of winner prize percentages is not 100.');
        require(_winnerPrizePct1 >= _winnerPrizePct2 && _winnerPrizePct2 >= _winnerPrizePct3, 'Prophet Lottery: winner prize percentages should be set properly by order.');
        winnerPrizePct1 = _winnerPrizePct1;
        winnerPrizePct2 = _winnerPrizePct2;
        winnerPrizePct3 = _winnerPrizePct3;
        emit WinnerPrizeUpdated(_winnerPrizePct1, _winnerPrizePct2, _winnerPrizePct3);
    }
    
    function setMinPlayerCount(uint256 _minPlayerCount) public onlyOwner() nonReentrant {
        require(_minPlayerCount >= 10, 'Prophet Lottery: minPlayerCount is less than 10.');
        minPlayerCount = _minPlayerCount;
        emit MinPlayerCountUpdated(_minPlayerCount);
    }
    
    function setAnnounceFee(uint256 _announceFee) public onlyOwner() nonReentrant {
        require(_announceFee >= 10e9 && _announceFee <= 100e9, 'Prophet Lottery: announceFee should be in 10e9 ~ 100e9.');
        announceFee = _announceFee;
        emit AnnounceFeeUpdated(_announceFee);
    }
    
    function setMaxBuyableTicketCountInDay(uint256 _maxBuyableTicketCountInDay) public onlyOwner() nonReentrant {
        require(_maxBuyableTicketCountInDay >= 1 && _maxBuyableTicketCountInDay <= 10, 'Prophet Lottery: maxBuyableTicketCountInDay should be in 1 ~ 10.');
        maxBuyableTicketCountInDay = _maxBuyableTicketCountInDay;
        emit MaxBuyableTicketCountInDayUpdated(_maxBuyableTicketCountInDay);
    }
    
    function setTicketPrice(uint256 _ticketPrice) private {
        require(_ticketPrice >= 100e9, 'Prophet Lottery: ticketPrice is less than 100e9.');
        ticketPrice = _ticketPrice;
        emit TicketPriceUpdated(_ticketPrice);
    }
    
    function setRefundPct(uint256 _refundPct) private {
        require(players.length == 0, 'Prophet Lottery: game is in progress now.');
        require(_refundPct >= 33 && _refundPct <= 97, 'Prophet Lottery: refundPct should be in 33 ~ 97.');
        refundPct = _refundPct;
        emit RefundPctUpdated(_refundPct);
    }

    function getTicketCountInSameDate(address player, DateTime._DateTime memory dt) private view returns (uint256) {
        uint256 ticketCountInSameDate = 0;
        
        for(uint i=0; i<tickets.length; i++) {
            if(tickets[i].player == player && 
                tickets[i].date.year == dt.year &&
                tickets[i].date.month == dt.month &&
                tickets[i].date.day == dt.day) {
                ticketCountInSameDate++;
            }
        }
        
        return ticketCountInSameDate;
    }
    
    receive() external payable {}
    
    function buyTicket() external payable nonReentrant noContract(msg.sender) {
        require(
            gameInProgress,
            "Prophet Lottery: game is not started yet."
        );
        
        uint256 currentTarget = rnGenerator.getCurrentTarget();
        require(
            currentTarget == 0,
            "Prophet Lottery: it is too late to buy ticket now."
        );
        
        DateTime._DateTime memory dt = dTime.parseTimestamp(now);
        require(
            getTicketCountInSameDate(_msgSender(), dt) < maxBuyableTicketCountInDay,
            "Prophet Lottery: you already bought max tickets today."
        );
        
        TICKET_INFO memory ticket;
        ticket.player = _msgSender();
        ticket.date = dt;
        tickets.push(ticket);

        uniswapV2Router
            .swapETHForExactTokens{value: msg.value}(
                ticketPrice,
                uniswapPairPath,
                address(this),
                block.timestamp + 15
            );

        (bool success,) = _msgSender().call{ value: address(this).balance }("");
        require(success, "refund failed");
        
        if(playerBalance[_msgSender()] == 0)
            players.push(_msgSender());

        playerBalance[_msgSender()] = playerBalance[_msgSender()].add(ticketPrice.mul(refundPct).div(100));
        
        totalAmountToRefund = totalAmountToRefund.add(ticketPrice.mul(refundPct).div(100));
        
        BoughtTicket(_msgSender(), ticketPrice);
    }
    
    function claim() external nonReentrant noContract(msg.sender) {
        require(
            !gameInProgress,
            "Prophet Lottery: game is in progress now."
        );
        
        require(
            playerBalance[_msgSender()] > 0,
            "Prophet Lottery: your balance is 0."
        );
        
        uint256 returnAmount = playerBalance[_msgSender()];
        removePlayerFromList();
        
        require(
            IERC20(prophetContract).transfer(
                _msgSender(),
                returnAmount
            ),
            "Prophet Lottery: exit failed."
        );
        
        Claimed(_msgSender(), playerBalance[_msgSender()]);
    }
    
    function removePlayerFromList() private {
        playerBalance[_msgSender()] = 0;
        
        for(uint i=0; i<players.length; i++) {
            if(players[i] == _msgSender()) {
                players[i] = players[players.length-1];
                players.pop();
                break;
            }
        }
    }
    
    function dealerDeposit(uint256 amount) external nonReentrant noContract(msg.sender) {
        require(
            _msgSender() == dealerWallet,
            "Prophet Lottery: only dealer wallet can deposit."
        );
        
        require(
            dealerDepositAmount.add(amount) >= minDealerDepositAmount,
            "Prophet Lottery: dealerDepositAmount is less than minDealerDepositAmount."
        );
        
        require(
            IERC20(prophetContract).transferFrom(
                _msgSender(),
                address(this),
                amount
            ),
            "Prophet Lottery: dealer deposit failed."
        );

        dealerDepositAmount = dealerDepositAmount.add(amount);
        
        DealerDeposited(_msgSender(), amount);
    }

    function pickWinner1() external nonReentrant noContract(msg.sender) {
        require(
            gameInProgress &&
            now >= lotteryEndTime,
            "Prophet Lottery: it is not a time to pick winner."
        );
        
        require(
            dealerDepositAmount >= minDealerDepositAmount,
            "Prophet Lottery: dealerDepositAmount is less than minDealerDepositAmount."
        );
        
        require(
            players.length >= minPlayerCount,
            "Prophet Lottery: player count is less than minPlayerCount."
        );
        
        uint256 currentTarget = rnGenerator.getCurrentTarget();
        require(currentTarget == 0, "Prophet Lottery: we can't pick winner1 now.");
        rnGenerator.getRandomNumber(1);
    }
    
    function pickWinner2() external nonReentrant noContract(msg.sender) {
        uint256 currentTarget = rnGenerator.getCurrentTarget();
        (uint256 winner1,,) = rnGenerator.getWinners();
        require(currentTarget == 1 && winner1 != 0, "Prophet Lottery: we can't pick winner2 now.");
        rnGenerator.getRandomNumber(2);
    }
    
    function pickWinner3() external nonReentrant noContract(msg.sender) {
        uint256 currentTarget = rnGenerator.getCurrentTarget();
        (,uint256 winner2,) = rnGenerator.getWinners();
        require(currentTarget == 2 && winner2 != 0, "Prophet Lottery: we can't pick winner3 now.");
        rnGenerator.getRandomNumber(3);
    }
    
    function announceWinners() external nonReentrant noContract(msg.sender) {
        uint256 ticketCount = tickets.length;
        uint256 playerCount = players.length;

        require(
            gameInProgress &&
            now >= lotteryEndTime,
            "Prophet Lottery: it is not a time to announce winner."
        );
        
        require(
            dealerDepositAmount >= minDealerDepositAmount,
            "Prophet Lottery: dealerDepositAmount is less than minDealerDepositAmount."
        );
        
        if(playerCount >= minPlayerCount) {
            (uint256 winner1, uint256 winner2, uint256 winner3) = rnGenerator.getWinners();
            if(winnerMode == 1)
                require(
                    winner1 != 0,
                    "Prophet Lottery: Not picked all wineres yet."
                );
            else
                require(
                    winner1 != 0 &&
                    winner2 != 0 &&
                    winner3 != 0,
                    "Prophet Lottery: Not picked all wineres yet."
                );
        
            prizeAmountAtAnnounce = IERC20(prophetContract).balanceOf(address(this)).sub(totalAmountToRefund).sub(announceFee);
            uint256 winnerPrize1 = prizeAmountAtAnnounce.mul(winnerPrizePct1).div(100);
            uint256 winnerPrize2 = prizeAmountAtAnnounce.mul(winnerPrizePct2).div(100);
            uint256 winnerPrize3 = prizeAmountAtAnnounce.sub(winnerPrize1).sub(winnerPrize2);
            
            
            TICKET_INFO[] memory ticketList = tickets;
            
            winner1 = winner1.mod(playerCount);
            winner1Address = ticketList[winner1].player;
            playerBalance[winner1Address] = playerBalance[winner1Address].add(winnerPrize1);
            
            
            ticketList[winner1] = ticketList[ticketCount - 1];
            ticketCount--;
            
            winner2 = winner2.mod(playerCount);
            winner2Address = ticketList[winner2].player;
            playerBalance[winner2Address] = playerBalance[winner2Address].add(winnerPrize2);
            
            
            ticketList[winner2] = ticketList[ticketCount - 1];
            ticketCount--;
            
            winner3 = winner3.mod(playerCount);
            winner3Address = ticketList[winner3].player;
            playerBalance[winner3Address] = playerBalance[winner3Address].add(winnerPrize3);
            
            require(
                IERC20(prophetContract).transfer(
                    _msgSender(),
                    announceFee
                ),
                "Prophet Lottery: announceFee transfer failed."
            );
            
            newGameStart = false;
            gameInProgress = false;
            
            AnnouncedWinners(winner1Address, winner2Address, winner3Address);
        } else {
            if(dealerDepositAmount > 0) {
                IERC20(prophetContract).transfer(
                    dealerWallet,
                    dealerDepositAmount.mul(refundPct)
                );
            }
            
            if(IERC20(prophetContract).balanceOf(address(this)).sub(totalAmountToRefund) >= announceFee) {
                IERC20(prophetContract).transfer(
                    _msgSender(),
                    announceFee
                );
            }
            
            dealerDepositAmount = 0;
            
            newGameStart = false;
            gameInProgress = false;
        }
    }
    
    function getBalance(address player) external view returns (uint256) {
        return playerBalance[player];
    }
    
    function getPlayerCount() external view returns (uint256) {
        return players.length;
    }
    
    function getPlayers() external view returns (address [] memory) {
        return players;
    }

    function getEstimatedETHforTicket() external view returns (uint[] memory) {
        return uniswapV2Router.getAmountsIn(ticketPrice, uniswapPairPath);
    }
    
    function getTicketCountOfToday(address player) external view returns (uint256) {
        DateTime._DateTime memory dt = dTime.parseTimestamp(now);
        return getTicketCountInSameDate(player, dt);
    }
    
    function getTicketCountOfPlayer(address player) external view returns (uint256) {
        uint256 ticketCountOfPlayer = 0;
        
        for(uint i=0; i<tickets.length; i++) {
            if(tickets[i].player == player) {
                ticketCountOfPlayer++;
            }
        }
        
        return ticketCountOfPlayer;
    }
    
    function getTicketCount() external view returns (uint256) {
        return tickets.length;
    }
    
    function getWinner1() external view returns (address) {
        return winner1Address;
    }
    
    function getWinner2() external view returns (address) {
        return winner2Address;
    }
    
    function getWinner3() external view returns (address) {
        return winner3Address;
    }
    
    function getWinners() external view returns (uint256, uint256, uint256) {
        return rnGenerator.getWinners();
    }
    
    function getCurrentTarget() external view returns (uint256) {
        return rnGenerator.getCurrentTarget();
    }
    
    function getDealerDepositAmount() external view returns (uint256) {
        return dealerDepositAmount;
    }
    
    function getLotteryStartTime() external view returns (uint256) {
        return lotteryStartTime;
    }
    
    function getLotteryEndTime() external view returns (uint256) {
        return lotteryEndTime;
    }
    
    function getTicketPrice() external view returns (uint256) {
        return ticketPrice;
    }
    
    function getMinPlayerCount() external view returns (uint256) {
        return minPlayerCount;
    }
    
    function getWinnerPrizePct1() external view returns (uint256) {
        return winnerPrizePct1;
    }
    
    function getWinnerPrizePct2() external view returns (uint256) {
        return winnerPrizePct2;
    }
    
    function getWinnerPrizePct3() external view returns (uint256) {
        return winnerPrizePct3;
    }
    
    function getRefundPct() external view returns (uint256) {
        return refundPct;
    }
    
    function getAnnounceFee() external view returns (uint256) {
        return announceFee;
    }
    
    function getGameInProgress() external view returns (bool) {
        return gameInProgress;
    }
    
    function getDealerWallet() external view returns (address) {
        return dealerWallet;
    }
    
    function getMinDealerDepositAmount() external view returns (uint256) {
        return minDealerDepositAmount;
    }
    
    function getWinnerMode() external view returns(uint256) {
        return winnerMode;
    }
    
    function getTotalPrizeAmount() external view returns (uint256) {
        if(IERC20(prophetContract).balanceOf(address(this)).sub(totalAmountToRefund) >= announceFee)
            return IERC20(prophetContract).balanceOf(address(this)).sub(totalAmountToRefund).sub(announceFee);
        return 0;
    }
    
    function getTotalPrizeAmountAtAnnounce() external view returns (uint256) {
        return prizeAmountAtAnnounce;
    }
    
    function getMaxBuyableTicketCountInDay() external view returns (uint256) {
        return maxBuyableTicketCountInDay;
    }
}