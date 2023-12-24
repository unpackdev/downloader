// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";

import "./IERC20.sol";

import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IReferralRegistry.sol";
import "./INpLiquidityHolder.sol";

contract NpToken is UUPSUpgradeable, OwnableUpgradeable, IERC20 {
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;

    mapping(address => bool) private _isExcluded;
    address[] private _excluded;

    uint256 private _tTotal;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint256 public _taxFee;
    uint256 public _liquidityFee;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled;
    bool public _referralFee;

    uint256 public numTokensSellToAddToLiquidity;
    IReferralRegistry public registry;
    address public usd;
    INpLiquidityHolder public lpHolder;

    bool private _noFee; // transient variable

    struct TaxDecay {
        uint256 initialTax;
        uint256 decay;
        uint256 lastDecay;
    }
    bool public tradingEnabled;
    TaxDecay public taxDecay;

    uint256 private _additionalLpFee; // transient variable

    event SwapAndLiquify(uint256 tokensSwapped, uint256 usdReceived, uint256 tokensIntoLiqudity);
    event RewardDistribution(address indexed sender, address indexed referrer, uint256 reward);

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    function initialize(
        address _usd,
        IUniswapV2Router02 _router,
        IReferralRegistry reg,
        INpLiquidityHolder _lpHolder,
        uint256 _totalSupply,
        uint256 liquifyNum
    ) external initializer {
        __Ownable_init(_msgSender());

        registry = reg;
        usd = _usd;

        //Core Setup
        _name = "MoneyArk Token";
        _symbol = "Mark";

        lpHolder = _lpHolder;

        _tTotal = _totalSupply; // 100_000_000 * 10 ** 9
        _rTotal = (type(uint256).max - (type(uint256).max % _tTotal));
        _decimals = 9;
        _taxFee = 5;
        _liquidityFee = 5;
        _referralFee = true;
        swapAndLiquifyEnabled = false;
        numTokensSellToAddToLiquidity = liquifyNum; //50_000 * 10 ** 9

        _rOwned[owner()] = _rTotal;

        // set the rest of the contract variables
        uniswapV2Router = _router;
        uniswapV2Pair = IUniswapV2Factory(_router.factory()).createPair(address(this), _usd);

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        //at creation the owner owns all the tokens
        emit Transfer(address(0), owner(), _tTotal);
    }

    function setNumTokenSellAndAddLp(uint256 _num) external onlyOwner {
        numTokensSellToAddToLiquidity = _num;
    }

    function setSwapEnable(bool _en) external onlyOwner {
        swapAndLiquifyEnabled = _en;
    }

    function _decayTheTax() internal {
        uint256 currentTax = taxDecay.initialTax;
        if (currentTax == 0) return;
        uint256 decayAmount = (block.number - taxDecay.lastDecay) * taxDecay.decay;
        if (decayAmount >= currentTax) {
            taxDecay.initialTax = 0;
        } else {
            taxDecay.initialTax -= decayAmount;
        }
        taxDecay.lastDecay = block.number;
    }

    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "cannot enable twice");
        taxDecay = TaxDecay(70, 5, block.number);
        tradingEnabled = true;
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

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function reflect(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount, , , , , ) = _getValues(tAmount);
        _rOwned[sender] -= rAmount;
        _rTotal -= rAmount;
        _tFeeTotal += tAmount;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns (uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , , ) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

    function excludeFromReward(address account) public onlyOwner {
        require(account != address(uniswapV2Router), "We can not exclude the router.");
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] -= tAmount;
        _rOwned[sender] -= rAmount;
        _tOwned[recipient] += tTransferAmount;
        _rOwned[recipient] += rTransferAmount;
        _takeLiquidity(tLiquidity);
        (rFee, tFee) = _takeReferrerFee(sender, rFee, tFee);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal -= rFee;
        _tFeeTotal += tFee;
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        if (_noFee) {
            return (tAmount, 0, 0);
        }
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount - tFee - tLiquidity;
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount * currentRate;
        uint256 rFee = tFee * currentRate;
        uint256 rLiquidity = tLiquidity * currentRate;
        uint256 rTransferAmount = rAmount - rFee - rLiquidity;
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i; i < _excluded.length; ++i) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply -= _rOwned[_excluded[i]];
            tSupply -= _tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity * currentRate;
        _rOwned[address(this)] += rLiquidity;
        if (_isExcluded[address(this)]) _tOwned[address(this)] += tLiquidity;
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return (_amount * _taxFee) / 10 ** 2;
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return (_amount * (_liquidityFee + _additionalLpFee)) / 10 ** 2;
    }

    function removeAllFee() private {
        _noFee = true;
    }

    function restoreAllFee() private {
        _noFee = false;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        // _decayTheTax();
        // address pair = uniswapV2Pair;
        // bool enLp = swapAndLiquifyEnabled;

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        // uint256 contractTokenBalance = balanceOf(address(this));

        uint256 numSell = numTokensSellToAddToLiquidity;

        if (balanceOf(address(this)) >= numSell && !inSwapAndLiquify && from != uniswapV2Pair && swapAndLiquifyEnabled) {
            swapAndLiquify(numSell);
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        // TO BE REMOVED AFTER LAUNCH FOR SAVING GAS
        // Initial Buy Tax
        // if (!tradingEnabled && (from == pair || to == pair) && takeFee) {
        //     revert("trading not enabled");
        // }
        // if (!enLp && from == pair && takeFee) {
        //     _additionalLpFee = taxDecay.initialTax;
        // }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);

        // TO BE REMOVED AFTER LAUNCH FOR SAVING GAS
        // _additionalLpFee = 0;
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance / 2;
        uint256 otherHalf = contractTokenBalance - half;

        // capture the contract's current USD balance.
        // this is so that we can capture exactly the amount of USD that the
        // swap creates, and not make the liquidity event include any USD that
        // has been manually sent to the contract
        uint256 initialBalance = IERC20(usd).balanceOf(address(lpHolder));

        // swap tokens for USD
        swapTokensForUsd(half);

        uint256 newBalance = IERC20(usd).balanceOf(address(lpHolder)) - initialBalance;

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForUsd(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> usd
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = usd;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of USD
            path,
            address(lpHolder),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 usdAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        IERC20(usd).approve(address(uniswapV2Router), usdAmount);
        lpHolder.getToken(usd, usdAmount);

        // add the liquidity
        uniswapV2Router.addLiquidity(
            address(this),
            usd,
            tokenAmount,
            usdAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(lpHolder), // lp holder owns the liquidity
            block.timestamp
        );
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) removeAllFee();

        bool senderExcluded = _isExcluded[sender];
        bool recipientExcluded = _isExcluded[recipient];
        if (senderExcluded && !recipientExcluded) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!senderExcluded && recipientExcluded) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!senderExcluded && !recipientExcluded) {
            _transferStandard(sender, recipient, amount);
        } else if (senderExcluded && recipientExcluded) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        if (!takeFee) restoreAllFee();
    }

    function _takeReferrerFee(address sender, uint rFee, uint tFee) internal returns (uint, uint) {
        if (!_noFee && _referralFee) {
            address referrer = registry.referrerOf(sender);
            if (referrer != address(0)) {
                uint256 ttFee = tFee / 5;
                tFee -= ttFee;
                uint256 rrFee = ttFee * _getRate();
                rFee -= rrFee;
                _rOwned[referrer] += rrFee;
                if (_isExcluded[referrer]) {
                    _tOwned[referrer] += ttFee;
                }
                emit RewardDistribution(sender, referrer, ttFee);
            }
        }
        return (rFee, tFee);
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] -= rAmount;
        _rOwned[recipient] += rTransferAmount;
        _takeLiquidity(tLiquidity);
        (rFee, tFee) = _takeReferrerFee(sender, rFee, tFee);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] -= rAmount;
        _tOwned[recipient] += tTransferAmount;
        _rOwned[recipient] += rTransferAmount;
        _takeLiquidity(tLiquidity);
        (rFee, tFee) = _takeReferrerFee(sender, rFee, tFee);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] -= tAmount;
        _rOwned[sender] -= rAmount;
        _rOwned[recipient] += rTransferAmount;
        _takeLiquidity(tLiquidity);
        (rFee, tFee) = _takeReferrerFee(sender, rFee, tFee);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
