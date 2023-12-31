// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
     * Emits a {Transfer} event. C U ON THE MOON
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract SimpleStaking is Ownable {
    // boolean to prevent reentrancy
    bool internal locked;

    uint256 public timePeriod = 7 days;


    // Token amount variables
    mapping(address => uint256) public balances;
    mapping(address => uint256) public stakedAt;
    uint256 public totalStaked;
    uint256 public totalRewards;

    // ERC20 contract address
    IERC20 public erc20Contract = IERC20(0xF295F068db0d9175F0500e7B9255Fc5e2Ad673fA);

    // Events
    event TokensStaked(address from, uint256 amount);
    event TokensUnstaked(address to, uint256 amount);

    constructor() {
        // Initialize the reentrancy variable to not locked
        locked = false;
    }

    // Modifier
    /**
     * @dev Prevents reentrancy
     */
    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    /// @param _timePeriodInSeconds amount of seconds minimum staking period
    function setTimestamp(uint256 _timePeriodInSeconds) external onlyOwner  {
        timePeriod = _timePeriodInSeconds;
    }

    /// @dev Allows the contract owner to allocate official ERC20 tokens to each future recipient (only one at a time).
    /// @param amount to allocate to recipient.
    function stakeTokens(uint256 amount) external noReentrant {
        erc20Contract.transferFrom(msg.sender, address(this), amount);
        balances[msg.sender] += amount;
        stakedAt[msg.sender] = block.timestamp;
        totalStaked += amount;
        emit TokensStaked(msg.sender, amount);
    }

    /// @dev Allows user to unstake tokens after the correct time period has elapsed
    /// @param amount - the amount to unlock
    function unstakeTokens(uint256 amount) external noReentrant {
        require(balances[msg.sender] >= amount, "Insufficient token balance, try lesser amount");
        if (block.timestamp >= timePeriod + stakedAt[msg.sender]) {
            balances[msg.sender] -= amount;
            erc20Contract.transfer(msg.sender, amount);
            totalStaked -= amount;
            emit TokensUnstaked(msg.sender, amount);
        } else {
            revert("Tokens are only available after correct time period has elapsed");
        }
    }

    function addRewards(uint256 amount) external {
        erc20Contract.transferFrom(msg.sender, address(this), amount);
        totalRewards += amount;
    }

    function distributeRewards(uint256 amount, address[] calldata stakers) external onlyOwner {
        for(uint256 i = 0; i < stakers.length; i++){
            erc20Contract.transfer(stakers[i], balances[stakers[i]] * amount / totalStaked);
        }
        totalRewards -= amount;
    }

    function reduceRewards(uint256 amount) external onlyOwner {
        erc20Contract.transfer(owner(), amount);
        totalRewards -= amount;
    }

    /// @dev Transfer accidentally locked ERC20 tokens.
    /// @param token - ERC20 token address.
    /// @param amount of ERC20 tokens to remove.
    function transferAccidentallyLockedTokens(IERC20 token, uint256 amount) external onlyOwner {
        require(address(token) != address(0), "Token address can not be zero");
        // This function can not access the official timelocked tokens; just other random ERC20 tokens that may have been accidently sent here
        require(token != erc20Contract, "Token address can not be ERC20 address which was passed into the constructor");
        // Transfer the amount of the specified ERC20 tokens, to the owner of this contract
        token.transfer(owner(), amount);
    }
}