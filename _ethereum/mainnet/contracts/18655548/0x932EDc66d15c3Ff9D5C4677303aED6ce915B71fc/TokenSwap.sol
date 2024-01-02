// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

pragma solidity ^0.8.20;

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: Swapper.sol


pragma solidity ^0.8.20;



contract TokenSwap is Ownable {
    IERC20 public tokenX;
    IERC20 public tokenY;

    uint256 public exchangeRate;

    mapping(address => uint256) public userTokenXAmount;

    bool public swapTokensEnabled = true;
    bool public claimTokensEnabled = true;

    event TokensSwapped(address indexed user, uint256 amountX, uint256 totalAmountY, uint256 exchangeRate);
    event TokensClaimed(address indexed user, uint256 claimedAmountY);
    event ExchangeRateUpdated(uint256 newExchangeRate);
    event TokenYUpdated(address newTokenY);
    event SwapTokensEnabled(bool enabled);
    event ClaimTokensEnabled(bool enabled);

    constructor(IERC20 _tokenX, uint256 _initialExchangeRate, address initialOwner) Ownable(initialOwner) {
        tokenX = _tokenX;
        exchangeRate = _initialExchangeRate;
    }

    modifier swapTokensEnabledOnly() {
        require(swapTokensEnabled, "SwapTokens is currently disabled");
        _;
    }

    modifier claimTokensEnabledOnly() {
        require(claimTokensEnabled, "ClaimTokens is currently disabled");
        _;
    }

    function setTokenY(IERC20 _tokenY) external onlyOwner {
        require(address(_tokenY) != address(0), "Invalid token address");
        tokenY = _tokenY;
        emit TokenYUpdated(address(_tokenY));
    }

    function depositTokens(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        require(tokenY.transferFrom(msg.sender, address(this), amount), "Token transfer failed");
    }

    function swapTokens(uint256 amount) external swapTokensEnabledOnly {
        require(amount > 0, "Amount must be greater than zero");

        require(tokenX.transferFrom(msg.sender, address(this), amount), "Token transfer failed");

        uint256 totalAmountY = (amount * exchangeRate) / 100;
        userTokenXAmount[msg.sender] += totalAmountY;

        emit TokensSwapped(msg.sender, amount, userTokenXAmount[msg.sender], exchangeRate);
    }

    function claimTokens() external claimTokensEnabledOnly {
        uint256 claimedAmountY = userTokenXAmount[msg.sender];
        require(claimedAmountY > 0, "No tokens to claim");

        userTokenXAmount[msg.sender] = 0;
        require(tokenY.transfer(msg.sender, claimedAmountY), "Token transfer failed");

        emit TokensClaimed(msg.sender, claimedAmountY);
    }

    function withdrawTokensX(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        require(tokenX.transfer(owner(), amount), "Token transfer failed");
    }

    function withdrawTokensY(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        require(tokenY.transfer(owner(), amount), "Token transfer failed");
    }

    function changeOwner(address newOwner) external onlyOwner {
        transferOwnership(newOwner);
    }

    function setExchangeRate(uint256 newExchangeRate) external onlyOwner {
        require(newExchangeRate > 0, "Exchange rate must be greater than zero");
        exchangeRate = newExchangeRate;
        emit ExchangeRateUpdated(newExchangeRate);
    }

    function enableSwapTokens(bool _enabled) external onlyOwner {
        swapTokensEnabled = _enabled;
        emit SwapTokensEnabled(_enabled);
    }

    function enableClaimTokens(bool _enabled) external onlyOwner {
        claimTokensEnabled = _enabled;
        emit ClaimTokensEnabled(_enabled);
    }
}