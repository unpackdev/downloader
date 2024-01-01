// File: contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

pragma solidity ^0.8.20;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

// File: contracts/token/ERC20/extensions/IERC20Permit.sol


// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
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
     *
     * CAUTION: See Security Considerations above.
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

// File: contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// File: contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.20;




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

    /**
     * @dev An operation with an ERC20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
}

// File: contracts/CC_OFFRAMP/CC_OFFRAMP_AIR_ETH.sol

/**
 *Submitted for verification at BscScan.com on 
*/

/*                                                                                                                                                                                      
 * ARK Air Card ETHEREUM
 * 
 * Forked/Edited by: DutchDapps.com 
 * 
 * SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.20;



interface IBEP20 is IERC20 {
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IDEXRouter {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external payable;
}

contract CC_OFFRAMP  {
    using SafeERC20 for IBEP20;
    IBEP20 public USDT;

    address public constant CEO = 0xB8e0a68f2509b89f08E0D9F3C1a48Fc0d5Cf68B0;
    address public treasury = 0xB8e0a68f2509b89f08E0D9F3C1a48Fc0d5Cf68B0;
    address public fallbackReferrer = 0xB8e0a68f2509b89f08E0D9F3C1a48Fc0d5Cf68B0;
    
    //IBEP20 public constant USDT = IBEP20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IDEXRouter public constant ROUTER = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public constant WBNB = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    
    mapping(string => Deposit) public deposits;
    mapping(address => address) public referrerOf;
    mapping(address => address[]) public downline;   
    mapping(address => uint256) public totalReferralRewards1;
    mapping(address => uint256) public totalReferralRewards2;
    mapping(address => uint256) public totalReferrals;

    event DepositDone(string uid, Deposit details);    
    
    uint256 multiplier = 10**6;
    uint256 minDeposit;
    uint256 maxDeposit = 5000 * multiplier;
    uint256 public affiliateReward = 4 * multiplier;
    uint256 public secondLevelReward = 1 * multiplier;

    struct Deposit {
        address user;
        address currency;
        uint256 currencyAmount;
        uint256 depositAmount;
        uint256 timestamp;
        bool isReload;
        bool hasSupport;
        bool hasLegacy;
        address referrer;
        address secondLevelReferrer;
    }

    modifier onlyCEO() {
        require(msg.sender == CEO, "Only CEO");
        _;
    }

	constructor(address _usdtAddress) {
        USDT = IBEP20(_usdtAddress);
        USDT.approve(address(ROUTER), type(uint256).max);
    }

    receive() external payable {}

    function checkIfUidIsUsed(string memory uid) internal view returns (bool) {
        if(deposits[uid].timestamp != 0) return true;
        return false;
    }

    function depositMoneyUSDT(uint256 amount, string memory uid, bool isReload, bool hasSupport, address referrer, bool hasLegacy) external {        
        require(!checkIfUidIsUsed(uid),"Uid already exists");
        uint256 balanceBefore = USDT.balanceOf(address(this));        
        USDT.safeTransferFrom(msg.sender, address(this), amount * multiplier);
        Deposit memory deposit = Deposit(msg.sender, address(USDT), amount * multiplier, 0, block.timestamp, isReload, hasSupport, false, address(0), address(0));
        deposits[uid] = deposit;
        if(referrer == address(0) || referrer == msg.sender) referrer = fallbackReferrer;  
        if(referrerOf[msg.sender] == address(0)) {
            referrerOf[msg.sender] = referrer;
            downline[referrer].push(msg.sender);
        }
        _deposit(balanceBefore, uid, referrerOf[msg.sender], hasLegacy);
    }

    function depositMoneyBNB(string memory uid, uint256 minOut, bool isReload, bool hasSupport, address referrer, bool hasLegacy) public payable {
        require(!checkIfUidIsUsed(uid),"Uid already exists");
        uint256 balanceBefore = USDT.balanceOf(address(this));
        Deposit memory deposit = Deposit(msg.sender, address(0), msg.value, 0, block.timestamp, isReload, hasSupport, false, address(0), address(0));
        deposits[uid] = deposit;

        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(USDT);
        
        ROUTER.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            minOut * multiplier,
            path,
            address(this),
            block.timestamp
        );
        if(referrer == address(0) || referrer == msg.sender) referrer = fallbackReferrer;  
        if(referrerOf[msg.sender] == address(0)) {
            referrerOf[msg.sender] = referrer;
            downline[referrer].push(msg.sender);
        }
        _deposit(balanceBefore, uid, referrerOf[msg.sender], hasLegacy);
    }

    function depositMoneyEasy(
        uint256 amount, 
        address currency, 
        uint256 minOut, 
        string memory uid, 
        bool isReload, 
        bool hasSupport, 
        address referrer,
        bool hasLegacy
    ) external {
        require(!checkIfUidIsUsed(uid),"Uid already exists");
        require(IBEP20(currency).transferFrom(msg.sender, address(this), amount), "failed");
        IBEP20(currency).approve(address(ROUTER), type(uint256).max);

        Deposit memory deposit = Deposit(msg.sender, currency, amount, 0, block.timestamp, isReload, hasSupport, false, address(0), address(0));
        deposits[uid] = deposit;

        address[] memory path = new address[](2);
        path[0] = currency;
        path[1] = address(USDT);

        uint256 balanceBefore = USDT.balanceOf(address(this));
        ROUTER.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            minOut * multiplier,
            path,
            address(this),
            block.timestamp
        );
        if(referrer == address(0) || referrer == msg.sender) referrer = fallbackReferrer;  
        if(referrerOf[msg.sender] == address(0)) {
            referrerOf[msg.sender] = referrer;
            downline[referrer].push(msg.sender);
        }
        _deposit(balanceBefore, uid, referrerOf[msg.sender], hasLegacy);
    }

    function depositMoneyExpert(
        uint256 amount,
        address[] memory path,
        uint256 minOut,
        string memory uid,
        bool isReload,
        bool hasSupport,
        address referrer,
        bool hasLegacy
    ) external {
        require(!checkIfUidIsUsed(uid),"Uid already exists");
        require(IBEP20(path[0]).transferFrom(msg.sender, address(this), amount), "failed");
        require(path[path.length - 1] == address(USDT), "wrong");
        IBEP20(path[0]).approve(address(ROUTER), type(uint256).max);

        Deposit memory deposit = Deposit(msg.sender, path[0], amount, 0, block.timestamp, isReload, hasSupport, false, address(0), address(0));
        deposits[uid] = deposit;
        
        uint256 balanceBefore = USDT.balanceOf(address(this));
        ROUTER.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            minOut * multiplier,
            path,
            address(this),
            block.timestamp
        );
        if(referrer == address(0) || referrer == msg.sender) referrer = fallbackReferrer;  
        if(referrerOf[msg.sender] == address(0)) {
            referrerOf[msg.sender] = referrer;
            downline[referrer].push(msg.sender);
        }
        _deposit(balanceBefore, uid, referrerOf[msg.sender], hasLegacy);
    }

    function _deposit(uint256 balanceBefore, string memory uid, address referrer, bool hasLegacy) internal {
        uint256 depositAmount = USDT.balanceOf(address(this)) - balanceBefore;
        require(depositAmount >= minDeposit, "Min deposit");
        require(depositAmount <= maxDeposit, "Max deposit");
        deposits[uid].depositAmount = depositAmount;
        deposits[uid].hasLegacy = hasLegacy;
        if(!hasLegacy) {
            USDT.safeTransfer(referrer, affiliateReward);
            if(referrerOf[referrer] == address(0)) referrerOf[referrer] = fallbackReferrer;
            address secondLevelAddress = referrerOf[referrer];
            USDT.safeTransfer(secondLevelAddress, secondLevelReward);
            totalReferralRewards1[referrer] += affiliateReward;
            totalReferralRewards2[secondLevelAddress] += secondLevelReward;
            totalReferrals[referrer]++;
            totalReferrals[secondLevelAddress]++;
            deposits[uid].referrer = referrer;
            deposits[uid].secondLevelReferrer = secondLevelAddress;
            depositAmount -= affiliateReward;
            depositAmount -= secondLevelReward;
        }
        USDT.safeTransfer(treasury, depositAmount);
        emit DepositDone(uid, deposits[uid]);
    }

    function expectedUSDTFromCurrency(uint256 input, address currency) public view returns(uint256) {
        address[] memory path = new address[](2);
        path[0] = currency;
        path[1] = address(USDT);
        uint256 usdtAmount = ROUTER.getAmountsOut(input, path)[path.length - 1];
        return usdtAmount; 
    }

    function expectedUSDTFromPath(uint256 input, address[] memory path) public view returns(uint256) {
        require(path[path.length-1] == address(USDT), "USDT");
        uint256 usdtAmount = ROUTER.getAmountsOut(input, path)[path.length - 1];
        return usdtAmount;
    }

    function rescueAnyToken(IBEP20 tokenToRescue) external onlyCEO {
        uint256 _balance = tokenToRescue.balanceOf(address(this));
        tokenToRescue.transfer(CEO, _balance);
    }

    function rescueBnb() external onlyCEO {
        (bool success,) = address(CEO).call{value: address(this).balance}("");
        if(success) return;
    } 

    function setLimits(uint256 newMinDeposit, uint256 newMaxDeposit) external onlyCEO {
        minDeposit = newMinDeposit * multiplier;
        maxDeposit = newMaxDeposit * multiplier;
    }
    
    function setTreasury(address newTreasury) external onlyCEO {
        treasury = newTreasury;
    }    

    function setFallbackReferrer(address newFallbackReferrer) external onlyCEO {
        fallbackReferrer = newFallbackReferrer;
    }

    function setReferrer(address investor, address newReferrer) external onlyCEO {
        referrerOf[investor] = newReferrer;
    }

    function setReferrers(address oldReferrer, address newReferrer) external onlyCEO {
        for(uint256 i = 0; i<downline[oldReferrer].length;i++){
            referrerOf[downline[oldReferrer][i]] = newReferrer;
        }
    }

    function setAffiliateReward(uint256 newAffiliateReward, uint256 newSecondLevelReward) external onlyCEO {
        affiliateReward = newAffiliateReward * multiplier;
        secondLevelReward = newSecondLevelReward * multiplier;
    }
}