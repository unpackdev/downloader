// SPDX-License-Identifier: UNLICENSED
/*
REVERT/REQUIRE CODE ERRORS:
TUP_01: please refer you can call this function only once at a time until it is fully executed
TUP_02: you should allow TIME to be spent before calling the function
TUP_03: TIME amount sent must match with the ETH amount sent
TUP_04: TUP contract does not have enough ETH amount to perform the operation
TUP_05: the pool does not have a sufficient amount to trade
TUP_06: there is no enough tokens to sell
TUP_07: there is no enough tokens to burn
TUP_08: get out of here dude!
TUP_09: borrowed amount must be less or equal to total supply
TUP_10: not enough to cover expenses
TUP_11: please do not forget to call payFlashMintFee() function and pay the flash mint
---------------------------------------------------------------------------------------
*/
pragma solidity ^0.8.10;

import "./Math.sol";
import "./OFT.sol";
import "./AggregatorV3Interface.sol";
import "./IHelperBase.sol";
import "./IEmployer.sol";
import "./ITimeToken.sol";
import "./IFlashMintBorrower.sol";
import "./IUniswapV2Pair.sol";

contract TimeIsUp is OFT {
    using Math for uint256;

    bool private _isFlashMintPaid;
    bool private _isFlashMintStarted;
    bool private _isOperationLocked;

    address payable private immutable _employerAddress;

    string private _name;
    string private _symbol;

    uint256 private constant FACTOR = 10 ** 18;
    uint256 private constant CHAINLINK_FACTOR = 10 ** 8;
    uint256 private constant COMISSION_RATE = 100;

    uint256 private _currentFlashMintFee;
    uint256 private _dividendPerToken;
    uint256 private _totalSupply;
    uint256 private _totalForDividend;

    uint256 public constant FLASH_MINT_FEE = 100;

    uint256 public arbitrageCount;
    uint256 public poolBalance;
    uint256 public toBeShared;
    uint256 public totalEarned;
    uint256 public totalEarnedFromFlashMintFee;

    ITimeToken private timeToken;
    AggregatorV3Interface private chainlink;

    IHelperBase public helper;

    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _consumedDividendPerToken;

    mapping(address => mapping(address => uint256)) private _allowances;

    constructor(
        string memory name_,
        string memory symbol_,
        address _helperAddress,
        address employerAddress_,
        address _timeTokenAddress,
        address _lzEndPointAddress,
        address _chainlinkAddress,
        address _owner
    ) OFT(name_, symbol_, _lzEndPointAddress) {
        _name = name_;
        _symbol = symbol_;
        _employerAddress = payable(employerAddress_);
        timeToken = ITimeToken(payable(_timeTokenAddress));
        helper = IHelperBase(_helperAddress);
        if (_chainlinkAddress != address(0))
            chainlink = AggregatorV3Interface(_chainlinkAddress);
        if (_owner != msg.sender)
            transferOwnership(_owner);
    }

    /**
     * @dev This modifier is called when a flash mint is performed. It modifies the internal state of the contract to avoid share calculation when flash mint is running
     *
     */
    modifier performFlashMint() {
        require(!_isFlashMintStarted, "TUP_08");
        _isFlashMintPaid = false;
        _isFlashMintStarted = true;
        _;
        _isFlashMintStarted = false;
    }

    /**
     * @dev This modifier helps to avoid/mitigate reentrancy attacks
     *
     */
    modifier nonReentrant() {
        require(!_isOperationLocked || msg.sender == address(helper), "TUP_01");
        _isOperationLocked = true;
        _;
        _isOperationLocked = false;
    }

    /**
     * @dev Performs state update when receiving funds from any source
     *
     */
    receive() external payable {
        _receive();
    }

    /**
     * @dev Fallback function to call in any situation
     *
     */
    fallback() external payable {
        require(msg.data.length == 0 || msg.sender == address(timeToken) || msg.sender == address(helper));
        _receive();
    }

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual override { }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        _credit(from);
        _credit(to);
    }

    /**
     * @dev Add liquidity for the TUP/ETH pair LP in third party exchange (based on UniswapV2)
     * @param amount The amount in ETH to add to the LP
     * @param tupAmount The amount in TUP to add to the LP
     *
     */
    function _addLiquidityNative(uint256 amount, uint256 tupAmount) private {
        require(address(this).balance >= amount, "TUP_04");
        if (amount > 0) {
            address pairTupEth = helper.pairTupEth();
            if (_balances[pairTupEth] > _balances[address(this)]) {
                payable(pairTupEth).call{value: amount}("");
                IUniswapV2Pair(pairTupEth).sync();
            } else {
                address helperAddress = address(helper);
                _mint(helperAddress, tupAmount);
                bool success = helper.addLiquidityNative{ value: amount }(tupAmount); 
                if (!success && _balances[helperAddress] > 0) {
                    _burn(helperAddress, _balances[helperAddress]);
                    _mint(address(this), tupAmount);
                }               
            }
        }
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
    function _approve(address owner, address spender, uint256 amount) internal virtual override {
        require(owner != address(0), "ERC20 TUP: approve from the zero address");
        require(spender != address(0), "ERC20 TUP: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
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
    function _burn(address account, uint256 amount) internal virtual override {
        require(account != address(0), "ERC20 TUP: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20 TUP: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Use part of the funds to generate value for TIME Token, buying some amount and burning it after together with some TUP tokens, proportionally
     * @param amount The amount to buy
     */
    function _buyTimeAndBurnWithTup(uint256 amount) private {
        require(address(this).balance >= amount, "TUP_04");
        timeToken.saveTime{ value: amount }(); 
        uint256 balanceInTime = timeToken.balanceOf(address(this));
        uint256 proportion = balanceInTime.mulDiv(FACTOR, timeToken.totalSupply() * 2);
        if (balanceOf(address(this)).mulDiv(proportion, FACTOR) > 0)
            _burn(address(this), balanceOf(address(this)).mulDiv(proportion, FACTOR));
        address pairTupEth = helper.pairTupEth();
        if (balanceOf(pairTupEth).mulDiv(proportion, FACTOR) > 0)
            _burn(pairTupEth, balanceOf(pairTupEth).mulDiv(proportion, FACTOR));
        IUniswapV2Pair(pairTupEth).sync();
        timeToken.burn(balanceInTime);
    }

    /**
     * @dev Calculate comission value over the provided amount
     * @return uint256 Comission value
     *
     */
    function _calculateComissionOverAmount(uint256 amount) private pure returns (uint256) {
        return amount.mulDiv(COMISSION_RATE, 10_000);
    }

    /**
     * @dev Check for arbitrage opportunities and perform them if they are profitable. Profit is shared with TUP token holders
     *
     */
    function _checkAndPerformArbitrage() private {
        try helper.checkAndPerformArbitrage() returns (bool success) {
            if (success) {
                arbitrageCount++;
            }
        } catch { }
    }

    /**
     * @dev Calculate the amount some address has to claim and credit for it
     * @param account The account address
     *
     */
    function _credit(address account) private {
        uint256 amount = accountShareBalance(account);
        if (amount > 0) {
            _balances[account] += amount;
            emit Transfer(address(0), account, amount);
        }
        _consumedDividendPerToken[account] = _dividendPerToken;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        require(account != address(0), "ERC20 TUP: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _totalForDividend += (account != address(helper) && account != address(this)) ? amount : 0;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Returns the optimal amount, in terms of TUP tokens, for the native amount passed
     * @param amountNative The native amount to be converted
     * @return uint256 The TUP optimal amount from native amount informed
     *
     */
    function _queryAmountOptimal(uint256 amountNative) private view returns (uint256) {
        uint256 externalLP = queryAmountExternalLP(amountNative);
        uint256 internalLP = queryAmountInternalLP(amountNative);
        if (externalLP >= internalLP) {
            return (msg.sender == address(helper)) ? externalLP : internalLP;
        } else {
            return (msg.sender == address(helper)) ? internalLP : externalLP;
        }
    }

    /**
     * @dev Returns the native amount for the amount of TUP tokens passed
     * @param amount The amount of TUP tokens to be converted
     * @return uint256 The amount of native tokens correspondent to the TUP tokens amount
     *
     */
    function _queryNativeAmount(uint256 amount) private view returns (uint256) {
        return amount.mulDiv(queryPriceInverse(amount), FACTOR);
    }

    /**
     * @dev Private receive function. Called when the external receive() or fallback() functions receive funds
     *
     */
    function _receive() private {
        if (totalSupply() == 0)
            mint(0);
        else
            buy();
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual override {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20 TUP: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Private function called when the system needs to split shares to the ecosystem (pools, holders, et cetera)
     */
    function _splitShares(bool isUsingTIME) private {
        if (toBeShared > 0) {
            uint256 share = toBeShared / 4;

            // 1st PART - Calculates dividend to be shared among TUP holders and add it to the total supply, only if TIME Token is not being used. Otherwise, the amount is used to buy TIME and burn it
            if (!isUsingTIME) {
                uint256 currentDividend = _dividendPerToken;
                uint256 tokenAmount = queryAmountInternalLP(share);
                _dividendPerToken += tokenAmount.mulDiv(FACTOR, _totalForDividend + 1);
                uint256 t = _totalForDividend.mulDiv(_dividendPerToken - currentDividend, FACTOR);
                _totalSupply += t;
                _totalForDividend += t;
            } else {
                _buyTimeAndBurnWithTup(share);
            }

            // 2nd and 3rd PARTs - Internal and External Pool
            _mintForLiquidity(share);

            // 4th PART - Employer - It gives value for TIME Token
            _employerAddress.call{value: share}("");

            toBeShared = 0;
            _checkAndPerformArbitrage();
            _updatePoolBalance();
        }
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
    function _transfer(address from, address to, uint256 amount) internal virtual override {
        require(from != address(0), "ERC20 TUP: transfer from the zero address");
        require(to != address(0), "ERC20 TUP: transfer to the zero address");

        _checkAndPerformArbitrage();

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20 TUP: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /**
     * @dev Updates the state of the internal pool balance
     *
     */
    function _updatePoolBalance() private {
        poolBalance = address(this).balance > toBeShared ? address(this).balance - toBeShared : 0;
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
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account] + accountShareBalance(account);
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
        if (to == address(this)) {
            sell(amount);
        } else {
            _transfer(msg.sender, to, amount);
        }
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
        address owner = msg.sender;
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
        address spender = msg.sender;
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual override returns (bool) {
        address owner = msg.sender;
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual override returns (bool) {
        address owner = msg.sender;
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20 TUP: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Show the amount an account address can credit to itself
     * @notice Shares are not calculated when running flash mint
     * @param account The address of some account
     * @return The claimable amount
     *
     */
    function accountShareBalance(address account) public view returns (uint256) {
        if (account != address(this) && account != helper.pairTupEth() && account != address(helper) && !_isFlashMintStarted) {
            return _balances[account].mulDiv(_dividendPerToken - _consumedDividendPerToken[account], FACTOR);
        } else {
            return 0;
        }
    }

    /**
     * @dev External function to burn TUP tokens. Sometimes is useful when you want to throw your money away... Who knows?
     * @param amount The amount of TUP tokens to be burned
     *
     */
    function burn(uint256 amount) external {
        require(amount <= balanceOf(msg.sender), "TUP_07");
        _burn(msg.sender, amount);
    }

    /**
     * @dev Main function of the TUP contract. Called whenever someone needs to generate tokens under the required conditions
     * @param timeAmount The amount of TIME Tokens an investor wants to use in order to mint more TUP tokens
     *
     */
    function mint(uint256 timeAmount) public payable nonReentrant {
        // It must transfer and burn TIME Token onto the contract in order to mint additional TUP tokens
        require(timeToken.allowance(msg.sender, address(this)) >= timeAmount, "TUP_02");
        uint256 timeAmountNativeValue = queryNativeFromTimeAmount(timeAmount);
        require(msg.value >= timeAmountNativeValue && msg.value > 0, "TUP_03");
        toBeShared += msg.value;
        if (timeAmount > 0) {
            timeToken.transferFrom(msg.sender, address(this), timeAmount);
            _splitShares(true);
        } else {
            _splitShares(false);
        }
        _mint(msg.sender, queryAmountOptimal(msg.value + timeAmountNativeValue));
    }

    /**
     * @dev Performs TUP minting for Liquidity Pools (Internal and External)
     * @notice It should query Chainlink to check the USD rate/price of native currency in order to maintain the same rate on all deployed networks
     * @param share The amount of ETH dedicated for the pools
     *
     */
    function _mintForLiquidity(uint256 share) private {
        uint256 shareForLiquidity = _queryAmountOptimal(share);
        if (shareForLiquidity == share) {
            (, int256 roundData,,,) = address(chainlink) != address(0) ? chainlink.latestRoundData() : (uint80(0),int256(CHAINLINK_FACTOR),uint256(0),uint256(0),uint80(0));
            shareForLiquidity = shareForLiquidity.mulDiv(uint256(roundData), CHAINLINK_FACTOR);
        }
        _addLiquidityNative(share, shareForLiquidity);
        if (_balances[address(this)] == 0)
            _mint(address(this), shareForLiquidity);
    }

    /**
     * @dev Queries for the external amount, in terms of TUP tokens, given an informed native amount
     * @notice It queries for the external LP
     * @param amountNative The native amount
     * @return uint256 The amount of TUP tokens
     *
     */
    function queryAmountExternalLP(uint256 amountNative) public view returns (uint256) {
        uint256 amountExternalLP = amountNative.mulDiv(helper.queryRate(), FACTOR);
        return (amountExternalLP == 0) ? amountNative : amountExternalLP;
    }

    /**
     * @dev Queries for the internal amount, in terms of TUP tokens, given an informed native amount
     * @notice It queries for the internal LP
     * @param amountNative The native amount
     * @return uint256 The amount of TUP tokens
     *
     */
    function queryAmountInternalLP(uint256 amountNative) public view returns (uint256) {
        uint256 amountInternalLP = amountNative.mulDiv(queryPriceNative(amountNative), FACTOR);
        return (amountInternalLP == 0) ? amountNative : amountInternalLP;
    }

    /**
     * @dev Queries for the optimal amount, in terms of TUP tokens, given an informed native amount
     * @param amountNative The native amount
     * @return uint256 The amount of TUP tokens
     *
     */
    function queryAmountOptimal(uint256 amountNative) public view returns (uint256) {
        uint256 amountOptimal = _queryAmountOptimal(amountNative);
        return (amountOptimal - _calculateComissionOverAmount(amountOptimal));
    }

    /**
     * @dev Queries for the native amount value given some TUP tokens informed
     * @param amount The amount of TUP tokens
     * @return uint256 The native amount
     *
     */
    function queryNativeAmount(uint256 amount) external view returns (uint256) {
        uint256 amountNativeValue = _queryNativeAmount(amount);
        return (amountNativeValue - _calculateComissionOverAmount(amountNativeValue));
    }

    /**
     * @dev Queries for the native amount value given some TIME Token amount passed
     * @param timeAmount The amount of TIME Tokens informed
     * @return uint256 The native amount
     *
     */
    function queryNativeFromTimeAmount(uint256 timeAmount) public view returns (uint256) {
        if (timeAmount != 0) {
            return timeAmount.mulDiv(timeToken.swapPriceTimeInverse(timeAmount), FACTOR);
        } else {
            return 0;
        }
    }

    /**
     * @dev Query for market price before swap, in TUP/ETH, in terms of native cryptocurrency (ETH)
     * @notice Constant Function Market Maker
     * @param amountNative The amount of ETH a user wants to exchange
     * @return Local market price, in TUP/ETH, given the amount of ETH a user informed
     *
     */
    function queryPriceNative(uint256 amountNative) public view returns (uint256) {
        if (poolBalance > 0 && _balances[address(this)] > 0) {
            uint256 ratio = poolBalance.mulDiv(FACTOR, amountNative + 1);
            uint256 deltaSupply = _balances[address(this)].mulDiv(amountNative.mulDiv(ratio, 1), poolBalance + amountNative);
            return deltaSupply / poolBalance;
        } else {
            return FACTOR;
        }
    }

    /**
     * @dev Query for market price before swap, in ETH/TUP, in terms of ETH currency
     * @param amount The amount of TUP a user wants to exchange
     * @return Local market price, in ETH/TUP, given the amount of TUP a user informed
     *
     */
    function queryPriceInverse(uint256 amount) public view returns (uint256) {
        if (poolBalance > 0 && _balances[address(this)] > 0) {
            uint256 deltaBalance =
                poolBalance.mulDiv(amount.mulDiv(_balances[address(this)].mulDiv(FACTOR, amount + 1), 1), _balances[address(this)] + amount);
            return deltaBalance / _balances[address(this)];
        } else {
            return 1;
        }
    }

    /**
     * @dev Queries the amount to be paid to callers of the splitSharesDinamicallyWithReward() function
     * @return uint256 The amount to be paid
     *
     */
    function queryPublicReward() public view returns (uint256) {
        return toBeShared.mulDiv(COMISSION_RATE, 10_000);
    }

    /**
     * @notice Receives ETH as profit and set to be shared among TUP holders
     * @dev Usually called by Helper contract, but anyone can call it
     * @return response Just a silly response
     *
     */
    function receiveProfit() external payable returns (bool response) {
        if (msg.value > 0) {
            toBeShared += msg.value;
            totalEarned += msg.value;
            _updatePoolBalance();
            response = true;
        }
        return response;
    }

    /**
     * @dev Returns native amount back to the TUP contract when it is not desired to share the amount with holders. Usually called by Helper
     * @return bool Just a silly response
     *
     */
    function returnNative() external payable nonReentrant returns (bool) {
        _updatePoolBalance();
        return true;
    }

    /**
     * @notice Define a new Helper contract to TUP token
     * @dev Established as a security measure. Only the owner of this contract can call it
     * @param newHelperAddress The address of the new Helper contract
     */
    function setHelper(address newHelperAddress) external onlyOwner {
        helper = IHelperBase(newHelperAddress);
    }

    /**
     * @dev Splits the share (earned amount) among the TUP token holders and pays a reward for the caller
     * @notice This function should be called sometimes in order to make the contract works as desired
     *
     */
    function splitSharesWithReward() external nonReentrant {
        if (toBeShared > 0) {
            uint256 reward = queryPublicReward();
            toBeShared -= reward;
            _splitShares(false);
            payable(msg.sender).transfer(reward);
            _updatePoolBalance();
        }
    }

    /**
     * @dev Investor send native cryptocurrency in exchange for TUP tokens. Here, he sends some amount and the contract calculates the equivalent amount in TUP units
     * @notice msg.value - The amount of TUP in terms of ETH an investor wants to buy
     * @return success If the operation was performed well
     */
    function buy() public payable nonReentrant returns (bool success) {
        if (msg.value > 0) {
            uint256 nativeAmountValue = _queryAmountOptimal(msg.value);
            require(nativeAmountValue <= _balances[address(this)], "TUP_05");
            if (msg.sender == address(helper)) {
                _transfer(address(this), msg.sender, nativeAmountValue);
            } else {
                uint256 comission = _calculateComissionOverAmount(nativeAmountValue);
                _transfer(address(this), msg.sender, nativeAmountValue - comission);
                if (comission < _balances[address(this)])
                    _burn(address(this), comission);
                address pairTupEth = helper.pairTupEth();
                if (comission < balanceOf(pairTupEth)) {
                    _burn(pairTupEth, comission);
                    IUniswapV2Pair(pairTupEth).sync();
                }
            }
            _updatePoolBalance();
            success = true;
        }
        return success;
    }

    /**
     * @dev Investor send TUP tokens in exchange for native cryptocurrency
     * @param amount The amount of TUP tokens for exchange
     * @return success Informs if the sell was performed well
     */
    function sell(uint256 amount) public nonReentrant returns (bool success) {
        require(!_isFlashMintStarted, "TUP_08");
        require(balanceOf(msg.sender) >= amount, "TUP_06");
        uint256 amountNativeValue = _queryNativeAmount(amount);
        require(amountNativeValue <= poolBalance, "TUP_05");
        _transfer(msg.sender, address(this), amount);
        if (msg.sender == address(helper)) {
            payable(msg.sender).transfer(amountNativeValue);
        } else {
            uint256 comission = _calculateComissionOverAmount(amountNativeValue);
            payable(msg.sender).transfer(amountNativeValue - comission);
            uint256 internalAmount = queryAmountInternalLP(comission);
            if (internalAmount > 0 && internalAmount < _balances[address(this)])
                _burn(address(this), internalAmount);
            address pairTupEth = helper.pairTupEth();
            uint256 externalAmount = queryAmountExternalLP(comission);
            if (externalAmount > 0 && externalAmount < _balances[pairTupEth])
                _burn(pairTupEth, externalAmount);
            IUniswapV2Pair(pairTupEth).sync();
            toBeShared += comission;
            totalEarned += comission;
        }
        _updatePoolBalance();
        return success;
    }

    /**
     * @dev Performs flash mint of TUP tokens for msg.sender address, limited to the _totalSupply amount
     * @notice The user must implement his logic inside the doSomething() function. The fee for flash mint must be paid in native tokens by calling and passing the value for the payFlashMintFee() function from the doSomething() function
     * @param amountToBorrow The amount of TUP tokens the user wants to borrow
     * @param data Arbitrary data the user wants to pass to its doSomething() function
     *
     */
    function flashMint(uint256 amountToBorrow, bytes calldata data) external nonReentrant performFlashMint {
        require(amountToBorrow <= _totalSupply, "TUP_09");
        uint256 earnedBefore = totalEarnedFromFlashMintFee;
        _currentFlashMintFee = _queryNativeAmount(amountToBorrow).mulDiv(FLASH_MINT_FEE, 10_000);
        _mint(msg.sender, amountToBorrow);
        // Here the borrower should perform some action with the borrowed TUP amount
        IFlashMintBorrower(msg.sender).doSomething(amountToBorrow, _currentFlashMintFee, data);
        require((totalEarnedFromFlashMintFee - earnedBefore) >= _currentFlashMintFee, "TUP_10");
        require(_isFlashMintPaid, "TUP_11");
        _burn(msg.sender, amountToBorrow);
    }

    /**
     * @dev Function called inside the doSomething() function to pay fees for the flash minted amount
     *
     */
    function payFlashMintFee() external payable {
        require(_isFlashMintStarted, "TUP_08");
        require(msg.value >= _currentFlashMintFee, "TUP_10");
        totalEarned += msg.value;
        totalEarnedFromFlashMintFee += msg.value;
        toBeShared += msg.value;
        _updatePoolBalance();
        _isFlashMintPaid = true;
    }
}
