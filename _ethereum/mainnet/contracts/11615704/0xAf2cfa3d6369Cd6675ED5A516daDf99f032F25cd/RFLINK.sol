// SPDX-License-Identifier: MIT

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";

pragma solidity ^0.6.12;

contract Balancer {
    constructor() public {
    }
}

contract RFLINK is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    string private _name = "RFLINK";
    string private _symbol = "RFLINK";
    uint8 private _decimals = 9;

    mapping(address => uint256) internal _reflectionBalance;
    mapping(address => uint256) internal _tokenBalance;
    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 private constant MAX = ~uint256(0);
    uint256 internal _tokenTotal = 1000000e9;
    uint256 internal _reflectionTotal = (MAX - (MAX % _tokenTotal));

    mapping(address => bool) isExcludedFromFee;
    mapping(address => bool) internal _isExcluded;
    address[] internal _excluded;

    uint256 public _feeDecimal = 2;
    uint256 public _buyHoldersFee = 100; // buys: 1% to holders
    uint256 public _sellHoldersFee = 200; // sells: 2% to holders
    uint256 public _buySplitFee = 100; // buys: 1% split into 0.5% buyback + 0.5% liquidity
    uint256 public _sellSplitFee = 200; // sells: 2% split into 1% buyback + 1% liquidity
    uint256 public _rebalanceCallerFee = 500;

    bool private inSwapAndLiquify;
    bool public tradingEnabled = false;

    uint256 public minTokensBeforeSwap = 100;
    uint256 public minEthBeforeSwap = 100;

    uint256 public lastRebalance = now;
    uint256 public rebalanceInterval = 30 minutes;
    uint256 public tradingEnabledAt;

    IUniswapV2Router02 public  uniswapV2Router;
    address public uniswapV2Pair;
    address public balancer;

    event RewardsDistributed(uint256 amount);
    event SwapedTokenForEth(uint256 EthAmount, uint256 TokenAmount);
    event SwapedEthForTokens(uint256 EthAmount, uint256 TokenAmount, uint256 CallerReward, uint256 AmountBurned);

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() public {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;

        balancer = address(new Balancer());

        isExcludedFromFee[_msgSender()] = true;
        isExcludedFromFee[address(this)] = true;

        _isExcluded[uniswapV2Pair] = true;
        _excluded.push(uniswapV2Pair);

        _reflectionBalance[_msgSender()] = _reflectionTotal;
        emit Transfer(address(0), _msgSender(), _tokenTotal);
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

    function totalSupply() public override view returns (uint256) {
        return _tokenTotal;
    }

    function balanceOf(address account) public override view returns (uint256) {
        if (_isExcluded[account]) return _tokenBalance[account];
        return tokenFromReflection(_reflectionBalance[account]);
    }

    function tokenFromReflection(uint256 reflectionAmount) public view returns (uint256)
    {
        require(reflectionAmount <= _reflectionTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getReflectionRate();
        return reflectionAmount.div(currentRate);
    }

    function transfer(address recipient, uint256 amount) public override virtual returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public override view returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override virtual returns (bool) {
        _transfer(sender, recipient, amount);

        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool)
    {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool)
    {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (!tradingEnabled && sender != owner()) {
            revert("Trading is not enabled yet");
        }

        bool isAddingLiquidity = sender == owner() && recipient == uniswapV2Pair;
        bool isBuy = sender == uniswapV2Pair && recipient != owner();
        bool isSell = sender != owner() && recipient == uniswapV2Pair;

        if (isBuy && tradingEnabledAt + 60 minutes > now && amount > 10_000e9) {
            revert("For the first 60 minutes, only buys of max 10.000 tokens are allowed");
        }

        if (!inSwapAndLiquify && sender != uniswapV2Pair && !isAddingLiquidity) {
            bool swap = true;
            uint256 contractBalance = address(this).balance;
            if (now > lastRebalance + rebalanceInterval && contractBalance > minEthBeforeSwap) {
                split(contractBalance);
                swap = false;
            }

            if (swap) {
                uint256 contractTokenBalance = balanceOf(address(this));
                if (contractTokenBalance >= minTokensBeforeSwap) {
                    swapTokensForEth();
                }
            }
        }

        uint256 transferAmount = amount;
        uint256 rate = _getReflectionRate();

        if (!isExcludedFromFee[sender] && !isExcludedFromFee[recipient] && !inSwapAndLiquify) {
            transferAmount = collectFee(sender, amount, rate, isBuy, isSell);
        }

        _reflectionBalance[sender] = _reflectionBalance[sender].sub(amount.mul(rate));
        _reflectionBalance[recipient] = _reflectionBalance[recipient].add(transferAmount.mul(rate));

        if (_isExcluded[sender]) {
            _tokenBalance[sender] = _tokenBalance[sender].sub(amount);
        }
        if (_isExcluded[recipient]) {
            _tokenBalance[recipient] = _tokenBalance[recipient].add(transferAmount);
        }

        emit Transfer(sender, recipient, transferAmount);
    }

    function collectFee(address account, uint256 amount, uint256 rate, bool isBuy, bool isSell) private returns (uint256) {
        uint256 transferAmount = amount;

        uint256 holdersFee = isBuy && _buyHoldersFee != 0 ? _buyHoldersFee : (isSell && _sellHoldersFee != 0 ? _sellHoldersFee : 0);
        if (holdersFee != 0) {
            uint256 taxFee = amount.mul(holdersFee).div(10 ** (_feeDecimal + 2));
            transferAmount = transferAmount.sub(taxFee);
            _reflectionTotal = _reflectionTotal.sub(taxFee.mul(rate));
            emit RewardsDistributed(taxFee);
        }

        uint256 baseSplitFee = isBuy && _buySplitFee != 0 ? _buySplitFee : (isSell && _sellSplitFee != 0 ? _sellSplitFee : 0);
        if (baseSplitFee != 0) {
            uint256 splitFee = amount.mul(baseSplitFee).div(10 ** (_feeDecimal + 2));
            transferAmount = transferAmount.sub(splitFee);
            _reflectionBalance[address(this)] = _reflectionBalance[address(this)].add(splitFee.mul(rate));
            emit Transfer(account, address(this), splitFee);
        }

        return transferAmount;
    }

    function _getReflectionRate() private view returns (uint256) {
        uint256 reflectionSupply = _reflectionTotal;
        uint256 tokenSupply = _tokenTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_reflectionBalance[_excluded[i]] > reflectionSupply || _tokenBalance[_excluded[i]] > tokenSupply)
                return _reflectionTotal.div(_tokenTotal);
            reflectionSupply = reflectionSupply.sub(_reflectionBalance[_excluded[i]]);
            tokenSupply = tokenSupply.sub(_tokenBalance[_excluded[i]]);
        }
        if (reflectionSupply < _reflectionTotal.div(_tokenTotal))
            return _reflectionTotal.div(_tokenTotal);
        return reflectionSupply.div(tokenSupply);
    }

    function swapTokensForEth() private lockTheSwap {
        uint256 tokenAmount = balanceOf(address(this));
        uint256 ethAmount = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

        ethAmount = address(this).balance.sub(ethAmount);
        emit SwapedTokenForEth(tokenAmount, ethAmount);
    }

    function swapEthForTokens(uint256 EthAmount) private {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value : EthAmount}(
            0,
            path,
            address(balancer),
            block.timestamp
        );

        _transfer(address(balancer), address(this), balanceOf(address(balancer)));
    }

    function split(uint256 contractBalance) private lockTheSwap {
        lastRebalance = now;

        uint256 quarterEthBalance = contractBalance.div(4);
        uint256 threeQuartersEthBalance = contractBalance.sub(quarterEthBalance);
        uint256 remainingQuarterEthBalance = contractBalance.sub(threeQuartersEthBalance);

        swapEthForTokens(threeQuartersEthBalance);

        uint256 tokenBalance = balanceOf(address(this));

        uint256 tokensForBuyAndBurn = tokenBalance.div(3).mul(2);

        // Buy and burn
        uint256 rewardForCaller = tokensForBuyAndBurn.mul(_rebalanceCallerFee).div(10 ** (_feeDecimal + 2));
        uint256 amountToBurn = tokensForBuyAndBurn.sub(rewardForCaller);

        uint256 rate = _getReflectionRate();

        _reflectionBalance[tx.origin] = _reflectionBalance[tx.origin].add(rewardForCaller.mul(rate));
        _reflectionBalance[address(balancer)] = 0;

        _tokenTotal = _tokenTotal.sub(amountToBurn);
        _reflectionTotal = _reflectionTotal.sub(amountToBurn.mul(rate));

        emit Transfer(address(balancer), tx.origin, rewardForCaller);
        emit Transfer(address(balancer), address(0), amountToBurn);
        emit SwapedEthForTokens(quarterEthBalance.mul(2), tokensForBuyAndBurn, rewardForCaller, amountToBurn);

        // Add liquidity
        uint256 tokensForLiquidity = tokenBalance.sub(tokensForBuyAndBurn);
        _tokenTotal = _tokenTotal.sub(tokensForLiquidity);
        _reflectionTotal = _reflectionTotal.sub(tokensForLiquidity.mul(rate));

        _approve(address(this), address(uniswapV2Router), tokensForLiquidity);
        _approve(address(balancer), address(uniswapV2Router), tokensForLiquidity);

        uniswapV2Router.addLiquidityETH{value : remainingQuarterEthBalance}(
            address(this),
            tokensForLiquidity,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    function enableTrading() external onlyOwner() {
        tradingEnabled = true;
        tradingEnabledAt = now;
    }

    function setBuyHoldersFee(uint256 newBuyHoldersFee) external onlyOwner() {
        _buyHoldersFee = newBuyHoldersFee;
    }

    function setSellHoldersFee(uint256 newSellHoldersFee) external onlyOwner() {
        _sellHoldersFee = newSellHoldersFee;
    }

    function setBuySplitFee(uint256 newBuySplitFee) external onlyOwner() {
        _buySplitFee = newBuySplitFee;
    }

    function setSellSplitFee(uint256 newSellSplitFee) external onlyOwner() {
        _sellSplitFee = newSellSplitFee;
    }

    receive() external payable {}
}
