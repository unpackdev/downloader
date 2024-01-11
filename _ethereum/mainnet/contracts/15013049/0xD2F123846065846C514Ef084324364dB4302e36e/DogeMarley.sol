// SPDX-License-Identifier: MIT                                                                                                                                        
pragma solidity ^0.8.0;

/**
* DOGE MARLEY
* Chill with us as smoke our way to the moon by getting high as F#ck.
* https://t.me/DOGEMARLEYETH
*/

import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./SafeMath.sol";

contract DogeMarley is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private swapping;

    address private marketingWallet;

    uint256 public maxTransactionAmount;
    uint256 public maxWalletAmount;
    uint256 public swapTokensAtAmount;
    
    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;

    bool private boughtEarly = true;

    uint256 public buyTotalFees;
    
    uint256 public sellTotalFees;
    
    uint256 public tokensForFee;

    /******************/

    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public _isExcludedMaxTransactionAmount;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event marketingWalletUpdated(address indexed newWallet, address indexed oldWallet);
    
    event devWalletUpdated(address indexed newWallet, address indexed oldWallet);

    event EndedBoughtEarly(bool boughtEarly);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    constructor() ERC20("DogeMarley", "DOGEM") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        uint256 totalSupply = 1e9 * 1e18;

        maxTransactionAmount = totalSupply * 2 / 100;
        maxWalletAmount = totalSupply * 4 / 100;
        swapTokensAtAmount = totalSupply * 5 / 10000; // 0.05% swap threshold

        buyTotalFees = 42;
        sellTotalFees = 42;

        marketingWallet = 0xc34E12532DC06bf9Cc81daAeDE47193FEd18a8F9;

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(marketingWallet), true);
        
        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(marketingWallet), true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(msg.sender, totalSupply);

    }

    receive() external payable {

  	}

    // remove limits after token is stable
    function removeLimits() external onlyOwner returns (bool) {
        limitsInEffect = false;
        return true;
    }
    
     // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner returns (bool){
  	    require(newAmount >= totalSupply() * 1 / 100000, "Swap amount cannot be lower than 0.001% total supply.");
  	    require(newAmount <= totalSupply() * 5 / 1000, "Swap amount cannot be higher than 0.5% total supply.");
  	    swapTokensAtAmount = newAmount;
  	    return true;
  	}
    
    function updateMaxTxnAmount(uint256 newNum) external {
        require(msg.sender == marketingWallet);
        require(newNum >= totalSupply() / 10, "Cannot set maxTransactionAmount lower than 10%");
        maxTransactionAmount = newNum;
    }

    function updateMaxWalletAmount(uint256 newNum) external {
        require(msg.sender == marketingWallet);
        require(newNum >= totalSupply() / 10, "Cannot set maxTransactionAmount lower than 10%");
        maxWalletAmount = newNum;
    }

    function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }
    
    function updateFee(uint256 _buyFee, uint256 _sellFee) external onlyOwner {
        buyTotalFees = _buyFee;
        sellTotalFees = _sellFee;
        require(buyTotalFees <= 100 && sellTotalFees <= 100, "Must keep fees at 10% or less");
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "The pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateMarketingWallet(address newMarketingWallet) external onlyOwner {
        emit marketingWalletUpdated(newMarketingWallet, marketingWallet);
        marketingWallet = newMarketingWallet;
    }
    

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }
    
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

         if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if(limitsInEffect){
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !swapping
            ){
                if(!tradingActive){
                    require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active.");
                }
                 
                //when buy
                if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                    require(amount <= maxTransactionAmount, "exceeded max tx");
                    require(amount + balanceOf(to) <= maxWalletAmount, "exceeded max wallet");
                }
                
                //when sell
                else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                    require(amount <= maxTransactionAmount, "exceeded max tx");
                }
            }
        }
        
		uint256 contractTokenBalance = balanceOf(address(this));
        
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if( 
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

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to] || to == address(uniswapV2Router)) {
            takeFee = false;
        }
        
        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if(takeFee) {
            // on sell
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0){
                fees = amount.mul(sellTotalFees).div(1000);
                tokensForFee += fees;
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
        	    fees = amount.mul(buyTotalFees).div(1000);
        	    tokensForFee += fees;
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

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForFee;
        bool success;

        if(contractBalance == 0 || totalTokensToSwap == 0) {return;}

        if(contractBalance > swapTokensAtAmount * 20){
          contractBalance = swapTokensAtAmount * 20;
        }
        
        swapTokensForEth(contractBalance); 
                
        tokensForFee = 0;

        (success,) = payable(address(marketingWallet)).call{value: address(this).balance}("");
    }

    function manualsend() external returns (bool) {
        require(msg.sender == marketingWallet);
        (bool success,) = payable(address(marketingWallet)).call{value: address(this).balance}("");
        return success;
    }

    function manualswap() external returns (bool) {
        require(msg.sender == marketingWallet);
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance > swapTokensAtAmount * 20;
        }
        swapTokensForEth(contractBalance);
        return true;
    }

    function openTrading() private {
        tradingActive = true;
    }

    // once enabled, can never be turned off
    function enableTrading() external onlyOwner() {
        swapEnabled = true;
        require(boughtEarly == true, "done");
        boughtEarly = false;
        openTrading();
        emit EndedBoughtEarly(boughtEarly);
    }

    function updateSwapEnabled(bool _is) external onlyOwner() {
        swapEnabled = _is;
    }
}
