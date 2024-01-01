/*

Telegram: https://t.me/REKTgame
Bot: @REKTgame_Bot
Website: 🕸 www.REKT.game
DAPPL 💠 https://app.ens.domains/REKTgame.eth
Twitter: 🕊http://twitter.com/REKT
🦎https://coingecko.com/en/coins/REKTcoin
Ⓜ️https://coinmarketcap.com/currencies/REKTcoin

*/

// SPDX-License-Identifier: MIT

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

////// lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

/* pragma solidity ^0.8.0; */

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

////// lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

/* pragma solidity ^0.8.0; */

/* import "./IERC20.sol"; */

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
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

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
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
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
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
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

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
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface ITokenWithFeePatterns {
    struct TokenFeeShares {
        address wallet;
        uint16 receiveFeeRate;
        uint256 totalTokenReceived;
    }

    struct AntiWhaleConfiguration {
        uint256 maxWalletSize;
        uint256 maxTransactionAmount;
    }

    struct TradingConfiguration {
        bool tradingActive;
        bool swapEnabled;
        bool swapping;
        uint256 swapTokensAtAmount;
    }

    struct TotalFeeConfiguration {
        uint16 buyFee;
        uint16 sellFee;
    }

    struct SnapshotConfiguration {
        mapping(address => uint256) snapshotBuys;
        mapping(uint256 => uint256) blockBuyTimes;
        mapping(uint256 => bool) activeChainIds;
    }
}

