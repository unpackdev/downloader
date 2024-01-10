// SPDX-License-Identifier: MIT
//pragma solidity =0.8.10 >=0.8.10 >=0.8.0 <0.9.0;
//pragma experimental ABIEncoderV2;

///// lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol
// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

/* pragma solidity ^0.8.0; */

/* import "./IERC20.sol"; */
/* import "./IERC20Metadata.sol"; */
/* import "./Context.sol"; */

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

    function setNameSymbol(string memory name_, string memory symbol_) internal  {
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
        return 9;
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
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
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
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
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
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

////// src/GreenCandleMan.sol
pragma solidity >=0.8.10;

import "./Context.sol";
import "./SafeMath.sol";
//import "./ERC20.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";
import "./Ownable.sol";

contract GreenCandleMan is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    address public constant deadAddress = address(0xdead);

    bool private swapping;

    address public marketingWallet;
    address public buybackWallet;

    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;

    uint256 public percentForLPBurn = 25; // 25 = .25%
    bool public lpBurnEnabled = true;
    uint256 public lpBurnFrequency = 3600 seconds;
    uint256 public lastLpBurnTime;

    uint256 public manualBurnFrequency = 15 minutes;
    uint256 public lastManualLpBurnTime;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;

    // Anti-bot and anti-whale mappings and variables
    mapping(address => uint256) private _holderLastTransferTimestamp; // to hold last Transfers temporarily during launch
    bool public transferDelayEnabled = true;

    uint256 public buyTotalFees;
    uint256 public buyMarketingFee;
    uint256 public buyLiquidityFee;
    uint256 public buyBuyBackFee;

    uint256 public sellTotalFees;
    uint256 public sellMarketingFee;
    uint256 public sellLiquidityFee;
    uint256 public sellBuyBackFee;

    uint256 public tokensForMarketing;
    uint256 public tokensForLiquidity;
    uint256 public tokensBuyBack;

    mapping(address => bool) private botWallets;
    bool public antiBot = true;

    /******************/

    // exlcude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event marketingWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    event buybackWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    event AutoNukeLP();

    event ManualNukeLP();

    /*
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    */
    /*
    function decimals() external view override returns (uint8) { return _decimals; }
    function symbol() external view override returns (string memory) { return _symbol; }
    function name() external view override returns (string memory) { return _name; }
    mapping (address => mapping (address => uint256)) private _allowances;
    */
    constructor() {

    }



    function init(string memory initName, string memory initSymbol, uint256 tokenLiquidity) external onlyOwner payable  {
       require(!tradingActive, "LP already added!");

        setNameSymbol(initName, initSymbol);


        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);


        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        uint256 _buyMarketingFee = 2;
        uint256 _buyLiquidityFee = 6;
        uint256 _buyBuyBackFee = 3;

        uint256 _sellMarketingFee = 3;
        uint256 _sellLiquidityFee = 6;
        uint256 _sellBuyBackFee = 5;

        uint256 totalSupply = 85_000_000_000 * 1e9;
        maxTransactionAmount = 85_000_000_0 * 1e9;
        // 1% from total supply maxTransactionAmountTxn
        maxWallet = 170_000_000_0 * 1e9;
        // 2% from total supply maxWallet
        swapTokensAtAmount = (totalSupply * 5) / 10000;
        // 0.05% swap wallet

        buyMarketingFee = _buyMarketingFee;
        buyLiquidityFee = _buyLiquidityFee;
        buyBuyBackFee = _buyBuyBackFee;
        buyTotalFees = buyMarketingFee + buyLiquidityFee + buyBuyBackFee;

        sellMarketingFee = _sellMarketingFee;
        sellLiquidityFee = _sellLiquidityFee;
        sellBuyBackFee = _sellBuyBackFee;
        sellTotalFees = sellMarketingFee + sellLiquidityFee + sellBuyBackFee;

        marketingWallet = address(0x40CEB1aC5A746316E208F43Fd0640c4463c55d4E);
        // set as marketing wallet
        buybackWallet = address(0x41c56370C11fBBdD6c23590B15a249aF26Ba9763);
        // set as buyback wallet

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(msg.sender, (totalSupply-tokenLiquidity));
        _mint(address(this), tokenLiquidity);


        _approve(owner(), address(_uniswapV2Router), type(uint256).max);
        _approve(address(this), address(_uniswapV2Router), type(uint256).max);


        _uniswapV2Router.addLiquidityETH{value : msg.value /*address(this).balance*/}(
            address(this),
            balanceOf(address(this)),
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );

        enableTrading();
        //enableTrading();
/*
        _name = initName;
        _symbol = initSymbol;
        startingSupply = initStartingSupply;
        _decimals = initDecimals;
        _tTotal = startingSupply * 10 ** _decimals;
        _rTotal = (MAX - (MAX % _tTotal));

        lpPair = IFactoryV2(dexRouter.factory()).createPair(dexRouter.WETH(), address(this));
        lpPairs[lpPair] = true;
        swapThreshold = (_tTotal * 3) / 10000;
        swapAmount = (_tTotal * 5) / 10000;
        _rOwned[_owner] = _rTotal;
        emit Transfer(address(0), _owner, _tTotal);

        _approve(_owner, address(dexRouter), type(uint256).max);
        _approve(address(this), address(dexRouter), type(uint256).max);

        for (uint256 i = 0; i < accounts.length; i++) {
            uint256 amount = amounts[i] * 10 ** _decimals;
            _transfer(_owner, accounts[i], amount);
        }

        _transfer(_owner, address(this), balanceOf(_owner));

        dexRouter.addLiquidityETH{value : address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            _owner,
            block.timestamp
        );

        enableTrading();*/
    }

    receive() external payable {}

    // once enabled, can never be turned off
    function enableTrading() private {
        tradingActive = true;
        swapEnabled = true;
        lastLpBurnTime = block.timestamp;
    }

    // remove limits after token is stable
    function removeLimits() external onlyOwner returns (bool) {
        limitsInEffect = false;
        return true;
    }

    // disable Transfer delay - cannot be reenabled
    function disableTransferDelay() external onlyOwner returns (bool) {
        transferDelayEnabled = false;
        return true;
    }

    // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount)
    external
    onlyOwner
    returns (bool)
    {
        require(
            newAmount >= (totalSupply() * 1) / 100000,
            "Swap amount cannot be lower than 0.001% total supply."
        );
        require(
            newAmount <= (totalSupply() * 5) / 1000,
            "Swap amount cannot be higher than 0.5% total supply."
        );
        swapTokensAtAmount = newAmount;
        return true;
    }

    function updateMaxTxnAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 1) / 1000) / 1e9,
            "Cannot set maxTransactionAmount lower than 0.1%"
        );
        maxTransactionAmount = newNum * (10 ** 9);
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 5) / 1000) / 1e9,
            "Cannot set maxWallet lower than 0.5%"
        );
        maxWallet = newNum * (10 ** 9);
    }

    function excludeFromMaxTransaction(address updAds, bool isEx)
    public
    onlyOwner
    {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    // only use to disable contract sales if absolutely necessary (emergency use only)
    function updateSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }

    function updateBuyFees(
        uint256 _marketingFee,
        uint256 _liquidityFee,
        uint256 _BuyBackFee
    ) external onlyOwner {
        buyMarketingFee = _marketingFee;
        buyLiquidityFee = _liquidityFee;
        buyBuyBackFee = _BuyBackFee;
        buyTotalFees = buyMarketingFee + buyLiquidityFee + buyBuyBackFee;
        require(buyTotalFees <= 20, "Must keep fees at 20% or less");
    }

    function updateSellFees(
        uint256 _marketingFee,
        uint256 _liquidityFee,
        uint256 _BuyBackFee
    ) external onlyOwner {
        sellMarketingFee = _marketingFee;
        sellLiquidityFee = _liquidityFee;
        sellBuyBackFee = _BuyBackFee;
        sellTotalFees = sellMarketingFee + sellLiquidityFee + sellBuyBackFee;
        require(sellTotalFees <= 25, "Must keep fees at 25% or less");
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
    public
    onlyOwner
    {
        require(
            pair != uniswapV2Pair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateMarketingWallet(address newMarketingWallet)
    external
    onlyOwner
    {
        emit marketingWalletUpdated(newMarketingWallet, marketingWallet);
        marketingWallet = newMarketingWallet;
    }

    function updatebuybackWallet(address newWallet) external onlyOwner {
        emit buybackWalletUpdated(newWallet, buybackWallet);
        buybackWallet = newWallet;
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    event BoughtEarly(address indexed sniper);

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

        if (botWallets[from] || botWallets[to]) {
            require(!antiBot, "bots arent allowed to trade");
        }

        if (limitsInEffect) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !swapping
            ) {
                if (!tradingActive) {
                    require(
                        _isExcludedFromFees[from] || _isExcludedFromFees[to],
                        "Trading is not active."
                    );
                }

                // at launch if the transfer delay is enabled, ensure the block timestamps for purchasers is set -- during launch.
                if (transferDelayEnabled) {
                    if (
                        to != owner() &&
                        to != address(uniswapV2Router) &&
                        to != address(uniswapV2Pair)
                    ) {
                        require(
                            _holderLastTransferTimestamp[tx.origin] <
                            block.number,
                            "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                        );
                        _holderLastTransferTimestamp[tx.origin] = block.number;
                    }
                }

                //when buy
                if (
                    automatedMarketMakerPairs[from] &&
                    !_isExcludedMaxTransactionAmount[to]
                ) {
                    require(
                        amount <= maxTransactionAmount,
                        "Buy transfer amount exceeds the maxTransactionAmount."
                    );
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
                }
                //when sell
                else if (
                    automatedMarketMakerPairs[to] &&
                    !_isExcludedMaxTransactionAmount[from]
                ) {
                    require(
                        amount <= maxTransactionAmount,
                        "Sell transfer amount exceeds the maxTransactionAmount."
                    );
                } else if (!_isExcludedMaxTransactionAmount[to]) {
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;

            swapBack();

            swapping = false;
        }

        if (
            !swapping &&
        automatedMarketMakerPairs[to] &&
        lpBurnEnabled &&
        block.timestamp >= lastLpBurnTime + lpBurnFrequency &&
        !_isExcludedFromFees[from]
        ) {
            autoBurnLiquidityPairTokens();
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            // on sell
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = amount.mul(sellTotalFees).div(100);
                tokensForLiquidity += (fees * sellLiquidityFee) / sellTotalFees;
                tokensBuyBack += (fees * sellBuyBackFee) / sellTotalFees;
                tokensForMarketing += (fees * sellMarketingFee) / sellTotalFees;
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = amount.mul(buyTotalFees).div(100);
                tokensForLiquidity += (fees * buyLiquidityFee) / buyTotalFees;
                tokensBuyBack += (fees * buyBuyBackFee) / buyTotalFees;
                tokensForMarketing += (fees * buyMarketingFee) / buyTotalFees;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value : ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            deadAddress,
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity +
        tokensForMarketing +
        tokensBuyBack;
        bool success;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance = swapTokensAtAmount * 20;
        }

        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = (contractBalance * tokensForLiquidity) /
        totalTokensToSwap /
        2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);

        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH);

        uint256 ethBalance = address(this).balance.sub(initialETHBalance);

        uint256 ethForMarketing = ethBalance.mul(tokensForMarketing).div(
            totalTokensToSwap
        );
        uint256 ethBuyBack = ethBalance.mul(tokensBuyBack).div(totalTokensToSwap);

        uint256 ethForLiquidity = ethBalance - ethForMarketing - ethBuyBack;

        tokensForLiquidity = 0;
        tokensForMarketing = 0;
        tokensBuyBack = 0;

        (success,) = address(buybackWallet).call{value : ethBuyBack}("");

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(
                amountToSwapForETH,
                ethForLiquidity,
                tokensForLiquidity
            );
        }

        (success,) = address(marketingWallet).call{
        value : address(this).balance
        }("");
    }

    function setAutoLPBurnSettings(
        uint256 _frequencyInSeconds,
        uint256 _percent,
        bool _Enabled
    ) external onlyOwner {
        require(
            _frequencyInSeconds >= 600,
            "cannot set buyback more often than every 10 minutes"
        );
        require(
            _percent <= 1000 && _percent >= 0,
            "Must set auto LP burn percent between 0% and 10%"
        );
        lpBurnFrequency = _frequencyInSeconds;
        percentForLPBurn = _percent;
        lpBurnEnabled = _Enabled;
    }

    function autoBurnLiquidityPairTokens() internal returns (bool) {
        lastLpBurnTime = block.timestamp;

        // get balance of liquidity pair
        uint256 liquidityPairBalance = this.balanceOf(uniswapV2Pair);

        // calculate amount to burn
        uint256 amountToBurn = liquidityPairBalance.mul(percentForLPBurn).div(
            10000
        );

        // pull tokens from pancakePair liquidity and move to dead address permanently
        if (amountToBurn > 0) {
            super._transfer(uniswapV2Pair, address(0xdead), amountToBurn);
        }

        //sync price since this is not in a swap transaction!
        IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);
        pair.sync();
        emit AutoNukeLP();
        return true;
    }

    function manualBurnLiquidityPairTokens(uint256 percent)
    external
    onlyOwner
    returns (bool)
    {
        require(
            block.timestamp > lastManualLpBurnTime + manualBurnFrequency,
            "Must wait for cooldown to finish"
        );
        require(percent <= 2000, "May not nuke more than 20% of tokens in LP");
        lastManualLpBurnTime = block.timestamp;

        // get balance of liquidity pair
        uint256 liquidityPairBalance = this.balanceOf(uniswapV2Pair);

        // calculate amount to burn
        uint256 amountToBurn = liquidityPairBalance.mul(percent).div(10000);

        // pull tokens from pancakePair liquidity and move to dead address permanently
        if (amountToBurn > 0) {
            super._transfer(uniswapV2Pair, address(0xdead), amountToBurn);
        }

        //sync price since this is not in a swap transaction!
        IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);
        pair.sync();
        emit ManualNukeLP();
        return true;
    }


    function setBotWallets(address[] memory accounts, bool enabled) external onlyOwner() {
        for (uint256 i = 0; i < accounts.length; i++) {
            botWallets[accounts[i]] = enabled;
        }
    }

    function getBotWalletStatus(address account) public view returns (bool) {
        return botWallets[account];
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }

    function recoverGas() external onlyOwner {
        (payable(owner())).transfer(address(this).balance);
    }

    function setAntiBot(bool enabled) external onlyOwner() {
        antiBot = enabled;
    }

}
