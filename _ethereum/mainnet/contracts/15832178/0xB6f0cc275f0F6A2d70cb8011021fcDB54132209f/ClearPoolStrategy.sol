// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

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
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

    function decimals() external view returns (uint8);
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
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

contract CustomInitializable {
    bool private _wasInitialized;

    modifier ifInitialized () {
        require(_wasInitialized, "Not initialized yet");
        _;
    }

    modifier ifNotInitialized () {
        require(!_wasInitialized, "Already initialized");
        _;
    }

    function _initializationCompleted () internal ifNotInitialized {
        _wasInitialized = true;
    }
}

interface IClearPoolBase is IERC20 {
    function provide (uint256 currencyAmount) external;
    function redeem (uint256 tokens) external;
    function currency () external view returns (IERC20);
    function getCurrentExchangeRate () external view returns (uint256);
}

abstract contract BasePoolStrategy is CustomInitializable, Ownable, ReentrancyGuard {
    // The zero address
    address internal constant ZERO_ADDRESS = address(0);

    // The address of the pool
    address public poolAddress;

    // The address of the collateral token (aka: the token to deposit)
    address public currencyTokenAddress;

    // The address authorized to deposit funds into this contract
    address public vaultAddress;

    // The address authorized to interact with the pool
    address public operator;

    event OnVaultAddressUpdated (address prevValue, address newValue);
    event OnOperatorUpdated (address prevValue, address newValue);
    event OnDeposit (uint256 depositAmount, address tokenAddr, address senderAddr);
    event OnWithdrawal (uint256 withdrawalAmount, address tokenAddr, address senderAddr);

    modifier onlyVault () {
        require(msg.sender == vaultAddress, "Unauthorized sender");
        _;
    }

    modifier onlyOwnerOrOperator () {
        require(msg.sender == operator || msg.sender == owner(), "Unauthorized operator");
        _;
    }

    /**
     * @notice Sets the vault address the strategy will receive deposits from. 
     * @param vaultAddr Specifies the address of the Vault
     */
    function changeVaultAddress(address vaultAddr) external onlyOwnerOrOperator {
        require(vaultAddr != address(0), "Invalid address");

        emit OnVaultAddressUpdated(vaultAddress, vaultAddr);
        vaultAddress = vaultAddr;
    }

    function changeOperator(address operatorAddr) external onlyOwner {
        require(operatorAddr != address(0), "Invalid address");

        emit OnOperatorUpdated(operator, operatorAddr);
        operator = operatorAddr;
    }

    function withdrawToEoa (uint256 amount) external onlyOwner ifInitialized nonReentrant {
        require(IERC20(currencyTokenAddress).balanceOf(address(this)) >= amount, "Insufficient balance");
        require(IERC20(currencyTokenAddress).transfer(msg.sender, amount), "Transfer failed");
    }

    function deposit (uint256 depositAmount) external virtual;
    function withdraw (uint256 withdrawalAmount) external virtual;

    function _depositIntoThisContract (uint256 depositAmount, address senderAddr, IERC20 token) internal virtual returns (uint256) {
        require(depositAmount > 0, "Invalid deposit amount");
        require(token.balanceOf(senderAddr) >= depositAmount, "Insufficient balance");
        require(token.allowance(senderAddr, address(this)) >= depositAmount, "Insufficient allowance");

        uint256 balanceBeforeTransfer = token.balanceOf(address(this));
        require(token.transferFrom(senderAddr, address(this), depositAmount), "TransferFrom failed");
        uint256 balanceAfterTransfer = token.balanceOf(address(this));
        require(balanceAfterTransfer == balanceBeforeTransfer + depositAmount, "Balance verification failed");

        emit OnDeposit(depositAmount, address(token), senderAddr);

        return balanceAfterTransfer;
    }

    function _withdrawFromThisContract (uint256 withdrawalAmount, address senderAddr, IERC20 token) internal virtual {
        require(withdrawalAmount > 0, "Invalid withdrawal amount");
        require(token.balanceOf(address(this)) >= withdrawalAmount, "Insufficient balance");
        require(token.transfer(senderAddr, withdrawalAmount), "Token transfer failed");

        emit OnWithdrawal(withdrawalAmount, address(token), senderAddr);
    }
}

