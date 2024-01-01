// website  : https://zerogasprotocol.com/
// twitter  : https://twitter.com/zerogaserc
// telegram : https://t.me/zerogaserc

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
import "./IERC20.sol";
import "./Ownable.sol";
pragma solidity 0.8.21;

interface IPair {
    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function token0() external view returns (address);

    function sync() external;
}

interface IFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
}

interface IUniswapRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
}

abstract contract ERC20 is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory _tokenName, string memory _tokenSymbol) {
        _name = _tokenName;
        _symbol = _tokenSymbol;
        _decimals = 18;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

contract ZeroGasProtocol is ERC20, Ownable {
    address payable public marketingAddress;
    address public immutable deadAddress = address(0xDEAD);

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1_000_000_000 * 10 ** 18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    uint256 public maxAmount = (_tTotal * 2) / 100; // 2%
    uint256 public maxWallet = (_tTotal * 2) / 100; // 2%

    bool public limitsInEffect = true;
    bool public tradingEnable = false;
    uint256 public _sellTax = 3;

    uint256 private _initTax = 25;
    uint256 private _reduceTaxAt = 20;

    uint256 private _buyCount = 0;
    uint256 private _sellCount = 0;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;
    address[] private _excluded;

    IUniswapRouter public immutable router;
    address public immutable pair;

    event Distribute(uint256 amount);
    event OffLimits();

    constructor() ERC20("Zero Gas Protocol", "WEI") {
        marketingAddress = payable(msg.sender);
        _rOwned[_msgSender()] = _rTotal;
        router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        pair = IFactory(router.factory()).createPair(
            address(this),
            router.WETH()
        );

        _isExcludedFromFee[_msgSender()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[address(router)] = true;
        _isExcludedFromFee[deadAddress] = true;

        excludeFromReward(address(this));
        excludeFromReward(deadAddress);
        excludeFromReward(pair);

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    /**
     * @dev Returns the total supply of the token.
     */
    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    /**
     * @dev Returns the balance of a given account.
     * @param account The address of the account to check.
     * @return The balance of the account.
     */
    function balanceOf(address account) public view override returns (uint256) {
        // If the account is excluded, return the token balance directly.
        if (_isExcluded[account]) {
            return _tOwned[account];
        }

        // Otherwise, calculate the token balance from the reflection balance.
        return tokenFromReflection(_rOwned[account]);
    }

    function startZeroGas() external onlyOwner {
        tradingEnable = true;
    }

    /**
     * @dev Transfers `amount` tokens from the caller's account to `recipient`.
     *
     * @param recipient The address to transfer tokens to.
     * @param amount The amount of tokens to transfer.
     *
     * @return A boolean indicating whether the transfer was successful or not.
     */
    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        // Call the internal _transfer function to perform the actual transfer
        _transfer(_msgSender(), recipient, amount);

        // Return true to indicate that the transfer was successful
        return true;
    }

    /**
     * @dev Returns the amount of tokens that `spender` is allowed to spend
     * on behalf of `owner`.
     *
     * @param owner The address that owns the tokens.
     * @param spender The address that is allowed to spend the tokens.
     * @return The amount of tokens that `spender` is allowed to spend.
     */
    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev Approve the `spender` to spend `amount` of the caller's tokens.
     * Emits an {Approval} event.
     *
     * @param spender The address of the account allowed to spend the tokens.
     * @param amount The amount of tokens the `spender` is allowed to spend.
     * @return A boolean indicating whether the approval was successful.
     */
    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * @param sender The address to transfer tokens from.
     * @param recipient The address to transfer tokens to.
     * @param amount The amount of tokens to transfer.
     * @return A boolean indicating whether the transfer was successful.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        require(
            _allowances[sender][_msgSender()] >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()] - amount
        );
        return true;
    }

    /**
     * @dev Increase the allowance of `spender` by `addedValue` tokens.
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        // Increase the allowance
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + (addedValue)
        );
        return true;
    }

    /**
     * @dev Decreases the allowance of `spender` by `subtractedValue`.
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     * - The caller must have an allowance for `spender` of at least `subtractedValue`.
     *
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of allowance to decrease.
     * @return A boolean value indicating whether the operation was successful.
     */
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        require(
            _allowances[_msgSender()][spender] >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] - subtractedValue
        );
        return true;
    }

    /**
     * @dev Checks if an account is excluded from reward.
     * @param account The address of the account to check.
     * @return True if the account is excluded from reward, false otherwise.
     */
    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    /**
     * @dev Calculates the reflection amount from a given token amount.
     * @param tAmount The token amount.
     * @return The reflection amount.
     */
    function reflectionFromToken(
        uint256 tAmount
    ) public view returns (uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        (uint256 rAmount, , , ) = _getValues(tAmount, 0);
        return rAmount;
    }

    // Calculates the token amount from the reflection amount
    // rAmount: The reflection amount
    // Returns: The token amount
    function tokenFromReflection(
        uint256 rAmount
    ) public view returns (uint256) {
        // Ensure that the reflection amount is less than or equal to the total reflections
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );

        // Get the current rate
        uint256 currentRate = _getRate();

        // Calculate and return the token amount
        return rAmount / currentRate;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(
            !_isExcluded[sender],
            "Excluded addresses cannot call this function"
        );
        (uint256 rAmount, , , ) = _getValues(tAmount, 0);
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _rTotal = _rTotal - (rAmount);
        _tFeeTotal = _tFeeTotal + (tAmount);
    }

    /// @dev Disables the limits in effect.
    function offLimits() external onlyOwner {
        limitsInEffect = false;
        emit OffLimits();
    }

    // Sets the marketing address
    // Parameters:
    // - _marketingAddress: The new marketing address
    // Modifiers:
    // - onlyOwner: Restricts the function to be called only by the contract owner
    function setMarketingAddress(address _marketingAddress) external onlyOwner {
        require(
            _marketingAddress != address(0),
            "Cannot set treasury to zero address"
        );
        marketingAddress = payable(_marketingAddress);
    }

    /// @dev Excludes an account from fees
    /// @param account The address to exclude
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    /// @dev Includes an account in fees
    /// @param account The address to include
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    /**
     * @dev Calculates the tax fee for a transaction.
     * @param _amount The amount of tokens being transferred.
     * @param sender The address of the sender.
     * @param recipient The address of the recipient.
     * @return The tax fee amount.
     */
    function calculateTaxFee(
        uint256 _amount,
        address sender,
        address recipient
    ) private view returns (uint256) {
        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
            return 0;
        }
        if (sender != pair && recipient != pair) {
            return 0;
        }
        if (sender == pair && _buyCount < _reduceTaxAt) {
            return (_amount * _initTax) / 100;
        }
        if (recipient == pair) {
            if (_sellCount < _reduceTaxAt) return (_amount * _initTax) / 100;
            return (_amount * _sellTax) / 100;
        }
        return 0;
    }

    /**
     * @dev Excludes an account from receiving rewards.
     * @param account The address of the account to be excluded.
     */
    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    /**
     * @dev Includes an account in the reward distribution.
     * Can only be called by the contract owner.
     * @param account The address of the account to include.
     */
    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    /**
     * @dev Internal function to approve the spender to spend a certain amount of tokens from the owner's balance.
     * @param owner The address of the token owner.
     * @param spender The address of the spender.
     * @param amount The amount of tokens to be approved.
     */
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Internal function to transfer tokens.
     * @param from The address to transfer tokens from.
     * @param to The address to transfer tokens to.
     * @param amount The amount of tokens to transfer.
     */
    function _transfer(address from, address to, uint256 amount) private {
        require(amount > 0, "Transfer amount must be greater than zero");
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (!_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            require(tradingEnable, "Trading not live");
            if (limitsInEffect) {
                if (from == pair || to == pair) {
                    require(amount <= maxAmount, "Max Tx Exceeded");
                }
                if (to != pair) {
                    require(
                        balanceOf(to) + amount <= maxWallet,
                        "Max Wallet Exceeded"
                    );
                }
            }

            if (to == pair) {
                _sellCount++;
            }
            if (from == pair) {
                _buyCount++;
            }
        }
        _tokenTransfer(from, to, amount);
    }

    /**
     * @dev Internal function to transfer tokens.
     * @param sender The address sending the tokens.
     * @param recipient The address receiving the tokens.
     * @param amount The amount of tokens to transfer.
     */
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }

    /**
     * @dev Transfers tokens from the sender to the recipient.
     * @param sender The address of the sender.
     * @param recipient The address of the recipient.
     * @param tAmount The amount of tokens to transfer.
     */
    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        uint256 tFee = calculateTaxFee(tAmount, sender, recipient);
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount
        ) = _getValues(tAmount, tFee);
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _rOwned[recipient] = _rOwned[recipient] + (rTransferAmount);
        _takeFee(rFee, tFee, sender);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    /**
     * @dev Transfer tokens from a sender to a recipient (for excluded addresses).
     * @param sender The address sending the tokens.
     * @param recipient The address receiving the tokens.
     * @param tAmount The amount of tokens being transferred.
     */
    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        uint256 tFee = calculateTaxFee(tAmount, sender, recipient);
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount
        ) = _getValues(tAmount, tFee);
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _tOwned[recipient] = _tOwned[recipient] + (tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient] + (rTransferAmount);
        _takeFee(rFee, tFee, sender);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    /**
     * @dev Internal function to transfer tokens from an excluded address to another address.
     * @param sender The address sending the tokens.
     * @param recipient The address receiving the tokens.
     * @param tAmount The amount of tokens being transferred.
     */
    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        uint256 tFee = calculateTaxFee(tAmount, sender, recipient);

        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount
        ) = _getValues(tAmount, tFee);
        _tOwned[sender] = _tOwned[sender] - (tAmount);
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _rOwned[recipient] = _rOwned[recipient] + (rTransferAmount);
        _takeFee(rFee, tFee, sender);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    /**
     * @dev Transfer tokens from sender to recipient, with tax fee calculation.
     * @param sender The address sending the tokens.
     * @param recipient The address receiving the tokens.
     * @param tAmount The amount of tokens being transferred.
     */
    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        uint256 tFee = calculateTaxFee(tAmount, sender, recipient);
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount
        ) = _getValues(tAmount, tFee);
        _tOwned[sender] = _tOwned[sender] - (tAmount);
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _tOwned[recipient] = _tOwned[recipient] + (tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient] + (rTransferAmount);
        _takeFee(rFee, tFee, sender);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    /**
     * @dev Takes the fee from a transaction and distributes it accordingly.
     * @param rFeeTotal The total fee in the reflection token.
     * @param tFeeTotal The total fee in the transfer token.
     * @param _from The address from which the fee is taken.
     */
    function _takeFee(
        uint256 rFeeTotal,
        uint256 tFeeTotal,
        address _from
    ) private {
        uint256 rFeeReflect = (rFeeTotal * 2) / (_sellTax);
        uint256 tFeeReflect = (tFeeTotal * 2) / (_sellTax);

        // reflect fees
        _rTotal = _rTotal - (rFeeReflect);
        _tFeeTotal = _tFeeTotal + (tFeeReflect);

        // marketing fees
        _rOwned[marketingAddress] =
            _rOwned[marketingAddress] +
            (rFeeTotal - rFeeReflect);

        if (_isExcluded[marketingAddress]) {
            _tOwned[marketingAddress] =
                _tOwned[marketingAddress] +
                (tFeeTotal - tFeeReflect);
        }
        emit Transfer(_from, marketingAddress, tFeeTotal - tFeeReflect);
        emit Distribute(tFeeReflect);
    }

    /**
     * @dev Calculates the values for a given token amount and fee amount.
     * @param tAmount The token amount.
     * @param tFee The fee amount.
     * @return The calculated values: rAmount, rTransferAmount, rFee, tTransferAmount.
     */
    function _getValues(
        uint256 tAmount,
        uint256 tFee
    ) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tTransferAmount = _getTValues(tAmount, tFee);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            _getRate()
        );
        return (rAmount, rTransferAmount, rFee, tTransferAmount);
    }

    /**
     * @dev Calculates the transfer amount in token units.
     * @param tAmount The token amount.
     * @param tFee The fee amount.
     * @return The calculated transfer amount in token units.
     */
    function _getTValues(
        uint256 tAmount,
        uint256 tFee
    ) private pure returns (uint256) {
        uint256 tTransferAmount = tAmount - (tFee);
        return tTransferAmount;
    }

    /**
     * @dev Calculates the R values for a given tAmount, tFee, and currentRate.
     * @param tAmount The transfer amount.
     * @param tFee The transfer fee.
     * @param currentRate The current rate.
     * @return rAmount The R amount.
     * @return rTransferAmount The R transfer amount.
     * @return rFee The R fee.
     */
    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 currentRate
    ) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount * (currentRate);
        uint256 rFee = tFee * (currentRate);
        uint256 rTransferAmount = rAmount - (rFee);
        return (rAmount, rTransferAmount, rFee);
    }

    /**
     * @dev Returns the rate calculated based on the current supply.
     * The rate is calculated by dividing the reserve supply (rSupply) by the total supply (tSupply).
     * @return The rate as a uint256 value.
     */
    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / (tSupply);
    }

    /**
     * @dev Returns the current token supply.
     * @return rSupply The total reflected supply of tokens.
     * @return tSupply The total token supply.
     */
    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply - (_rOwned[_excluded[i]]);
            tSupply = tSupply - (_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal / (_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    /**
     * @dev Checks if an account is excluded from fee calculations.
     * @param account The address of the account to check.
     * @return True if the account is excluded from fees, false otherwise.
     */
    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    receive() external payable {}
}
