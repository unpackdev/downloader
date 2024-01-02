// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

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
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}


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

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is specified at deployment time in the constructor for `Ownable`. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        if (pendingOwner() != sender) {
            revert OwnableUnauthorizedAccount(sender);
        }
        _transferOwnership(sender);
    }
}


/**
 * @title ZettaHashMultiVesting
 * @dev A smart contract for managing token vesting schedules for various roles.
 */
contract ZettaHashMultiVesting is Ownable2Step, ReentrancyGuard {
    using SafeERC20 for IERC20;
    
    /// Custom errors
    error OnlyZettaDashDAO();
    error CannotRevokeFounderVesting();
    error VestingIsRevokedAlready();
    error OnlyBeneficiaryCanClaim();
    error InvalidLockerId();
    error NoTokensToClaimYetOrClaimedAlready();
    error CannotClaimNativeToken();
    error FounderVestingCannotBeAssignedByDao();
    error ZeroAddressNotAllowed();
    error OnlyElectedMembers();
    error MinCycleNeedsToBeOne();
   
    /**
     * @dev Enumeration representing different statuses for vesting schedules.
     */
    enum Status{
        Founder, 
        Co_Founder,
        ElectedMember,
        Hasher,
        Vender,
        Contributor
    }
    
    /**
     * @dev Struct representing a vesting schedule for a user.
     */
    struct VestingSchedule {
        Status status;
        uint256 vestStartTime;
        uint256 cliffPeriod;
        uint256 cycles;
        uint256 vestingDuration;
        uint256 totalTokens;
        uint256 claimedTokens;
        bool revoked;
    }
    
    /// @notice zettahash token
    IERC20 public token;
    /// @notice nested mapping for lockers to users address to vesting schedule
    mapping(address => mapping(uint256 => VestingSchedule)) public userLockers;
    /// @notice mapping for lockers to address
    mapping(uint256 => address) private lockerOwners;
    /// @notice mapping for address to lockers 
    mapping(address => uint256[]) private lockers;
    /// @notice zettahash dao address
    address public ZettaHashDAO = msg.sender;
    /// @notice zettahash elected members
    address public ElectedMemberMultiSig = msg.sender;
    /// @notice nextLockerId
    uint256 public nextLockerId;
    
    /// Events
    event VestingAssigned(
        address indexed beneficiary,
        uint256 lockerId,
        uint256 vestStartTime,
        uint256 cliffPeriod,
        uint256 cycles,
        uint256 vestingDuration,
        uint256 totalTokens
    );

    event TokensClaimed(
        address indexed beneficiary,
        uint256 lockerId,
        uint256 amount
    );

    event VestingRevoked(
        address indexed beneficiary,
        uint256 lockerId,
        uint256 amount
    );
    
    /**
     * @dev Modifier to restrict a function to be called only by the ZettaHashDAO address.
     */
    modifier onlyZettaHashDao() {
        if (msg.sender != ZettaHashDAO) {
            revert OnlyZettaDashDAO();
        }
        _;
    }

    /**
     * @dev Modifier to restrict a function to be called only by the Elected Members.
     */
    modifier onlyElectedMembers() {
        if (msg.sender == ElectedMemberMultiSig) {
            revert OnlyElectedMembers();
        }
        _;
    }


    
    /**
     * @dev Create the multivesting contract and initilize it wilh required variables.
     * @param _token The address of the ERC20 token to be vested.
     */
    constructor(IERC20 _token) Ownable(msg.sender) {
        token = _token;
        nextLockerId = 1;
    }
    

    /**
     * @dev Assign vesting to founders.
     * @param beneficiary The address of the beneficiary.
     * @param cliffPeriod Duration in seconds for the cliff period.
     * @param cycles Number of vesting cycles.
     * @param vestingDuration Total duration of the vesting schedule in seconds.
     * @param totalTokens Total tokens to be vested.in wei format.
     */
    function assignVestingToFounders(
        address beneficiary,
        uint256 cliffPeriod,
        uint256 cycles,
        uint256 vestingDuration,
        uint256 totalTokens
    ) external onlyOwner nonReentrant {
        if(beneficiary == address(0)){
            revert ZeroAddressNotAllowed();
        }

        if(cycles < 1){
            revert MinCycleNeedsToBeOne();
        }
        uint256 lockerId = nextLockerId;
        token.safeTransferFrom(msg.sender, address(this), totalTokens);
        userLockers[beneficiary][lockerId] = VestingSchedule({
            
            status: Status.Founder,
            vestStartTime: block.timestamp,
            cliffPeriod: cliffPeriod,
            cycles: cycles,
            vestingDuration: vestingDuration,
            totalTokens: totalTokens,
            claimedTokens: 0,
            revoked: false
        });
        lockerOwners[lockerId] = beneficiary;
        lockers[beneficiary].push(lockerId);
        nextLockerId = nextLockerId + 1;

        emit VestingAssigned(
            beneficiary,
            lockerId,
            block.timestamp,
            cliffPeriod,
            cycles,
            vestingDuration,
            totalTokens
        );
    }
    

    /**
     * @dev Assign vesting to users other than founders.
     * @param beneficiary The address of the beneficiary.
     * @param userStatus 1 - Hasher, 2 - vender, 3 - Contributor
     * @param cliffPeriod Duration in seconds for the cliff period.
     * @param cycles Number of vesting cycles.
     * @param vestingDuration Total duration of the vesting schedule in seconds.
     * @param totalTokens Total tokens to be vested. (wei format)
     */
    function assignVestingToHasherOrVenderOrContributor(
        address beneficiary,
        uint8  userStatus,
        uint256 cliffPeriod,
        uint256 cycles,
        uint256 vestingDuration,
        uint256 totalTokens
    ) external onlyElectedMembers nonReentrant {
        if(beneficiary == address(0)){
            revert ZeroAddressNotAllowed();
        }
        if(cycles < 1){
            revert MinCycleNeedsToBeOne();
        }
        Status status;
        if(userStatus == 1){
            status = Status.Hasher;
        } else if (userStatus == 2){
            status = Status.Vender;
        } else {
            status = Status.Contributor;
        }
        uint256 lockerId = nextLockerId;
        token.safeTransferFrom(msg.sender, address(this), totalTokens);
        userLockers[beneficiary][lockerId] = VestingSchedule({
            status: status,
            vestStartTime: block.timestamp,
            cliffPeriod: cliffPeriod,
            cycles: cycles,
            vestingDuration: vestingDuration,
            totalTokens: totalTokens,
            claimedTokens: 0,
            revoked: false
        });
        lockerOwners[lockerId] = beneficiary;
        lockers[beneficiary].push(lockerId);
        nextLockerId = nextLockerId + 1;
        emit VestingAssigned(
            beneficiary,
            lockerId,
            block.timestamp,
            cliffPeriod,
            cycles,
            vestingDuration,
            totalTokens
        );
    }


    /**
     * @dev Assign vesting to users other than founders.
     * @param beneficiary The address of the beneficiary.
     * @param isCoFounder boolean value, true - coFounder, false - contributor
     * @param cliffPeriod Duration in seconds for the cliff period.
     * @param cycles Number of vesting cycles.
     * @param vestingDuration Total duration of the vesting schedule in seconds.
     * @param totalTokens Total tokens to be vested. (wei format)
     */
    function assignVestingToCoFoundersOrElectedMembers(
        address beneficiary,
        bool  isCoFounder,
        uint256 cliffPeriod,
        uint256 cycles,
        uint256 vestingDuration,
        uint256 totalTokens
    ) external onlyZettaHashDao nonReentrant {
        if(beneficiary == address(0)){
            revert ZeroAddressNotAllowed();
        }
        if(cycles < 1){
            revert MinCycleNeedsToBeOne();
        }
        Status userStatus;
        if(isCoFounder){
            userStatus = Status.Co_Founder;
        } else {
            userStatus = Status.Contributor;
        }
        uint256 lockerId = nextLockerId;
        token.safeTransferFrom(msg.sender, address(this), totalTokens);
        userLockers[beneficiary][lockerId] = VestingSchedule({
            status: userStatus,
            vestStartTime: block.timestamp,
            cliffPeriod: cliffPeriod,
            cycles: cycles,
            vestingDuration: vestingDuration,
            totalTokens: totalTokens,
            claimedTokens: 0,
            revoked: false
        });
        lockerOwners[lockerId] = beneficiary;
        lockers[beneficiary].push(lockerId);
        nextLockerId = nextLockerId + 1;
        emit VestingAssigned(
            beneficiary,
            lockerId,
            block.timestamp,
            cliffPeriod,
            cycles,
            vestingDuration,
            totalTokens
        );
    }


     /**
     * @dev Claim vested tokens.
     * @param lockerId The ID of the vesting locker.
     */
    function claimTokens(uint256 lockerId) external nonReentrant {
        if (lockerId < 1 || lockerId >= nextLockerId) {
            revert InvalidLockerId();
        }
        address user = lockerOwners[lockerId];
        if (msg.sender != user) {
            revert OnlyBeneficiaryCanClaim();
        }
        VestingSchedule storage vestingSchedule = userLockers[
            lockerOwners[lockerId]
        ][lockerId];
        if (vestingSchedule.revoked) {
            revert VestingIsRevokedAlready();
        }

        uint256 claimableTokens = checkClaimableTokens(lockerId);
        if (claimableTokens == 0) {
            revert NoTokensToClaimYetOrClaimedAlready();
        }

        vestingSchedule.claimedTokens += claimableTokens;

        token.safeTransfer(lockerOwners[lockerId], claimableTokens);

        emit TokensClaimed(lockerOwners[lockerId], lockerId, claimableTokens);
    }
    
    /**
     * @dev Revoke vested tokens.
     * @param lockerId The ID of the vesting locker.
     */
    function revokeVesting(uint256 lockerId)
        external
        onlyZettaHashDao
        nonReentrant
    {
        if (lockerId < 1 && lockerId >= nextLockerId) {
            revert InvalidLockerId();
        }
        VestingSchedule storage vestingSchedule = userLockers[
            lockerOwners[lockerId]
        ][lockerId];
        Status userStatus = vestingSchedule.status;
        if (
           userStatus ==
            Status.Founder
        ) {
            revert CannotRevokeFounderVesting();
        }
        if (vestingSchedule.revoked) {
            revert VestingIsRevokedAlready();
        }

        uint256 remainingTokens = vestingSchedule.totalTokens -
            vestingSchedule.claimedTokens;

        vestingSchedule.revoked = true;

        if (remainingTokens > 0) {
            token.safeTransfer(owner(), remainingTokens);
        }

        emit VestingRevoked(lockerOwners[lockerId], lockerId, remainingTokens);
    }
    
    /**
     * @dev Set the ZettaHashDAO address.
     * @param newDaoAddress The new address for the ZettaHashDAO.
     */
    function setZettaHashDao(address newDaoAddress) external onlyOwner {
        if (newDaoAddress != address(0) || newDaoAddress != ZettaHashDAO) {
            ZettaHashDAO = newDaoAddress;
        }

    }

    /**
     * @dev Set the ElectedMemberMultiSig address.
     * @param newElectedMembersAddress The new address for the ElectedMember
     */
    function setElectedMember(address newElectedMembersAddress) external onlyOwner {
        if (newElectedMembersAddress != address(0) || newElectedMembersAddress != ElectedMemberMultiSig) {
            ElectedMemberMultiSig = newElectedMembersAddress;
        }
    
    }

    /**
     * @dev Claim ERC20 tokens other than the vested token.
     * @param otherToken The address of the ERC20 token to be claimed.
     * @param amount The amount of tokens to be claimed.
     */
    function claimOtherERC20(IERC20 otherToken, uint256 amount)
        external
        onlyOwner
    {
        if (otherToken != token) {
            otherToken.safeTransfer(owner(), amount);
        } else {
            revert CannotClaimNativeToken();
        }
    }
    

    /**
     * @dev Check the amount of tokens claimable for a given vesting locker.
     * @param lockerId The ID of the vesting locker.
     * @return claimableTokens The amount of tokens claimable.
     */
    function checkClaimableTokens(uint256 lockerId)
        public
        view
        returns (uint256)
    {
        VestingSchedule storage vestingSchedule = userLockers[
            lockerOwners[lockerId]
        ][lockerId];
        if (block.timestamp < vestingSchedule.vestStartTime) {
            return 0; // Vesting has not started
        }

        uint256 elapsed = block.timestamp - vestingSchedule.vestStartTime;
        uint256 timeSinceCliff = elapsed < vestingSchedule.cliffPeriod
            ? 0
            : elapsed - vestingSchedule.cliffPeriod;
        uint256 cycleDuration = vestingSchedule.vestingDuration /
            vestingSchedule.cycles;

        // Calculate the completed cycles
        uint256 completedCycles = timeSinceCliff / cycleDuration;

        // Ensure completed cycles do not exceed the allotted cycles
        completedCycles = completedCycles > vestingSchedule.cycles
            ? vestingSchedule.cycles
            : completedCycles;

        // Calculate the claimable tokens based on the completed cycles
        uint256 claimableTokens = (completedCycles *
            vestingSchedule.totalTokens) / vestingSchedule.cycles;
        // Deduct the already claimed tokens
        claimableTokens -= vestingSchedule.claimedTokens;
        // Ensure claimable tokens do not exceed the total allotted tokens
        if (
            claimableTokens + vestingSchedule.claimedTokens >
            vestingSchedule.totalTokens
        ) {
            claimableTokens =
                vestingSchedule.totalTokens -
                vestingSchedule.claimedTokens;
        }

        return claimableTokens > 0 ? claimableTokens : 0;
    }
    

    /**
     * @dev Get the list of locker IDs for a user.
     * @param user The address of the user.
     * @return lockersList An array of locker IDs.
     */
    function getUserLockersList(address user)
        public
        view
        returns (uint256[] memory)
    {
        return lockers[user];
    }
}