contract ClearPoolStrategy is BasePoolStrategy {
    function initializeStrategy (IClearPoolBase pool, address vaultAddr, address operatorAddr) external onlyOwner ifNotInitialized {
        require(vaultAddr != ZERO_ADDRESS, "Invalid vault address");
        require(operatorAddr != ZERO_ADDRESS, "Invalid operator address");
        require(address(pool) != ZERO_ADDRESS, "Invalid Pool address");
        require(address(pool.currency()) != ZERO_ADDRESS, "Invalid currency address");

        poolAddress = address(pool);
        currencyTokenAddress = address(pool.currency());
        vaultAddress = vaultAddr;
        operator = operatorAddr;
    }

    /**
     * @notice Deposits funds into this strategy.
     * @param depositAmount The amount of tokens to deposit.
     */
    function deposit (uint256 depositAmount) external override onlyVault ifInitialized nonReentrant {
        _depositIntoThisContract(depositAmount, msg.sender, IERC20(currencyTokenAddress));
    }

    /**
     * @notice Withdraws funds from this strategy.
     * @param withdrawalAmount The amount of tokens to withdraw.
     */
    function withdraw (uint256 withdrawalAmount) external override onlyVault ifInitialized nonReentrant {
        _withdrawFromThisContract(withdrawalAmount, msg.sender, IERC20(currencyTokenAddress));
    }

    /**
     * @notice Deposits funds into the pool.
     * @param depositAmount The deposit amount.
     */
    function depositInPool (uint256 depositAmount) external onlyOwnerOrOperator ifInitialized nonReentrant {
        require(depositAmount > 0, "Deposit amount required");
        require(IERC20(currencyTokenAddress).balanceOf(address(this)) >= depositAmount, "Insufficient balance");

        // Spender approval, if needed
        if (depositAmount > IERC20(currencyTokenAddress).allowance(address(this), poolAddress)) {
            require(IERC20(currencyTokenAddress).approve(poolAddress, depositAmount), "Approval failed");
        }

        uint256 balanceBeforeDeposit = IClearPoolBase(poolAddress).balanceOf(address(this));
        uint256 exchangeRate = IClearPoolBase(poolAddress).getCurrentExchangeRate();
        uint256 minOutputTokensExpected = (depositAmount * 1e18) / exchangeRate;

        // Deposit into the pool
        IClearPoolBase(poolAddress).provide(depositAmount);

        // Check
        require(IClearPoolBase(poolAddress).balanceOf(address(this)) >= balanceBeforeDeposit + minOutputTokensExpected, "Balance verification failed");

        emit OnPoolDeposit(depositAmount);
    }

    event OnPoolDeposit (uint256 depositAmount);
    event OnPoolWithdrawal (uint256 lpTokensAmount, uint256 collateralAmount);

    function withdrawFromPool (uint256 lpTokensAmount) external onlyOwnerOrOperator ifInitialized nonReentrant {
        require(lpTokensAmount > 0, "Withdrawal amount required");

        uint256 balanceBefore = IERC20(currencyTokenAddress).balanceOf(address(this));
        uint256 exchangeRate = IClearPoolBase(poolAddress).getCurrentExchangeRate();
        uint256 expectedBalance = (lpTokensAmount * 1e18) * exchangeRate;

        IClearPoolBase(poolAddress).redeem(lpTokensAmount);

        require(IERC20(currencyTokenAddress).balanceOf(address(this)) > balanceBefore, "Balance verification failed");

        emit OnPoolWithdrawal(lpTokensAmount, expectedBalance);
    }

    function getPoolBalance () public view returns (uint256) {
        return IERC20(poolAddress).balanceOf(address(this));
    }
}