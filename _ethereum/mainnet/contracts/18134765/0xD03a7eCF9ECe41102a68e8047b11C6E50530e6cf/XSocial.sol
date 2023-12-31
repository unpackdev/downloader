// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

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

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IXSocial is IERC20 {
    event Snapshot(uint256 epoch, uint256 rewards, address indexed from);
    event Swapped(uint256 eth, uint256 social);
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Claimed(address indexed user, uint256 reward);
    event Reinvestment(address indexed user, bool status);

    // ========== State Changing Functions ==========
    // Deposit (stake) social tokens and get Xsocial tokens of the same amount in return
    function deposit(uint256 _amount) external;

    // Withdraw (unstake) social tokens and get Xsocial tokens back
    function withdraw(uint256 _amount) external;

    // Claim pending reward
    function claimReward() external;

    // Snapshot the current epoch and distribute rewards (ETH sent in msg.value)
    function snapshot() external payable;

    // Switch Autocompounding on/off
    function toggleReinvesting() external;

    // Get ETH from the contract
    function rescueETH(uint256 _weiAmount) external;

    // Get ERC20 from the contract
    function rescueERC20(address _tokenAdd, uint256 _amount) external;

    // ========== View functions ==========
    // Get pending rewards
    function calculateRewardForUser(address user) external view returns (uint256);

    // Get auto-compounding status
    function isReinvesting(address user) external view returns (bool);

    // Total rewards injected, - this is only for distribution
    function totalRewards() external view returns (uint256);

    // Current epoch ordinal number, starts from 0 and increases by 1 after each snapshot (by default every 24 hours)
    function currentEpoch() external view returns (uint256);
}

/// @title social Bot Staking Contract
/// @notice This contract allow users to stake social tokens and earn rewards from the fees generated by the platform

