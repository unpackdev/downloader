//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router.sol";

contract CRUFT is ERC20, Ownable {

    address payable public operationsWalletAddress = payable(0x5d43F1CcE7Af30BB7422Bc36Dd17E330aF31E208);
    address payable public marketingWalletAddress = payable(0xf8f6606172683f729C7f0475b49119fff8ddB72D);

    mapping (address => bool) public isExcludedFromFee;
    mapping (address => bool) public isWalletLimitExempt;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => uint256) public lastBuy;

    uint256 public penaltyTime = 24 hours;
    uint256 public penaltyPercent = 1;
    uint256 public _liquidityFee = 50;
    uint256 public _operationsFee = 20;
    uint256 public _marketingFee = 30;
    uint256 public totalFee = _liquidityFee + _operationsFee + _marketingFee;
    uint256 public constant DENOMINATOR = 1000;

    uint256 public multiplier = 250;
    uint256 public constant MULTIPLIER_DENOMINATOR = 100;

    uint256 public _maxTxAmount = 2_500_000 * 10 ** decimals();
    uint256 public _walletMax = 2_500_000 * 10 ** decimals();
    uint256 public minimumTokensBeforeSwap = 1_500* 10 ** decimals();

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived);
    event SwapETHForTokens(uint256 amountIn, address[] path);
    event SwapTokensForETH(uint256 amountIn, address[] path);
    event ETHSentTo(uint256 amount, address wallet);




    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor () ERC20("CRUFT", "CRUFT") {

        _mint(msg.sender, 10 ** 9 * 10 ** decimals());

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);//router
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;

        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[address(operationsWalletAddress)] = true;
        isExcludedFromFee[address(marketingWalletAddress)] = true;
        isExcludedFromFee[address(uniswapV2Router)] = true;

        isWalletLimitExempt[owner()] = true;
        isWalletLimitExempt[address(this)] = true;
        isWalletLimitExempt[address(operationsWalletAddress)] = true;
        isWalletLimitExempt[address(uniswapV2Pair)] = true;
        isWalletLimitExempt[address(marketingWalletAddress)] = true;

        isTxLimitExempt[owner()] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[address(operationsWalletAddress)] = true;
        isTxLimitExempt[address(marketingWalletAddress)] = true;
        isTxLimitExempt[address(uniswapV2Router)] = true;

    }

    function updatePenaltyTimeInSeconds(uint256 _newTime) external onlyOwner {
        penaltyTime = _newTime;
    }

    function updatePenaltyPercent(uint256 _newPercent) external onlyOwner {
        penaltyPercent = _newPercent;
    }

    function updateIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function updateIsExcludedFromFee(address account, bool newValue) public onlyOwner {
        isExcludedFromFee[account] = newValue;
    }

    function updateWalletLimitExempt(address holder, bool exempt) external onlyOwner {
        isWalletLimitExempt[holder] = exempt;
    }

    function setTaxes(uint256 newLiquidityFee, uint256 newDev, uint256 newMarketing) external onlyOwner() {
        _liquidityFee = newLiquidityFee;
        _operationsFee = newDev;
        _marketingFee = newMarketing;
        totalFee = _liquidityFee + _operationsFee + _marketingFee;
        require(totalFee <= 250, "Total fee can't be more than 25%");
    }

    function setMaxTxAmount(uint256 maxTxAmount) external onlyOwner() {
        _maxTxAmount = maxTxAmount;
    }

    function setWalletLimit(uint256 newLimit) external onlyOwner {
        _walletMax  = newLimit;
    }

    function updateWallets(address newDevWalletAddress, address newMarketingWalletAddress) external onlyOwner() {
        operationsWalletAddress = payable(newDevWalletAddress);
        marketingWalletAddress = payable(newMarketingWalletAddress);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setNumTokensBeforeSwap(uint256 newLimit) external onlyOwner() {
        minimumTokensBeforeSwap = newLimit;
    }

    function updateMultiplier(uint256 _newMultiplier ) external onlyOwner {
        require(_newMultiplier >= 100,"Should be greater than 100");
        multiplier = _newMultiplier;
    }

    function updateRouter(address newRouterAddress) public onlyOwner returns(address newPairAddress) {

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(newRouterAddress);

        newPairAddress = IUniswapV2Factory(_uniswapV2Router.factory()).getPair(address(this), _uniswapV2Router.WETH());

        if(newPairAddress == address(0)) //Create If Doesnt exist
        {
            newPairAddress = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        }

        uniswapV2Pair = newPairAddress; //Set new pair address
        uniswapV2Router = _uniswapV2Router; //Set new router address
    }

    receive() external payable {}

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {

        if(inSwapAndLiquify)
        {
            super._transfer(sender, recipient, amount);
            return;
        }
        else
        {
            if(!isTxLimitExempt[sender] && !isTxLimitExempt[recipient] && !inSwapAndLiquify) {
                require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;

            if (overMinimumTokenBalance && !inSwapAndLiquify && sender != uniswapV2Pair && swapAndLiquifyEnabled)
            {
                swapAndSendToWallets(minimumTokensBeforeSwap);
            }

            uint256 feeAmount;
            if(isExcludedFromFee[sender] || isExcludedFromFee[recipient]) {
                super._transfer(sender, recipient, amount);
                return;
            } else if (inPenalty(amount, sender)) {
                feeAmount = amount * totalFee * multiplier / DENOMINATOR / MULTIPLIER_DENOMINATOR;
            } else {
                feeAmount = amount * totalFee / DENOMINATOR;
            }
            if (feeAmount > 0) super._transfer(sender, address(this), feeAmount);

            amount -= feeAmount;

            if(!isWalletLimitExempt[recipient])
                require(balanceOf(recipient) + amount <= _walletMax);

            super._transfer(sender, recipient, amount);
            lastBuy[recipient] = block.timestamp;
        }
    }

    function inPenalty(uint256 amount, address sender) public view returns(bool) {
        if (amount >= totalSupply() * penaltyPercent/DENOMINATOR ||
            lastBuy[sender] + penaltyTime > block.timestamp) {
            return true;
        }
        return false;
    }

    function swapAndSendToWallets(uint256 tokens) private  {
        uint256 liquidityTokens = tokens * _liquidityFee / 2 / totalFee;
        uint256 tokensToSwap = tokens - liquidityTokens;
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(tokensToSwap);
        uint256 receivedETH = address(this).balance - initialBalance;
        uint256 totalFeesAdjusted = totalFee - _liquidityFee / 2;

        uint256 liquidityETH = receivedETH * _liquidityFee / 2 / (totalFeesAdjusted);
        uint256 operationsETH = receivedETH * _operationsFee / (totalFeesAdjusted);
        uint256 marketingETH = receivedETH - liquidityETH - operationsETH;

        addLiquidity(liquidityTokens, liquidityETH);
        emit SwapAndLiquify(liquidityTokens, liquidityETH);
        bool success;
        (success,) = address(operationsWalletAddress).call{value: operationsETH}("");
        if (success) {
            emit ETHSentTo(operationsETH, operationsWalletAddress);
        }
        (success,) = address(marketingWalletAddress).call{value: marketingETH}("");
        if (success) {
            emit ETHSentTo(marketingETH, marketingWalletAddress);
        }
    }

    function swapAndLiquify(uint256 tAmount) private lockTheSwap {
        uint256 tokensForLP = tAmount / 2;
        uint256 tokensForSwap = tAmount - tokensForLP;
        uint256 ETHBefore = address(this).balance;
        swapTokensForEth(tokensForSwap);
        uint256 ETHReceived = address(this).balance - ETHBefore;
        addLiquidity(tokensForLP, ETHReceived);
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
            address(this), // The contract
            block.timestamp
        );

        emit SwapTokensForETH(tokenAmount, path);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }
}
