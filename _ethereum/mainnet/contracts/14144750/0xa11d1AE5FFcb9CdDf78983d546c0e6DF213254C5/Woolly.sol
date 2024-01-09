// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";

import "./DividendToken.sol";

contract Woolly is Context, IERC20, IERC20Metadata, DividendToken {

    string private constant NAME = 'Woolly';
    string private constant SYMBOL = 'WOOL';
    uint8 private constant DECIMALS = 18;
    uint256 constant INITIAL_SUPPLY = 1000000000000000000000000000000000; // in smallest unit of token
    uint internal inceptionTimestamp_;
    uint internal constant DIVIDEND_PAY_PERIOD = 30 days;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;

    constructor() {

        _totalSupply = INITIAL_SUPPLY;
        dividendSupply_ = INITIAL_SUPPLY/2;
        inceptionTimestamp_ = block.timestamp;

        // add contract creator to dividend blacklist
        updateDividendBlacklist(msg.sender, true);

        _balances[msg.sender] = INITIAL_SUPPLY/2;
        emit Transfer(address(0), msg.sender, INITIAL_SUPPLY/2);

    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address ownerAddress, address spenderAddress) external view virtual override returns (uint256) {
        return _allowances[ownerAddress][spenderAddress];
    }

   /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

   /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `ownerAddress` cannot be the zero address.
     * - `spenderAddress` cannot be the zero address.
     */
    function _approve(address ownerAddress, address spenderAddress, uint256 amount) internal virtual {
        require(ownerAddress != address(0), "ERC20: approve from the zero address");
        require(spenderAddress != address(0), "ERC20: approve to the zero address");
        _allowances[ownerAddress][spenderAddress] = amount;
        emit Approval(ownerAddress, spenderAddress, amount);
    }

    /**
    * @dev Returns the account balance of another account with the address owner
    * @param ownerAddress - the address of the account owner
    */
    function balanceOf(address ownerAddress) external view virtual override returns (uint256) {
        return _balances[ownerAddress];
    }

    /**
    * @dev Burn tokens into Dividend Supply
    * @param value - amount of tokens to burn to the dividend supply
    * @return bool
    */
    function burnToDividendSupply(uint256 value) external returns (bool)
    {
        // validate that sender has sufficent balance
        require(value <= _balances[msg.sender]);

        // deduct from the sender's balance
        _balances[msg.sender] = _balances[msg.sender] - value;

        // add value to dividend supply
        return addToDividendSupply(msg.sender, value);
    }

    /**
    * @dev calculate the dividend for the supplied address and periods
    * @param targetAddress - address of the dividend recipient
    * @param dividendPeriods - number of periods on which the dividend should be calculated
    * @return uint256
    * NOTE: Dividend rate of ~ 0.578% per period simulated by /173
    *       This supports a monthly dividend payment for 10 years
    */
    function calculateDividend(address targetAddress, uint dividendPeriods) public view returns (uint256) {
        uint256 newBalance = _balances[targetAddress];
        uint256 currentDividend = 0;
        uint256 totalDividend = 0;
        for (uint i=0; i<dividendPeriods; i++) {
            currentDividend = newBalance / 173;
            totalDividend = totalDividend + currentDividend;
            newBalance = newBalance + currentDividend;
        }
        return totalDividend;
    }

    /**
    * @dev Collect Dividend
    * @param targetAddress - the address of the recipient of the dividends
    * @param isCollected - boolean indicator of whether the dividend is collected or sent
    */
    function collectDividend(address targetAddress, bool isCollected) public returns (bool) {

        // if the lastPaymentTimestamp is greater than a month, then calculate the number of months since the lastPaymentTimestamp and transfer that amount * (user token balance) to the user accounts.
        // Issue: The tokens could have been added recently, so the user should only receive dividend for those coins, not the entire balance.
        // This might require a monthly balance sheet for each user. That's a lot of storage and/or operations if performed on the chain
        // To avoid extra complexities the collectDividend function is called for both sender and receiver
        // Any changes to the balances should trigger collectDividend to avoid fraud

        // no dividend for blacklisted addresses
        if (dividendBlacklist[targetAddress]) {
            return false;
        }

        // Sets the Last Payment Timestamp for a new account
        if (lastPaymentTimestamp[targetAddress] == 0) {
            initializeNewAccount(targetAddress);
            return false;
        }

        if (_balances[targetAddress] > 0 && block.timestamp >= lastPaymentTimestamp[targetAddress] + DIVIDEND_PAY_PERIOD) {

            // calculate how many dividend periods have passed since the lastPayment
            uint currentPeriodTimestamp;
            uint dividendPeriods;
            (currentPeriodTimestamp, dividendPeriods) = getCurrentDividendPeriodAndTimestamp(lastPaymentTimestamp[targetAddress]);

            // compute total dividend
            uint totalDividend = calculateDividend(targetAddress, dividendPeriods);

            // validate totalDividend and update balances
            if (totalDividend > 0 && dividendSupply_ >= totalDividend) {
                updateBalances(targetAddress, totalDividend, isCollected, currentPeriodTimestamp, dividendPeriods);
                return true;
            }
        }

        return false;

    }

     /**
     * @dev Returns the number of decimals the token uses
     */
     function decimals() external view virtual override returns (uint8) {
        return DECIMALS;
     }

    /**
    * @dev Returns the Last Dividend Timestamp and number of dividend periods passed since a given timestamp
    * @param lastTimestamp - The last dividend payment timestamp as an argument for calculating number of dividend periods passed along with a new timestamp
    * @return tuple
    */
    function getCurrentDividendPeriodAndTimestamp(uint lastTimestamp) public view returns (uint, uint) {

        // the time passed since the inceptionTimestamp, divided by the period size and then rounded to months
        require (block.timestamp > lastTimestamp);
        uint numberOfPeriodsPassed = (block.timestamp - lastTimestamp) / DIVIDEND_PAY_PERIOD; // # of periods passed since the last payment
        return (lastTimestamp + (numberOfPeriodsPassed * DIVIDEND_PAY_PERIOD), numberOfPeriodsPassed);

    }

    /**
    * @dev Returns the InceptionTimestamp
    * @return uint
    */
    function getInceptionTimestamp() external view returns (uint) {
        return inceptionTimestamp_;
    }

     /**
     * @dev initialize a new account
     * @param targetAddress - address at which to initialize new account
     */
     function initializeNewAccount(address targetAddress) public {
         uint _period;
         (lastPaymentTimestamp[targetAddress], _period) = getCurrentDividendPeriodAndTimestamp(inceptionTimestamp_);
         emit DividendTimeStampInitialized(targetAddress, lastPaymentTimestamp[targetAddress], _period);
     }

     /**
     * @dev Returns the name of the token
     */
     function name() external view virtual override returns (string memory) {
        return NAME;
     }

     /**
     * @dev Returns the symbol of the token
     */
     function symbol() external view virtual override returns (string memory) {
        return SYMBOL;
     }

     /**
     * @dev Returns the total token supply
     */
     function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
     }

    /**
    * @dev Transfer token for a specified address
    * @param to - The address to transfer to.
    * @param value - The amount to be transferred.
    * @return bool
    */
    function transfer(address to, uint256 value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
    * @dev Transfer token for a specified address
    * @param from - The address to transfer from.
    * @param to - The address to transfer to.
    * @param value - The amount to be transferred.
    */
    function _transfer(address from, address to, uint256 value) internal virtual {

        require(to != address(0), "ERC20: transfer to the zero address");

        // validate balance
        require(value <= _balances[from], 'ERC20: insufficient balance');

        // collect dividends
        collectDividend(from, true);
        collectDividend(to, false);

        // update balances and emit transfer event
        _balances[from] = _balances[from] - value;
        _balances[to] = _balances[to] + value;
        emit Transfer(from, to, value);
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
     * - the caller must have allowance for ``sender``'s tokens of at least `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, 'ERC20: transfer amount exceeds allowance');
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }

        return true;
    }

    /**
    * @dev Update all balances from dividend collection
    * @param targetAddress - the address at which to update values
    * @param totalDividend - the total dividend amount
    * @param isCollected - boolean indicator of whether the dividend is collected or sent
    * @param currentPeriodTimestamp - current period timestamp value to update lastPaymentTimestamp
    * @param dividendPeriods - number of periods on which the dividend should be calculated
    */
    function updateBalances(address targetAddress, uint256 totalDividend, bool isCollected, uint currentPeriodTimestamp, uint dividendPeriods) public {

        // update balances
        dividendSupply_ = dividendSupply_ - totalDividend;
        _balances[targetAddress] = _balances[targetAddress] + totalDividend;

        // emit event
        if (isCollected) {
            emit DividendCollected(targetAddress, totalDividend, dividendPeriods);
        } else {
            emit DividendSent(targetAddress, totalDividend, dividendPeriods);
        }

        // set last payment timestamp for address
        lastPaymentTimestamp[targetAddress] = currentPeriodTimestamp;
    }
}