contract XSocial is IXSocial, ERC20("Stake SocialFi", "xSOCIAL"), Ownable, ReentrancyGuard {

    IERC20 public constant socialToken = IERC20(0x40D07B808891133C2F07FD35292c8281bc226E5E); // SOCIALFI Token Address
    IUniswapV2Router02 public constant uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    uint256 public epochDuration = 1 days;

    uint256 public minimumStake = 40000 * 1e18; // 0.4%
    // Staking time lock, 5 days by default
    uint256 public timeLock = 3 days;
    // Total rewards injected
    uint256 public totalRewards;

    // Snapshot of the epoch, generated by the snapshot(), used to calculate rewards
    struct EpochInfo {
        // Snapshot time
        uint256 timestamp;
        // Rewards injected
        uint256 rewards;
        // Total deposited snap
        uint256 supply;
        // $social swapped for rewards for re-investors
        uint256 social;
        // This is used for aligning with the user deposits/withdrawals during epoch to adjust totalsupply
        uint256 deposited;
        uint256 withdrawn;
    }

    uint256 public currentEpoch;
    mapping(uint256 => EpochInfo) public epochInfo;

    // User info, there's also a balance of xsocial on the ERC20 super contract
    struct UserInfo {
        //epoch => total amount deposited during the epoch
        mapping(uint256 => uint256) depositedInEpoch;
        mapping(uint256 => uint256) withdrawnInEpoch;
        mapping(uint256 => bool) isReinvestingOnForEpoch;
        // a starting epoch for reward calculation for user - either last claimed or first deposit
        uint256 lastEpochClaimedOrReinvested;
        uint256 firstDeposit;
    }

    mapping(address => UserInfo) public userInfo;

    // That's for enumerating re-investors because we have to iterate over them to buy social for rewards generated
    uint256 public reInvestorsCount;
    mapping(address => uint256) public reInvestorsIndex;
    mapping(uint256 => address) public reInvestors;

    // ========== Configuration ==========
    constructor() ReentrancyGuard()  {
    }

    function setEpochDuration(uint256 _newEpoch) public onlyOwner {
        epochDuration = _newEpoch;
    }

    function setMinimumStake(uint256 _minimumStake) public onlyOwner {
        minimumStake = _minimumStake;
    }

    function setTimeLock(uint256 _timeLock) public onlyOwner {
        timeLock = _timeLock;
    }

    // ========== State changing ==========

    function deposit(uint256 _amount) public nonReentrant {
        require(_amount + balanceOf(msg.sender) >= minimumStake, "Minimum deposit passed");
        require(socialToken.transferFrom(msg.sender, address(this), _amount), "Transfer failed");

        if (userInfo[msg.sender].firstDeposit == 0) {
            userInfo[msg.sender].firstDeposit = block.timestamp;
        }
        _updateStake(msg.sender, _amount, true);

        emit Deposited(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) public nonReentrant {
        require(balanceOf(msg.sender) >= _amount, "Insufficient balance");
        require(userInfo[msg.sender].firstDeposit + timeLock < block.timestamp, "Too early to withdraw");

        _updateStake(msg.sender, _amount, false);

        require(socialToken.transfer(msg.sender, _amount), "Transfer failed");

        emit Withdrawn(msg.sender, _amount);
    }

    function claimReward() public nonReentrant {
        require(currentEpoch > 1, "No rewards have been distributed yet");
//        uint256 lastSnapshotTime = epochInfo[currentEpoch - 1].timestamp;
//        require(lastSnapshotTime + epochDuration <= block.timestamp, "Too early to calculate rewards");
         require (!(reInvestorsIndex[msg.sender] > 0), "Auto-compounding is enabled");

        uint256 reward = calculateRewardForUser(msg.sender);
        require(reward > 0, "No reward available");
        require(address(this).balance >= reward, "Insufficient contract balance to transfer reward");
        payable(msg.sender).transfer(reward);
        userInfo[msg.sender].lastEpochClaimedOrReinvested = currentEpoch - 1;
        emit Claimed(msg.sender, reward);
    }

    // we need it to be only owner to keep epochs precise
    function snapshot() public payable nonReentrant onlyOwner {
        require(msg.value > 0, "ETH amount must be greater than 0");
        uint256 lastSnapshotTime = 0;
        if (currentEpoch > 0) {
            lastSnapshotTime = epochInfo[currentEpoch - 1].timestamp;
            require(block.timestamp >= lastSnapshotTime + epochDuration - 5 minutes, "Too early for a new snapshot");
        }
        totalRewards += msg.value;



        epochInfo[currentEpoch].rewards = msg.value;
        epochInfo[currentEpoch].timestamp = block.timestamp;
        epochInfo[currentEpoch].supply = totalSupply();
        // swap ETH for autocompounding


        uint256 ethToSell = 0;
        uint256[] memory stakersRewarsInEpoch = new uint256[](reInvestorsCount + 1);
        for (uint256 i = 1; i <= reInvestorsCount; i++) {
            address user = reInvestors[i];
            userInfo[user].isReinvestingOnForEpoch[currentEpoch] = true;

            stakersRewarsInEpoch[i] = _calculateReward(user, true);
            ethToSell += stakersRewarsInEpoch[i];
            if (ethToSell > 0) {
                userInfo[user].lastEpochClaimedOrReinvested = currentEpoch;
            }
        }
        uint256 xsocialToMintTotal = 0;

        if (ethToSell > 0) {
            xsocialToMintTotal = _swapEthForsocial(ethToSell);
            epochInfo[currentEpoch].social = xsocialToMintTotal;

            //now updating staking balances
            for (uint256 i = 1; i <= reInvestorsCount; i++) {

                uint256 xsocialToMint = stakersRewarsInEpoch[i] * xsocialToMintTotal / ethToSell;
                _updateStake(msg.sender, xsocialToMint, true);
            }
        }
        emit Snapshot(currentEpoch, msg.value, msg.sender);
        currentEpoch++;
    }


    function toggleReinvesting() public {
        bool currentStatus = reInvestorsIndex[msg.sender] > 0;
        if (!currentStatus) {
            // Add re-investor to the renumeration
            if (reInvestorsIndex[msg.sender] == 0) {
                reInvestorsCount++;
                reInvestorsIndex[msg.sender] = reInvestorsCount;
                reInvestors[reInvestorsCount] = msg.sender;
                userInfo[msg.sender].isReinvestingOnForEpoch[currentEpoch] = true;
            }
        }
        else {
            // Remove re-investor from the renumeration
            if (reInvestorsIndex[msg.sender] != 0) {
                uint256 index = reInvestorsIndex[msg.sender];
                address lastReinvestor = reInvestors[reInvestorsCount];

                // Swap the msg.sender to remove with the last msg.sender
                reInvestors[index] = lastReinvestor;
                reInvestorsIndex[lastReinvestor] = index;

                // Remove the last msg.sender and update count
                delete reInvestors[reInvestorsCount];
                delete reInvestorsIndex[msg.sender];
                reInvestorsCount--;
                userInfo[msg.sender].isReinvestingOnForEpoch[currentEpoch] = false;
            }
        }
        emit Reinvestment(msg.sender, !currentStatus);
    }


    function rescueETH(uint256 _weiAmount) external {
        payable(owner()).transfer(_weiAmount);
    }

    function rescueERC20(address _tokenAdd, uint256 _amount) external {
        IERC20(_tokenAdd).transfer(owner(), _amount);
    }

    // ========== View functions ==========

    function getPendingReward() public view returns (uint256) {
        return calculateRewardForUser(msg.sender);
    }

    function calculateRewardForUser(address user) public view returns (uint256) {
        return _calculateReward(user, false);
    }

     function isReinvesting(address user) external view returns (bool) {
        return reInvestorsIndex[user] > 0;
    }

    // ========== Internal functions ==========

    function _updateStake(address _user, uint256 _amount, bool _isDeposit) internal {
        if (_isDeposit) {
            userInfo[_user].depositedInEpoch[currentEpoch] += _amount;
            epochInfo[currentEpoch].deposited += _amount;
            _mint(_user, _amount);
        } else {
            userInfo[_user].withdrawnInEpoch[currentEpoch] += _amount;
            epochInfo[currentEpoch].withdrawn += _amount;
            _burn(_user, _amount);
        }
    }


    function _swapEthForsocial(uint256 _ethAmount) internal returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = address(socialToken);

        // 15 seeconds from the current block time
        uint256 deadline = block.timestamp + 15;

        // Swap and return the amount of social tokens received
        uint[] memory amounts = uniswapRouter.swapExactETHForTokens{value: _ethAmount}(
            0, // Accept any amount of social
            path,
            address(this),
            deadline
        );
        emit Swapped(_ethAmount, amounts[1]);
        // Return the amount of social tokens received
        return amounts[1];
    }

// Mock function for demonstration purposes. In reality, you'd interact with a decentralized exchange contract here.
    function _calculateReward(address _user, bool _isForReinvestment) internal view returns (uint256) {

        uint256 reward = 0;
        if (currentEpoch < 1) {
            return 0;
        }
        uint256 userBalanceInEpoch = balanceOf(_user);
        uint256 i = currentEpoch;
        while (i >= userInfo[_user].lastEpochClaimedOrReinvested && i <= currentEpoch) {
            uint256 supplyInEpoch = epochInfo[i].supply;
            uint256 epochReward = supplyInEpoch == 0 || i >= currentEpoch - 1 ? 0 :
                userBalanceInEpoch * epochInfo[i].rewards / supplyInEpoch;


            if (epochReward > 0 &&
                (_isForReinvestment && reInvestorsIndex[_user] > 0 ||
                    !_isForReinvestment && !userInfo[_user].isReinvestingOnForEpoch[i])) {
                reward += epochReward;

            }


            if (i == 0) {
                break;
            }
            userBalanceInEpoch -= userInfo[_user].depositedInEpoch[i];
            userBalanceInEpoch += userInfo[_user].withdrawnInEpoch[i];
            i--;
        }
        return reward;
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 _amount) internal override {
        super._beforeTokenTransfer(_from, _to, _amount);
        require(_from == address(0) || _to == address(0), "Only stake or unstake");
    }

    receive() external payable {}

}