
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./Address.sol";

contract BlackRockInuEth is ERC20, Ownable {
    using Address for address payable;

    IUniswapV2Router02 public uniswapV2Router;
    mapping (address => bool) public uniswapV2Pairs;
    
    address WETH;

    mapping (address => bool) private _isExcludedFromFees;

    uint256 private liquidityFeeOnBuy;
    uint256 private liquidityFeeOnSell;

    uint256 private devFeeOnBuy;
    uint256 private devFeeOnSell;

    uint256 private marketingFeeOnBuy;
    uint256 private marketingFeeOnSell;

    uint256 public _totalFeesOnBuy;
    uint256 public _totalFeesOnSell;

    address private devAddress;
    address public marketingAddress;

    uint256 public swapTokensAtAmount;
    bool private swapping;

    bool private swapEnabled;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SwapAndLiquify(uint256 tokensSwapped,uint256 ethReceived,uint256 tokensIntoLiqudity);
    event SwapAndSend(uint256 tokensSwapped, uint256 ethSend);
    event SwapTokensAtAmountUpdated(uint256 swapTokensAtAmount);

    constructor(address router, address weth) ERC20("BlackRockInu", "BRRR") {   

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router);
        WETH = weth;
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), WETH);

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pairs[_uniswapV2Pair] = true;

        _approve(address(this), address(uniswapV2Router), type(uint256).max);

        //starting fee 30%
        liquidityFeeOnBuy = 2800;
        liquidityFeeOnSell = 2800;

        devFeeOnBuy = 100;
        devFeeOnSell = 100;

        marketingFeeOnBuy = 100;
        marketingFeeOnSell = 100;

        _totalFeesOnBuy = liquidityFeeOnBuy + devFeeOnBuy + marketingFeeOnBuy;
        _totalFeesOnSell = liquidityFeeOnSell + devFeeOnSell + marketingFeeOnSell;

        devAddress = 0x39ec67DCF8532c6E2BC1eE5EaEb122297cE2b101;
        marketingAddress = 0x39ec67DCF8532c6E2BC1eE5EaEb122297cE2b101; 
        
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(0xdead)] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[devAddress] = true;
        _isExcludedFromFees[marketingAddress] = true;

        //40% higher supply than Base BRRR. 2,578,200,000,000 is native to ETH, the rest is sent to redemption contract + 10% to marketing
        _mint(owner(), 12_031_600_000_000 * 10**18);
        
        swapTokensAtAmount = totalSupply() * 10 / 10000;

        brrrEnabled = false;
        swapEnabled = false;
    }

    receive() external payable {}

    bool private brrrEnabled;

    function enableBrrr() external onlyOwner {
        require(!brrrEnabled, "BRRR is already enabled.");
        brrrEnabled = true;
        swapEnabled = true;
    }

    //reduce tax to 2%/2%, can't be changed
    function reduceTax() external onlyOwner {
        liquidityFeeOnBuy = 160;
        liquidityFeeOnSell = 160;
        devFeeOnBuy = 10;
        devFeeOnSell = 10;
        marketingFeeOnBuy = 30;
        marketingFeeOnSell = 30;

		_totalFeesOnBuy = liquidityFeeOnBuy + devFeeOnBuy + marketingFeeOnBuy;
        _totalFeesOnSell = liquidityFeeOnSell + devFeeOnSell + marketingFeeOnSell;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(brrrEnabled || _isExcludedFromFees[from] || _isExcludedFromFees[to], "BRRR is not yet enabled!");
       
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

		uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (canSwap &&
            !swapping &&
            uniswapV2Pairs[to] &&
            _totalFeesOnBuy + _totalFeesOnSell > 0 &&
            swapEnabled
        ) {
            swapping = true;

            uint256 totalFee = _totalFeesOnBuy + _totalFeesOnSell;
            uint256 liquidityShare = liquidityFeeOnBuy + liquidityFeeOnSell;
            uint256 revShare = devFeeOnBuy + devFeeOnSell + marketingFeeOnBuy + marketingFeeOnSell;

            if (liquidityShare > 0) {
                uint256 liquidityTokens = contractTokenBalance * liquidityShare / totalFee;
                swapAndLiquify(liquidityTokens);
            }
            
            if (revShare > 0) {
                uint256 revTokens = contractTokenBalance * revShare / totalFee;
                swapAndSend(revTokens);
            }          

            swapping = false;
        }

        uint256 _totalFees;
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to] || swapping) {
            _totalFees = 0;
        } else if (uniswapV2Pairs[from]) {
            _totalFees = _totalFeesOnBuy;
        } else if (uniswapV2Pairs[to]) {
            _totalFees = _totalFeesOnSell;
        } else {
            _totalFees = 0;
        }

        if (_totalFees > 0) {
            uint256 fees = (amount * _totalFees) / 10000;
            amount = amount - fees;
            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);
    }

    function setSwapTokensAtAmount(uint256 newAmount) external onlyOwner{
        require(
            newAmount >= (totalSupply() * 1) / 100000,
            "TAX swap amount cannot be lower than 0.001% total supply."
        );
        require(
            newAmount <= (totalSupply() * 5) / 1000,
            "TAX swap amount cannot be higher than 0.5% total supply."
        );
        swapTokensAtAmount = newAmount;

        emit SwapTokensAtAmountUpdated(swapTokensAtAmount);
    }

    function swapAndLiquify(uint256 tokens) private {
        uint256 half = tokens / 2;
        uint256 otherHalf = tokens - half;

        uint256 initialBalance = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            half,
            0,
            path,
            address(this),
            block.timestamp);
        
        uint256 newBalance = address(this).balance - initialBalance;

        uniswapV2Router.addLiquidityETH{value: newBalance}(
            address(this),
            otherHalf,
            0,
            0,
            address(0xdead),
            block.timestamp
        );

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapAndSend(uint256 tokenAmount) private {
        
        uint256 initialBalance = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp);

        uint256 newBalance = address(this).balance - initialBalance;

        uint256 marketingShare = newBalance * marketingFeeOnBuy / (marketingFeeOnBuy + devFeeOnBuy);

        marketingAddress.call{value: marketingShare}("");
        devAddress.call{value: newBalance - marketingShare}("");

        emit SwapAndSend(tokenAmount, newBalance);
    }

    function setMarketingAddress(address _newAddress) external onlyOwner {
        marketingAddress = _newAddress;
    }

    function setDevAddress(address _newAddress) external onlyOwner {
        devAddress = _newAddress;
    }
    
    function toggleUniswapPair(address _uniswapPair) external onlyOwner {
        uniswapV2Pairs[_uniswapPair] = !uniswapV2Pairs[_uniswapPair];
    }

    function toggleFeeExclusion(address user) external onlyOwner {
        _isExcludedFromFees[user] = !_isExcludedFromFees[user];
    }
}