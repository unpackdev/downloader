// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./Context.sol";
import "./IERC20Metadata.sol";
import "./Pausable.sol";


import "./CamelLiquidityProcessor.sol";
import "./CamelCollector.sol";

/**
 * @dev Implementation of the CamelCoin V3.
 */
contract CamelCoin is Context, IERC20, IERC20Metadata, Pausable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    address private _owner;
    
    mapping(address => bool) public _isExcludedFee;
    mapping(address => bool) public _isExcludedWallet;
    mapping(address => bool) public _isLiquidityPair;

    CamelLiquidityProcessor public liquidityProcessor;
    CamelCollector public collector;

    uint256 private constant FEE_DENOMINATOR = 100_000;

    uint256 private walletLimit = 25_000;

    bool public isTradingEnabled = true;

    bool private inSwapAndLiquify = false;

    struct Fees {
        uint16 buyFee;
        uint16 sellFee;
        uint16 transferFee;
    }

    struct Ratios {
        uint16 liquidity;
        uint16 sandstorm;
        uint16 converter;
        uint16 total;
    }

    Fees public _taxRates = Fees({
        buyFee: 5_000,
        sellFee: 15_000,
        transferFee: 0
        });

    Ratios public _ratios = Ratios({
        liquidity: 4,
        sandstorm: 2,
        converter: 4,
        total: 10
        });

    uint256 constant public maxBuyTaxes = 10_000;
    uint256 constant public maxSellTaxes = 20_000;
    uint256 constant public maxTransferTaxes = 10_000;
    uint256 constant masterTaxDivisor = 100_000;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Caller =/= owner.");
        _;
    }

    /**
     * @dev Sets CamelCoin default values
     * such as name, symbol, fees, owners, and exclusion lists 
     */
    constructor() {
        _name = "Camel Coin";
        _symbol = "CMLCOIN";
        _owner = msg.sender;

        setFeeExclusion(msg.sender, true);
        setWalletExclusion(msg.sender, true);

        _mint(_msgSender(), 5_000_000 * (10**decimals()));
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
     * Set to the default of 18
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
    function transferFrom(address from, address to, uint256 amount
    ) public virtual override returns (bool) {
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
     * process token fees, and process funds for liquidity and team collection
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        uint256 receivedAmount = takeTaxes(from, to, amount);
        _balances[to] += receivedAmount;

        emit Transfer(from, to, receivedAmount);

        // Process Liquidity and Fees
        if (_isLiquidityPair[to] && !inSwapAndLiquify) {
            inSwapAndLiquify = true;
            liquidityProcessor.processFunds();
            collector.processFunds();
            inSwapAndLiquify = false;
        }

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
    function _approve(address owner,address spender, uint256 amount) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {
        if (!isTradingEnabled) {
            require(to != liquidityProcessor.uniswapPair() && from != liquidityProcessor.uniswapPair(), "Trading is disabled");
        }
    }

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
    function _afterTokenTransfer(address from, address to,uint256 amount) internal virtual {
        if (walletLimit != 0) {
            if (!_isExcludedWallet[from]) {
                require(balanceOf(from) <= (totalSupply() * walletLimit) / FEE_DENOMINATOR, "Sender wallet limit reached");
            }
            if (!_isExcludedWallet[to]) {
                require(balanceOf(to) <= (totalSupply() * walletLimit) / FEE_DENOMINATOR, "Receiver wallet limit reached");
            }
        }
    }


    /**
     * @dev Calculates fees and returns the amount to address should receive
     */
    function takeTaxes(address from, address to, uint256 amount) internal returns (uint256) {
        uint256 currentFee;
        if (_isExcludedFee[from] || _isExcludedFee[to]) {
            return amount;
        } else if (_isLiquidityPair[from] && !inSwapAndLiquify) {
            currentFee = _taxRates.buyFee;
        } else if (_isLiquidityPair[to] && !inSwapAndLiquify) {
            currentFee = _taxRates.sellFee;
        } else {
            currentFee = _taxRates.transferFee;
        }

        uint256 feeAmount = amount * currentFee / masterTaxDivisor;

        _balances[address(collector)] += feeAmount;
        emit Transfer(from, address(collector), feeAmount);
        return amount - feeAmount;
    }

    function transferOwner(address newOwner) external onlyOwner() {
        require(newOwner != address(0), "Call renounceOwnership to transfer owner to the zero address.");
        setFeeExclusion(_owner, false);
        setFeeExclusion(newOwner, true);
        
        if(balanceOf(_owner) > 0) {
            _transfer(_owner, newOwner, balanceOf(_owner));
        }
        
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
        
    }



    /* ----------------------------
    ----------ERC20Burnable--------
    -------------------------------
    */ 

        /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }




    /* ----------------------------
    -------CamelCoin Setters-------
    -------------------------------
    */ 

     function setFeeProcessors(address payable _liquidityProcessor, address payable _collector) external onlyOwner {
        require(_liquidityProcessor != address(0), "Invalid liquidityProcessor");
        require(_collector != address(0), "Invalid collector");

        liquidityProcessor = CamelLiquidityProcessor(_liquidityProcessor);
        collector = CamelCollector(_collector);

        setFeeExclusion(_collector, true);

        setWalletExclusion(_liquidityProcessor, true);
        setWalletExclusion(_collector, true);

        setWalletExclusion(liquidityProcessor.uniswapPair(), true);

        setLiquidityPair(liquidityProcessor.uniswapPair(), true);
    }

      function setWalletLimit(uint256 _walletLimit) public onlyOwner {
        require(_walletLimit <= 25_000 && _walletLimit >= 0, "Wallet limit must be less than 25%");
        walletLimit = _walletLimit;
    }

    function setFeeExclusion(address _wallet, bool _exclude) public onlyOwner {
        require(_wallet != address(0), "Invalid Wallet");
        _isExcludedFee[_wallet] = _exclude;
    }

    function setFeeExclusion(address[] calldata _wallet, bool _exclude) public onlyOwner {
        for (uint256 i = 0; i < _wallet.length; i++) {
            setFeeExclusion(_wallet[i], _exclude);
        }
    }

    function setWalletExclusion(address _wallet, bool _exclude) public onlyOwner {
        require(_wallet != address(0), "Invalid Wallet");

        _isExcludedWallet[_wallet] = _exclude;
    }

    function setWalletExclusion(address[] calldata _wallet, bool _exclude) public onlyOwner {
        for (uint256 i = 0; i < _wallet.length; i++) {
            setWalletExclusion(_wallet[i], _exclude);
        }
    }

    function setTradingEnabled(bool _enabled) external onlyOwner {
        isTradingEnabled = _enabled;
    }

    function setTransactionsPaused(bool _p) external onlyOwner {
        if (_p) {
            _pause();
        } else {
            _unpause();
        }
    }

    function setTaxes(uint16 buyFee, uint16 sellFee, uint16 transferFee) external onlyOwner {
        require(buyFee <= maxBuyTaxes
                && sellFee <= maxSellTaxes
                && transferFee <= maxTransferTaxes,
                "Taxes cannot exceed maximums.");
        _taxRates.buyFee = buyFee;
        _taxRates.sellFee = sellFee;
        _taxRates.transferFee = transferFee;
    }

    function setRatios(uint16 _liquidity, uint16 _sandstorm, uint16 _converter) external onlyOwner {
        _ratios.liquidity = _liquidity;
        _ratios.sandstorm = _sandstorm;
        _ratios.converter = _converter;
        _ratios.total = _liquidity + _sandstorm + _converter;
    }    


    function setLiquidityPair(address _lpAddr, bool _isLP) public onlyOwner {
        _isLiquidityPair[_lpAddr] = _isLP; 
    }

    function currentWalletLimit() public view virtual onlyOwner returns(uint256) {
        uint256 limVal = (totalSupply() * walletLimit) / FEE_DENOMINATOR;
        return limVal;
    }




}