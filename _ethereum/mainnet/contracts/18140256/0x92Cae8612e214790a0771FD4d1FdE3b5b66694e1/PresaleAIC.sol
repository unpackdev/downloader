// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

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

// File @openzeppelin/contracts/access/Ownable.sol@v4.7.2

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

// File @openzeppelin/contracts/token/ERC20/IERC20.sol@v4.7.2

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File @openzeppelin/contracts/utils/math/SafeMath.sol@v4.7.2

// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

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
    function tryAdd(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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
    function trySub(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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
    function tryMul(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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
    function tryDiv(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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
    function tryMod(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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

// File contracts/interfaces/ICrowdsale.sol

pragma solidity ^0.8.0;

// Import this file to use console.log

interface ICrowdsale {
    // Amount in CAI
    event TokenSold(address indexed beneficiary, uint256 indexed amount);
    event TokenTransferred(address indexed receiver, uint256 indexed amount);

    // Price (USDT) per  CAI
    function price() external view returns (uint256);

    // Max. amount in USDT
    function maxAmountUsd() external view returns (uint256);

    // Max. amount in ETH
    function maxAmountETH() external view returns (uint256);

    // The beneficiary vesting wallet address
    function vestingWallet(address) external view returns (address);

    function startTimestamp() external view returns (uint256);

    function endTimestamp() external view returns (uint256);

    function soldToken() external view returns (uint256);

    function setPrice(uint256) external;

    function usdtAddress() external view returns (address);

    function caiAddress() external view returns (address);

    function RouterAddress() external view returns (address);

    function vestingManagerAddress() external view returns (address);

    function setStartTimestamp(uint256) external;

    function setRound(uint8) external;

    function setEndTimestamp(uint256) external;

    function setMaxAmountUsd(uint256) external;

    function setMaxAmountETH(uint256) external;

    function buyTokenETH() external payable;

    function buyTokenUSDT(uint256) external;

    function withdrawToken(address) external;

    function transferTokenOwnership(address) external;
}

// File @openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol@v4.7.2

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

interface IERC20_USDT {
    function transferFrom(address from, address to, uint value) external;
}

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// File @openzeppelin/contracts/utils/Address.sol@v4.7.2

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data
    ) internal view returns (bytes memory) {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
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

// File @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol@v4.7.2

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

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
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(
            nonceAfter == nonceBefore + 1,
            "SafeERC20: permit did not succeed"
        );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// File @openzeppelin/contracts/utils/math/Math.sol@v4.7.2

// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(
        uint256 a,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// File contracts/interfaces/IVestingManager.sol

pragma solidity ^0.8.0;

// Import this file to use console.log

interface IVestingManager {
    function startTimestamp() external view returns (uint256);

    function durationSAFT() external view returns (uint256);

    function durationOne() external view returns (uint256);

    function durationTwo() external view returns (uint256);

    function durationThree() external view returns (uint256);

    function durationFour() external view returns (uint256);

    function durationFive() external view returns (uint256);

    function durationSix() external view returns (uint256);

    function cliffoffSAFT() external view returns (uint256);

    function cliffoffOne() external view returns (uint256);

    function cliffoffTwo() external view returns (uint256);

    function tgeThree() external view returns (uint256);

    function tgeFour() external view returns (uint256);

    function tgeFive() external view returns (uint256);

    function tgeSix() external view returns (uint256);

    function setStartTimestamp(uint256) external;

    function setDurationSAFT(uint256) external;

    function setDurationOne(uint256) external;

    function setDurationTwo(uint256) external;

    function setDurationThree(uint256) external;

    function setDurationFour(uint256) external;

    function setDurationFive(uint256) external;

    function setDurationSix(uint256) external;

    function setCliffoffSAFT(uint256) external;

    function setCliffoffOne(uint256) external;

    function setCliffoffTwo(uint256) external;

    function setTgeThree(uint256) external;

    function setTgeFour(uint256) external;

    function setTgeFive(uint256) external;

    function setTgeSix(uint256) external;
}

// File contracts/VestingWallet.sol

// OpenZeppelin Contracts (last updated v4.7.0) (finance/VestingWallet.sol)

pragma solidity ^0.8.0;

// Import this file to use console.log

/**
 * @title VestingWallet
 * @dev This contract handles the vesting of Eth and ERC20 tokens for a given beneficiary. Custody of multiple tokens
 * can be given to this contract, which will release the token to the beneficiary following a given vesting schedule.
 * The vesting schedule is customizable through the {vestedAmount} function.
 *
 * Any token transferred to this contract will follow the vesting schedule as if they were locked from the beginning.
 * Consequently, if the vesting has already started, any amount of tokens sent to this contract will (at least partly)
 * be immediately releasable.
 */
contract VestingWallet is Context {
    using SafeMath for uint256;
    event EtherReleased(uint256 amount);
    event ERC20Released(address indexed token, uint256 amount);

    uint256 private _released;
    mapping(address => uint256) public _erc20Released;
    mapping(address => uint256) public _erc20Initial;
    mapping(address => bool) private _initial;
    address private immutable _beneficiary;

    uint8 private immutable _round;

    address private immutable _vestingManagerAddress;

    /**
     * @dev Set the beneficiary, start timestamp and vesting duration of the vesting wallet.
     */
    constructor(
        address beneficiaryAddress,
        address vestingManagerAddress,
        uint8 roundn
    ) {
        require(
            beneficiaryAddress != address(0),
            "VestingWallet: beneficiary is zero address"
        );
        _beneficiary = beneficiaryAddress;

        require(
            vestingManagerAddress != address(0),
            "VestingWallet: vesting manager is zero address"
        );
        _vestingManagerAddress = vestingManagerAddress;

        _round = roundn;
        _initial[address(this)] = false;
    }

    /**
     * @dev The contract should be able to receive Eth.
     */
    receive() external payable virtual {}

    /**
     * @dev Getter for the beneficiary address.
     */
    function beneficiary() public view virtual returns (address) {
        return _beneficiary;
    }

    /**
     * @dev Getter for the start timestamp.
     */
    function start() public view virtual returns (uint256) {
        return IVestingManager(_vestingManagerAddress).startTimestamp();
    }

    function round() public view virtual returns (uint256) {
        return _round;
    }

    /**
     * @dev Getter for the vesting duration.
     */
    function durationSAFT() public view virtual returns (uint256) {
        return IVestingManager(_vestingManagerAddress).durationSAFT();
    }

    function durationOne() public view virtual returns (uint256) {
        return IVestingManager(_vestingManagerAddress).durationOne();
    }

    function durationTwo() public view virtual returns (uint256) {
        return IVestingManager(_vestingManagerAddress).durationTwo();
    }

    function durationThree() public view virtual returns (uint256) {
        return IVestingManager(_vestingManagerAddress).durationThree();
    }

    function durationFour() public view virtual returns (uint256) {
        return IVestingManager(_vestingManagerAddress).durationFour();
    }

    function durationFive() public view virtual returns (uint256) {
        return IVestingManager(_vestingManagerAddress).durationFive();
    }

    function durationSix() public view virtual returns (uint256) {
        return IVestingManager(_vestingManagerAddress).durationSix();
    }

    function cliffoffSAFT() public view virtual returns (uint256) {
        return IVestingManager(_vestingManagerAddress).cliffoffSAFT();
    }

    function cliffoffOne() public view virtual returns (uint256) {
        return IVestingManager(_vestingManagerAddress).cliffoffOne();
    }

    function cliffoffTwo() public view virtual returns (uint256) {
        return IVestingManager(_vestingManagerAddress).cliffoffTwo();
    }

    function tgeThree() public view virtual returns (uint256) {
        return IVestingManager(_vestingManagerAddress).tgeThree();
    }

    function tgeFour() public view virtual returns (uint256) {
        return IVestingManager(_vestingManagerAddress).tgeFour();
    }

    function tgeFive() public view virtual returns (uint256) {
        return IVestingManager(_vestingManagerAddress).tgeFive();
    }

    function tgeSix() public view virtual returns (uint256) {
        return IVestingManager(_vestingManagerAddress).tgeSix();
    }

    /**
     * @dev Amount of token already released
     */
    function released() public view virtual returns (uint256) {
        address token = 0x4534b9De0a5CD0940a1f73B827b721eCb791DAe3;
        return _erc20Released[token];
    }

    /**
     * @dev Release the tokens that have already vested.
     *
     * Emits a {ERC20Released} event.
     */
    function release() public virtual {
        address token = 0x4534b9De0a5CD0940a1f73B827b721eCb791DAe3;

        uint256 releasable;

        require(block.timestamp > start(), "Vesting not started yet");

        releasable = vestedAmount(token, uint64(block.timestamp)) - released();

        if (_initial[address(this)] == true) {
            _erc20Released[token] += releasable;
        } else {
            _erc20Initial[token] += releasable;
        }

        emit ERC20Released(token, releasable);
        SafeERC20.safeTransfer(IERC20(token), beneficiary(), releasable);
        _initial[address(this)] = true;
    }

    /**
     * @dev Calculates the amount of tokens that has already vested. Default implementation is a linear vesting curve.
     */
    function vestedAmount(
        address token,
        uint64 timestamp
    ) public view virtual returns (uint256) {
        return
            _vestingSchedule(
                IERC20(token).balanceOf(address(this)) + released(),
                timestamp
            );
    }

    /**
     * @dev Virtual implementation of the vesting formula. This returns the amount vested, as a function of time, for
     * an asset given its total historical allocation.
     */
    function _vestingSchedule(
        uint256 totalAllocation,
        uint64 timestamp
    ) internal view virtual returns (uint256) {
        if (timestamp < start()) {
            return 0;
        } else {
            uint init = 0;

            if (_round == 1) {
                require(
                    (start() + cliffoffOne()) < timestamp,
                    "You still have to wait, sorry."
                );

                if (timestamp > (start() + durationOne())) {
                    return totalAllocation;
                }

                return
                    (totalAllocation *
                        (timestamp - (start() + cliffoffOne()))) /
                    durationOne();
            } else if (_round == 2) {
                require(
                    (start() + cliffoffTwo()) < timestamp,
                    "You still have to wait, sorry."
                );

                if (timestamp > (start() + durationTwo())) {
                    return totalAllocation;
                }

                return
                    (totalAllocation *
                        (timestamp - (start() + cliffoffTwo()))) /
                    durationTwo();
            } else if (_round == 3) {
                if (_initial[address(this)] == false) {
                    init = ((totalAllocation / 100) * tgeThree()) / 100;
                    return
                        ((totalAllocation * (timestamp - start())) /
                            durationThree()) + init;
                }

                if (timestamp > (start() + durationThree())) {
                    return totalAllocation;
                }

                return
                    (totalAllocation * (timestamp - start())) / durationThree();
            } else if (_round == 4) {
                if (_initial[address(this)] == false) {
                    init = ((totalAllocation / 100) * tgeFour()) / 100;
                    return
                        ((totalAllocation * (timestamp - start())) /
                            durationFour()) + init;
                }

                if (timestamp > (start() + durationFour())) {
                    return totalAllocation;
                }

                return
                    (totalAllocation * (timestamp - start())) / durationFour();
            } else if (_round == 5) {
                if (_initial[address(this)] == false) {
                    init = ((totalAllocation / 100) * tgeFive()) / 100;
                    return
                        ((totalAllocation * (timestamp - start())) /
                            durationFive()) + init;
                }

                if (timestamp > (start() + durationFive())) {
                    return totalAllocation;
                }

                return
                    (totalAllocation * (timestamp - start())) / durationFive();
            } else if (_round == 6) {
                if (_initial[address(this)] == false) {
                    init = ((totalAllocation / 100) * tgeSix()) / 100;
                    return
                        ((totalAllocation * (timestamp - start())) /
                            durationSix()) + init;
                }

                if (timestamp > (start() + durationSix())) {
                    return totalAllocation;
                }

                return
                    (totalAllocation * (timestamp - start())) / durationSix();
            } else if (_round == 0) {
                require(
                    (start() + cliffoffSAFT()) < timestamp,
                    "You still have to wait, sorry."
                );

                if (timestamp > (start() + durationSAFT())) {
                    return totalAllocation;
                }

                return
                    (totalAllocation *
                        (timestamp - (start() + cliffoffSAFT()))) /
                    durationSAFT();
            } else {
                return 0;
            }

            // return totalAllocation/100;
        }
    }
}

pragma solidity ^0.8.0;

contract PresaleAIC is ICrowdsale, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 private _price;
    uint256 private _maxAmountUsd;
    uint256 private _maxAmountETH;
    mapping(address => address) private _vestingWallets;
    mapping(address => uint8) private _bought;
    mapping(address => uint256) public whitelistSAFT;
    mapping(address => bool) public whitelistSEED;
    mapping(uint8 => uint256) public tokensCollected;
    AggregatorV3Interface internal priceFeed;

    uint256 private _startTimestamp;
    uint256 private _endTimestamp;
    uint256 public percent_dominator = 1000;

    uint256 private _soldToken;

    address private immutable _usdtAddress;
    uint8 public _round;
    address private immutable _caiAddress;
    address private immutable _RouterAddress;
    address private immutable _vestingManagerAddress;

    constructor(
        address addressUsdt,
        address addressCai,
        address addressRouter,
        address addressVestingManager
    ) {
        _price = 2000; // 0.02 USDT
        _maxAmountUsd = 15000 ether;
        _maxAmountETH = 100 ether;
        _usdtAddress = addressUsdt;
        _round = 1;
        _caiAddress = addressCai;
        _RouterAddress = addressRouter;
        _vestingManagerAddress = addressVestingManager;
        priceFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        );
    }

    function price() public view virtual override returns (uint256) {
        return _price;
    }

    function maxAmountUsd() public view virtual override returns (uint256) {
        return _maxAmountUsd;
    }

    function maxAmountETH() public view virtual override returns (uint256) {
        return _maxAmountETH;
    }

    function vestingWallet(
        address beneficiary
    ) public view virtual override returns (address) {
        return _vestingWallets[beneficiary];
    }

    function startTimestamp() public view virtual override returns (uint256) {
        return _startTimestamp;
    }

    function endTimestamp() public view virtual override returns (uint256) {
        return _endTimestamp;
    }

    function soldToken() public view virtual override returns (uint256) {
        return _soldToken;
    }

    function currentRound() public view virtual returns (uint8) {
        return _round;
    }

    function usdtAddress() public view virtual override returns (address) {
        return _usdtAddress;
    }

    function caiAddress() public view virtual override returns (address) {
        return _caiAddress;
    }

    function RouterAddress() public view virtual override returns (address) {
        return _RouterAddress;
    }

    function vestingManagerAddress()
        public
        view
        virtual
        override
        returns (address)
    {
        return _vestingManagerAddress;
    }

    function setWhitelistForSAFT(
        address _addr,
        uint256 amount
    ) external onlyOwner {
        whitelistSAFT[_addr] = amount;
    }

    function setWhitelistForSEED(address _addr) external onlyOwner {
        whitelistSEED[_addr] = true;
    }

    function setStartTimestamp(
        uint256 value
    ) public virtual override onlyOwner {
        require(
            value > block.timestamp,
            "Start timestamp must be in the future."
        );

        _startTimestamp = value;
    }

    function setEndTimestamp(uint256 value) public virtual override onlyOwner {
        require(
            value > block.timestamp,
            "End timestamp must be in the future."
        );

        _endTimestamp = value;
    }

    function setRound(uint8 value) public virtual override onlyOwner {
        require(value > 0, "Round must be greather than 1");

        _round = value;
    }

    function setMaxAmountUsd(uint256 value) public virtual override onlyOwner {
        _maxAmountUsd = value;
    }

    function setPrice(uint256 value) public virtual override onlyOwner {
        _price = value;
    }

    function setMaxAmountETH(uint256 value) public virtual override onlyOwner {
        _maxAmountETH = value;
    }

    function setPercentDominator(uint256 value) public onlyOwner {
        percent_dominator = value;
    }

    /**
     * Buying
     */
    function buyTokenETH() public payable virtual override {
        require(_round > 0, "ICO not started");
        _preValidate();
        _validateAmountETH();

        if (_round == 1) {
            require(
                whitelistSEED[msg.sender],
                "You are not whitelisted for the SEED Round"
            );
        }

        uint256 tokenAmount = (uint256(msg.value) * uint256(getLatestPrice())) /
            (price());

        uint256 amountCai = tokenAmount / percent_dominator;

        _execute(msg.sender, amountCai);
    }

    function SAFTClaim() public virtual {
        require(
            whitelistSAFT[msg.sender] > 0,
            "You are not in the SAFT Whitelist"
        );
        uint256 amountCai = whitelistSAFT[msg.sender];

        _execute(msg.sender, amountCai);
        whitelistSAFT[msg.sender] = 0;
    }

    function buyTokenUSDT(uint256 amountUsdt) public virtual override {
        require(_round > 0, "ICO not started");
        if (_round == 1) {
            require(
                whitelistSEED[msg.sender],
                "You are not whitelisted for the SEED Round"
            );
        }
        _buyTokenErc20(amountUsdt);
    }

    function _buyTokenErc20(uint256 usdtAmount) private {
        _preValidate();
        _validateAmountUsd(usdtAmount);

        IERC20 usdt = IERC20(usdtAddress());

        uint8 tokenDecimals = 18;
        uint8 usdtDecimals = 6;

        uint256 tokenAmount = ((usdtAmount *
            (10 ** (tokenDecimals - usdtDecimals))) / _price) *
            percent_dominator;

        require(
            usdt.allowance(msg.sender, address(this)) >= usdtAmount,
            "Insufficient USDT allowance"
        );

        IERC20(usdtAddress()).safeTransferFrom(
            msg.sender,
            address(this),
            usdtAmount
        );

        _execute(msg.sender, tokenAmount.mul(100));
    }

    function _execute(address beneficiary, uint256 amountCai) private {
        address walletAddress = _getVestingWalletAddress(beneficiary);
        require(
            _bought[beneficiary] == _round,
            "You already bought in a previous round"
        );
        tokensCollected[_round] += amountCai;
        _soldToken = _soldToken.add(amountCai);
        emit TokenTransferred(walletAddress, amountCai);
        emit TokenSold(beneficiary, amountCai);

        IERC20 cai = IERC20(caiAddress());
        require(
            cai.transfer(walletAddress, amountCai),
            "Crowdsale: CAI transfer failed"
        );
    }

    function _getVestingWalletAddress(
        address beneficiary
    ) private returns (address) {
        address existingWallet = _vestingWallets[beneficiary];

        if (existingWallet == address(0x0)) {
            VestingWallet wallet = new VestingWallet(
                beneficiary,
                vestingManagerAddress(),
                _round
            );

            address walletAddress = address(wallet);
            _vestingWallets[beneficiary] = walletAddress;
            _bought[beneficiary] = _round;
            return walletAddress;
        } else {
            return existingWallet;
        }
    }

    /**
     * Withdraw
     */
    function withdrawToken(
        address tokenAddress
    ) public virtual override onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        require(
            token.transfer(msg.sender, token.balanceOf(address(this))),
            "Crowdsale: token transfer failed"
        );
    }

    function withdrawUSDT() public onlyOwner {
        IERC20 usdt = IERC20(usdtAddress());
        usdt.safeTransfer(msg.sender, usdt.balanceOf(address(this)));
    }

    function clearStuckBalance(uint256 amountPercentage) external onlyOwner {
        uint256 amountETH = address(this).balance;
        payable(msg.sender).transfer((amountETH * amountPercentage) / 100);
    }

    function transferTokenOwnership(
        address tokenAddress
    ) public virtual override onlyOwner {
        Ownable cai = Ownable(tokenAddress);
        cai.transferOwnership(msg.sender);
    }

    function getLatestPrice() public view returns (int) {
        (
            uint80 roundID,
            int pricex,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return pricex;
    }

    /**
     * Validation
     */
    function _preValidate() private view {
        require(
            block.timestamp >= startTimestamp(),
            "Crowdsale: Sale isn't running yet"
        );

        require(
            block.timestamp < endTimestamp(),
            "Crowdsale: Sale was already finished"
        );
    }

    function _validateAmountETH() private view {
        require(msg.value > 0, "Crowdsale: Amount must be greater than 0");

        require(
            msg.value <= maxAmountETH(),
            "Crowdsale: Amount exceeds max. amount"
        );
    }

    function _validateAmountUsd(uint256 amountUsd) private view {
        require(amountUsd > 0, "Crowdsale: Amount must be greater than 0");

        require(
            amountUsd <= maxAmountUsd(),
            "Crowdsale: Amount exceeds max. amount"
        );
    }
}

pragma solidity ^0.8.0;

contract VestingManager is IVestingManager, Ownable {
    uint256 private _startTimestamp;
    uint256 private _durationSAFT;
    uint256 private _durationOne;
    uint256 private _durationTwo;
    uint256 private _durationThree;
    uint256 private _durationFour;
    uint256 private _durationFive;
    uint256 private _durationSix;
    uint256 private _cliffoffSAFT;
    uint256 private _cliffoffOne;
    uint256 private _cliffoffTwo;

    uint256 private _tgeThree;
    uint256 private _tgeFour;
    uint256 private _tgeFive;
    uint256 private _tgeSix;

    constructor() {
        _startTimestamp = type(uint256).max;
        _durationSAFT = 31536000;
        _durationOne = 31536000;
        _durationTwo = 26280000;
        _durationThree = 31536000;
        _durationFour = 26280000;
        _durationFive = 15768000;
        _durationSix = 15768000;
        _cliffoffSAFT = 7884000;
        _cliffoffOne = 2628000;
        _cliffoffTwo = 2628000;
        _tgeThree = 83;
        _tgeFour = 120;
        _tgeFive = 500;
        _tgeSix = 1000;
    }

    function startTimestamp() public view virtual override returns (uint256) {
        return _startTimestamp;
    }

    function cliffoffSAFT() public view virtual override returns (uint256) {
        return _cliffoffSAFT;
    }

    function cliffoffOne() public view virtual override returns (uint256) {
        return _cliffoffOne;
    }

    function cliffoffTwo() public view virtual override returns (uint256) {
        return _cliffoffTwo;
    }

    function durationSAFT() public view virtual override returns (uint256) {
        return _durationSAFT;
    }

    function durationOne() public view virtual override returns (uint256) {
        return _durationOne;
    }

    function durationTwo() public view virtual override returns (uint256) {
        return _durationTwo;
    }

    function durationThree() public view virtual override returns (uint256) {
        return _durationThree;
    }

    function durationFour() public view virtual override returns (uint256) {
        return _durationFour;
    }

    function durationFive() public view virtual override returns (uint256) {
        return _durationFive;
    }

    function durationSix() public view virtual override returns (uint256) {
        return _durationSix;
    }

    function tgeThree() public view virtual override returns (uint256) {
        return _tgeThree;
    }

    function tgeFour() public view virtual override returns (uint256) {
        return _tgeFour;
    }

    function tgeFive() public view virtual override returns (uint256) {
        return _tgeFive;
    }

    function tgeSix() public view virtual override returns (uint256) {
        return _tgeSix;
    }

    function setStartTimestamp(
        uint256 value
    ) public virtual override onlyOwner {
        require(
            value > block.timestamp,
            "VestingManager: Start timestamp must be in the future"
        );

        _startTimestamp = value;
    }

    function setCliffoffSAFT(uint256 value) public virtual override onlyOwner {
        _cliffoffSAFT = value;
    }

    function setCliffoffOne(uint256 value) public virtual override onlyOwner {
        _cliffoffOne = value;
    }

    function setCliffoffTwo(uint256 value) public virtual override onlyOwner {
        _cliffoffTwo = value;
    }

    function setDurationSAFT(uint256 value) public virtual override onlyOwner {
        _durationSAFT = value;
    }

    function setDurationOne(uint256 value) public virtual override onlyOwner {
        _durationOne = value;
    }

    function setDurationTwo(uint256 value) public virtual override onlyOwner {
        _durationTwo = value;
    }

    function setDurationThree(uint256 value) public virtual override onlyOwner {
        _durationThree = value;
    }

    function setDurationFour(uint256 value) public virtual override onlyOwner {
        _durationFour = value;
    }

    function setDurationFive(uint256 value) public virtual override onlyOwner {
        _durationFive = value;
    }

    function setDurationSix(uint256 value) public virtual override onlyOwner {
        _durationSix = value;
    }

    function setTgeThree(uint256 value) public virtual override onlyOwner {
        _tgeThree = value;
    }

    function setTgeFour(uint256 value) public virtual override onlyOwner {
        _tgeFour = value;
    }

    function setTgeFive(uint256 value) public virtual override onlyOwner {
        _tgeFive = value;
    }

    function setTgeSix(uint256 value) public virtual override onlyOwner {
        _tgeSix = value;
    }
}