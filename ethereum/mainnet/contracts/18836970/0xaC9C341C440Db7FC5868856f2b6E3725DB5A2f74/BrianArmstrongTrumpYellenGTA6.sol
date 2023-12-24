// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

// File: contracts/multistake.sol


pragma solidity ^0.8.0;





contract BrianArmstrongTrumpYellenGTA6 is Ownable, Pausable, ReentrancyGuard {
    event TokenStaked(
        address indexed user,
        address indexed token,
        uint256 amount
    );
    event TokenUnstaked(
        address indexed user,
        address indexed token,
        uint256 amount
    );
    event AllowedTokenAdded(address token, uint256 multiplier);
    event AllowedTokenRemoved(address token);
    event TokenMultiplierUpdated(address token, uint256 newMultiplier);
    event EmergencyWithdrawn(
        address indexed user,
        address indexed token,
        uint256 amount
    );

    struct StakingInfo {
        uint256 amount;
        uint256 startTime;
        uint256 accumulatedReward;
    }

    bool public emergencyWithdrawActive = false;

    mapping(address => bool) public isTokenAllowedMapping;

    mapping(address => mapping(address => StakingInfo)) public stakingInfo;

    mapping(address => uint256) public tokenRewardMultiplier;

    address[] public allowedTokens;

    constructor(address initialOwner) Ownable(initialOwner) {}

    function addAllowedToken(address _token, uint256 _multiplier)
        public
        onlyOwner
    {
        require(_token != address(0), "Invalid token address");
        require(!isTokenAllowedMapping[_token], "Token already allowed");

        allowedTokens.push(_token);
        tokenRewardMultiplier[_token] = _multiplier;
        isTokenAllowedMapping[_token] = true;

        emit AllowedTokenAdded(_token, _multiplier);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function removeAllowedToken(address _token) public onlyOwner {
        require(_token != address(0), "Invalid token address");
        require(isTokenAllowedMapping[_token], "Token not allowed");

        for (uint256 i = 0; i < allowedTokens.length; i++) {
            if (allowedTokens[i] == _token) {
                allowedTokens[i] = allowedTokens[allowedTokens.length - 1];
                allowedTokens.pop();
                break;
            }
        }

        isTokenAllowedMapping[_token] = false;
        emit AllowedTokenRemoved(_token);
    }

    function updateTokenMultiplier(address _token, uint256 _multiplier)
        public
        onlyOwner
    {
        require(isTokenAllowed(_token), "Token is not allowed");
        tokenRewardMultiplier[_token] = _multiplier;
        emit TokenMultiplierUpdated(_token, _multiplier);
    }

    function isTokenAllowed(address _token) public view returns (bool) {
        return isTokenAllowedMapping[_token];
    }

    function stakeTokens(uint256 _amount, address _token)
        public
        nonReentrant
        whenNotPaused
    {
        require(_amount > 0, "Amount cannot be 0");
        require(isTokenAllowed(_token), "Token is not allowed");

        IERC20 token = IERC20(_token);
        uint256 initialBalance = token.balanceOf(address(this));

        // Check user's balance and allowance
        require(
            token.balanceOf(msg.sender) >= _amount,
            "Insufficient balance."
        );
        require(
            token.allowance(msg.sender, address(this)) >= _amount,
            "Token allowance not set or insufficient."
        );

        // Update staking info before transferring tokens
        stakingInfo[msg.sender][_token].amount += _amount;
        stakingInfo[msg.sender][_token].startTime = block.timestamp;

        // Transfer the tokens
        require(
            token.transferFrom(msg.sender, address(this), _amount),
            "Transfer failed"
        );

        // Validate that the correct amount of tokens was transferred
        require(
            token.balanceOf(address(this)) - initialBalance == _amount,
            "Incorrect amount transferred"
        );

        emit TokenStaked(msg.sender, _token, _amount);
    }

    function unstakeTokens(uint256 _amount, address _token)
        public
        nonReentrant
        whenNotPaused
    {
        require(_amount > 0, "Amount cannot be 0");
        require(
            stakingInfo[msg.sender][_token].amount >= _amount,
            "Insufficient staked amount"
        );

        updateAccumulatedReward(msg.sender, _token);

        stakingInfo[msg.sender][_token].amount -= _amount;
        require(
            IERC20(_token).transfer(msg.sender, _amount),
            "Transfer failed"
        );
        emit TokenUnstaked(msg.sender, _token, _amount);
    }

    function updateAccumulatedReward(address _user, address _token) internal {
        StakingInfo storage info = stakingInfo[_user][_token];
        if (info.amount > 0) {
            uint256 reward = calculateReward(_user, _token);
            info.accumulatedReward += reward;
            info.startTime = block.timestamp;
        }
    }

    function calculateReward(address _user, address _token)
        internal
        view
        returns (uint256)
    {
        StakingInfo storage info = stakingInfo[_user][_token];
        uint256 stakingTime = block.timestamp - info.startTime;
        uint256 rewardMultiplier = tokenRewardMultiplier[_token];

        uint256 reward = stakingTime * rewardMultiplier * info.amount;
        return reward;
    }

    function getAccumulatedReward(address _user, address _token)
        public
        view
        returns (uint256)
    {
        StakingInfo storage info = stakingInfo[_user][_token];
        uint256 reward = calculateReward(_user, _token);
        return info.accumulatedReward + reward;
    }

    function getAllRewardsForUser(address user)
        external
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        uint256 tokenCount = allowedTokens.length;

        address[] memory tokens = new address[](tokenCount);
        uint256[] memory balances = new uint256[](tokenCount);
        uint256[] memory rewards = new uint256[](tokenCount);

        for (uint256 i = 0; i < tokenCount; i++) {
            address token = allowedTokens[i];
            tokens[i] = token;
            balances[i] = stakingInfo[user][token].amount;
            rewards[i] = getAccumulatedReward(user, token);
        }

        return (tokens, balances, rewards);
    }

    function setEmergencyWithdrawActive(bool _active) external onlyOwner {
        emergencyWithdrawActive = _active;
    }

    function emergencyWithdraw(address _token) external nonReentrant {
        require(emergencyWithdrawActive, "Emergency withdraw is not active");

        uint256 amount = stakingInfo[msg.sender][_token].amount;
        require(amount > 0, "No tokens to withdraw");

        stakingInfo[msg.sender][_token].amount = 0;
        stakingInfo[msg.sender][_token].accumulatedReward = 0;

        require(IERC20(_token).transfer(msg.sender, amount), "Transfer failed");
        emit EmergencyWithdrawn(msg.sender, _token, amount);
    }
}