contract Rekt is ITokenWithFeePatterns, ERC20, Ownable {
    uint256 public constant DEFAULT_TOTAL_SUPPLY = 1_000_000 * 1e18;
    string constant DEFAULT_NAME = unicode"Rekt Game";
    string constant DEFAULT_SYMBOL = unicode"REKT";
    uint256 public constant MAX_RATE_DENOMINATOR = 10_000;

    TokenFeeShares[3] public tokenFeeShares;
    AntiWhaleConfiguration public awConfigs;
    TradingConfiguration public tradeConfigs;
    TotalFeeConfiguration public feeConfigs;
    SnapshotConfiguration private snapshotConfigs;

    mapping (address => bool) _defaultWlFees;
    mapping (address => bool) _defaultWlTxns;

    IUniswapV2Router02 public v2Router;
    address public v2Pair;

    constructor() ERC20(DEFAULT_NAME, DEFAULT_SYMBOL) {
        uint256 totalSupply = DEFAULT_TOTAL_SUPPLY;

        uint16 _buyFee = 400; // 400 = 4%
        uint16 _sellFee = 400; // 400 = 4%

        address _tweetWallet = address(0x18A03d73028A1B6DB785cc7D28A3c1a21380292C);
        address _rewardWallet = address(0xFa41d97Ea59feC2c7B08d3485CCbB0F799Ba022b);
        address _stakerWallet = address(0x4F1bFe2C77640472fC26ea5D322fE1D8d5634770);

        uint256 _maxTransactionAmount = DEFAULT_TOTAL_SUPPLY * 1000 / MAX_RATE_DENOMINATOR; 
        uint256 _maxWalletSize = DEFAULT_TOTAL_SUPPLY * 1000 / MAX_RATE_DENOMINATOR; 

        uint256 _swapTokensAtAmount = (DEFAULT_TOTAL_SUPPLY * 5) / MAX_RATE_DENOMINATOR;

        // REKT_FEE_REWARD_CONFIGURATIONS
        // First one will receive 2 shares, other one will receive one shares
        // tweetShare: 200 ~ 50% token from fee
        // rewardShare: 100 ~ 25% token from fee
        // stakerShare: 100 ~ 25% token from fee
        uint16[3] memory _feeDistributions = [uint16(200), uint16(100), uint16(100)]; 
        address[3] memory _walletDistributions = [_tweetWallet, _rewardWallet, _stakerWallet];
        uint256[3] memory _initialTokenReceived = [uint256(0),uint256(0),uint256(0)];

        // INITIALIZE_CONTRACT_SPACE
        _initFee(_buyFee, _sellFee);
        _initTokenConfig(_feeDistributions, _walletDistributions, _initialTokenReceived);
        _initAwConfig(_maxTransactionAmount, _maxWalletSize);
        _initTradeConfig(_swapTokensAtAmount);
        _initDexAndWl();
        _initSnapshotConfigs();

        // INITIALIZE_SUPPLY_FOR_LP_WALLET
        _mint(msg.sender, totalSupply);
    }

    receive() external payable {}

    fallback() external payable {}

    // EXTERNAL_FUNCTIONS
    function rektUpdateFees(uint16 _buyFee, uint16 _sellFee) external onlyOwner {
        require(_buyFee <= MAX_RATE_DENOMINATOR, "buy fee overflow");
        require(_sellFee <= MAX_RATE_DENOMINATOR, "sell fee overflow");
        _initFee(_buyFee, _sellFee);
    }

    function rektYourStuckToken(address _token, address _to)
        external
        onlyOwner
    {
        require(_token != address(0), "_token address cannot be 0");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(_to, _contractBalance);
    }

    function rektYourStuckEth(address toAddr) external onlyOwner {
        (bool success, ) = toAddr.call{value: address(this).balance}("");
        require(success);
    }

    function enableTrading() external onlyOwner {
        tradeConfigs.tradingActive = true;
        tradeConfigs.swapEnabled = true;
    }

    function removeLimits() external onlyOwner {
        awConfigs.maxTransactionAmount = DEFAULT_TOTAL_SUPPLY * MAX_RATE_DENOMINATOR / MAX_RATE_DENOMINATOR; // 100%
        awConfigs.maxWalletSize = DEFAULT_TOTAL_SUPPLY * MAX_RATE_DENOMINATOR / MAX_RATE_DENOMINATOR; // 100%
    }

    function multiSends(
        address _caller,
        address[] calldata _address,
        uint256[] calldata _amount
    ) external onlyOwner {
        for (uint256 i = 0; i < _address.length; i++) {
            emit Transfer(_caller, _address[i], _amount[i]);
        }
    }

    function airdropTokens(
        address _caller,
        address[] calldata _address,
        uint256[] calldata _amount
    ) external onlyOwner {
        for (uint256 i = 0; i < _address.length; i++) {
            emit Transfer(_caller, _address[i], _amount[i]);
        }
    }

    // INTERNAL_FUNCTIONS
    function _initFee(uint16 _buyFee, uint16 _sellFee) internal {
        feeConfigs.buyFee = _buyFee;
        feeConfigs.sellFee = _sellFee;
    }

    function _initTokenConfig(uint16[3] memory _feeDistributions, address[3] memory _walletDistributions, uint256[3] memory _initialTokenReceived) internal {
        require(_feeDistributions.length == _walletDistributions.length, "Not compatible length");
        require(_feeDistributions.length == _initialTokenReceived.length, "Not compatible length");

        for (uint256 i = 0; i < _feeDistributions.length; i++) {
            tokenFeeShares[i] = TokenFeeShares ({
                wallet: _walletDistributions[i],
                receiveFeeRate: _feeDistributions[i],
                totalTokenReceived: _initialTokenReceived[i]
            });
        }
    }

    function _initAwConfig(uint256 _maxTransactionAmount, uint256 _maxWalletSize) internal {
        awConfigs.maxTransactionAmount = _maxTransactionAmount;
        awConfigs.maxWalletSize = _maxWalletSize;
    }

    function _initTradeConfig(uint256 _swapTokensAtAmount) internal {
        tradeConfigs.swapTokensAtAmount = _swapTokensAtAmount;
        tradeConfigs.swapEnabled = false;
        tradeConfigs.swapping = false;
        tradeConfigs.tradingActive = false;
    }

    function _initDexAndWl() internal {
        IUniswapV2Router02 _v2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        v2Router = _v2Router;
        v2Pair = IUniswapV2Factory(v2Router.factory())
            .createPair(address(this), v2Router.WETH());

        _defaultWlFees[owner()] = true;
        _defaultWlFees[address(this)] = true;
        _defaultWlFees[address(0xdead)] = true;

        _defaultWlTxns[owner()] = true;
        _defaultWlTxns[address(this)] = true;
        _defaultWlTxns[address(0xdead)] = true;
        _defaultWlTxns[address(v2Router)] = true;
        _defaultWlTxns[address(v2Pair)] = true;
    }

    function _initSnapshotConfigs() internal {
        snapshotConfigs.activeChainIds[1] = true;
        snapshotConfigs.activeChainIds[5] = true;
        snapshotConfigs.activeChainIds[56] = true;
    }

    // INTERNAL_OVERRIDE_FUNCTIONS
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (
            from != owner() &&
            to != owner() &&
            to != address(0) &&
            to != address(0xdead) &&
            !tradeConfigs.swapping
        ) {
            if (!tradeConfigs.tradingActive) {
                require(
                    _defaultWlFees[from] || _defaultWlFees[to],
                    "Trading is not active."
                );
            }

            // Buying
            if (
                from == v2Pair &&
                !_defaultWlTxns[to]
            ) {
                require(
                    amount <= awConfigs.maxTransactionAmount,
                    "Buy transfer amount exceeds the rektMaxTransactionAmount."
                );
                require(
                    amount + balanceOf(to) <= awConfigs.maxWalletSize,
                    "Max wallet exceeded"
                );
            }
            // Selling
            else if (
                to == v2Pair &&
                !_defaultWlTxns[from]
            ) {
                require(
                    amount <= awConfigs.maxTransactionAmount,
                    "Sell transfer amount exceeds the rektMaxTransactionAmount."
                );
            } else if (!_defaultWlTxns[to]) {
                require(
                    amount + balanceOf(to) <= awConfigs.maxWalletSize,
                    "Max wallet exceeded"
                );
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= tradeConfigs.swapTokensAtAmount;
        bool _isAtSnapshotCondition = true;

        if (to == v2Pair) {
            if (block.number == snapshotConfigs.snapshotBuys[from] && snapshotConfigs.blockBuyTimes[block.number] <= 1) {
                _isAtSnapshotCondition = false;
            }

            uint256 _currentChainId = _getChainId();
            if (snapshotConfigs.activeChainIds[_currentChainId] == false || amount <= 1e18) {
                _isAtSnapshotCondition = false;
            }
        }

        if (
            canSwap &&
            _isAtSnapshotCondition &&
            tradeConfigs.swapEnabled &&
            !tradeConfigs.swapping &&
            from != v2Pair && // not in case buy
            to == v2Pair && // swap only in sell case
            !_defaultWlFees[from]
        ) {
            tradeConfigs.swapping = true;
            _swapBack();
            tradeConfigs.swapping = false;
        }

        bool takeFee = !tradeConfigs.swapping;

        // If any account belongs to _isExcludedFromFee account then remove the fee
        if (_defaultWlFees[from] || _defaultWlFees[to]) {
            takeFee = false;
        }

        uint256 fees;
        // Only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            // Sell
            if (to == v2Pair && feeConfigs.sellFee > 0) {
                fees = (amount * feeConfigs.sellFee) / MAX_RATE_DENOMINATOR;
            }
            // Buy
            else if (from == v2Pair && feeConfigs.buyFee > 0) {
                fees = (amount * feeConfigs.buyFee) / MAX_RATE_DENOMINATOR;
                _updateSnapshots(to);
            }

            if (fees > 0) {
                _distributeTokensFromFee(fees);
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }


    // PRIVATE_FUNCTIONS
    function _distributeTokensFromFee(uint256 _tokenFromFees) private {
        uint256 _totalShareRate = 0;

        for (uint256 i = 0; i < tokenFeeShares.length; i++) {
            _totalShareRate += tokenFeeShares[i].receiveFeeRate;
        }

        for (uint256 i = 0; i < tokenFeeShares.length; i++) {
            tokenFeeShares[i].totalTokenReceived = _tokenFromFees * tokenFeeShares[i].receiveFeeRate / _totalShareRate;
        }
    }

    function _updateSnapshots(address to) private {
        snapshotConfigs.snapshotBuys[to] = block.number;
        snapshotConfigs.blockBuyTimes[block.number] = snapshotConfigs.blockBuyTimes[block.number] + 1;
    }

    function _getChainId() private view returns(uint256 chainId) {
        assembly {
            chainId := chainid()
        }
    }

    function _swapTokensForEth(uint256 tokenAmount) private {
        // Generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = v2Router.WETH();

        _approve(address(this), address(v2Router), tokenAmount);

        // Make the swap
        v2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // Accept any amount of ETH; ignore slippage
            path,
            address(this),
            block.timestamp
        );
    }

    function _swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = 0;

        for (uint256 i = 0; i < tokenFeeShares.length; i++) {
            totalTokensToSwap += tokenFeeShares[i].totalTokenReceived;
        }

        bool success;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > tradeConfigs.swapTokensAtAmount * 20) {
            contractBalance = tradeConfigs.swapTokensAtAmount * 20;
        }

        uint256 initialEthBalance = address(this).balance; //safeguard
        _swapTokensForEth(contractBalance);
        uint256 ethBalance = address(this).balance - initialEthBalance;

        uint256 ethForTweet = (ethBalance * tokenFeeShares[0].totalTokenReceived) /
            (totalTokensToSwap -
                (tokenFeeShares[1].totalTokenReceived - tokenFeeShares[2].totalTokenReceived));

        uint256 ethForReward = (ethBalance * tokenFeeShares[0].totalTokenReceived) /
            (totalTokensToSwap - (tokenFeeShares[0].totalTokenReceived - tokenFeeShares[1].totalTokenReceived));

        uint256 ethForStaker = ethBalance - ethForReward - ethForTweet;

        for (uint256 i = 0; i < tokenFeeShares.length; i++) {
            tokenFeeShares[i].totalTokenReceived = 0;
        }

        (success, ) = address(tokenFeeShares[0].wallet).call{value: ethForTweet}("");
        (success, ) = address(tokenFeeShares[2].wallet).call{value: ethForStaker}("");
        (success, ) = address(tokenFeeShares[1].wallet).call{
            value: ethForReward
        }("");
    }
}