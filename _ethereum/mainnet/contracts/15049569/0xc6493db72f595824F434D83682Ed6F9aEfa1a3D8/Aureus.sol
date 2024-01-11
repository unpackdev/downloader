// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";
import "./USDCDividendTracker.sol";

import "./SafeMath.sol";

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract Aureus is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;

    address public deadAddress = 0x000000000000000000000000000000000000dEaD;

    bool private swapping;
    bool public tradingIsEnabled = false;

    USDCDividendTracker public usdcDividendTracker;

    address public USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public devWallet = 0x5F9368460537e25D95FB355BC667a02FcC94cD93;
    address public marketingWallet = 0x196A1f00F45633eD87e7B892860960EAFBFDbbC0;
    
    uint256 public maxWalletToken; 
    uint256 public maxBuyTransactionAmount;
    uint256 public maxSellTransactionAmount;
    uint256 public swapTokensAtAmount;

    uint256 public minTransactionTier;
    uint256 public maxTransactionTier;
    
    uint256 public totalFees;

    uint256 public buyMarketingFeeMin;
    uint256 public buyMarketingFeeNormal;
    uint256 public buyMarketingFeeMax;

    uint256 public sellMarketingFeeMin;
    uint256 public sellMarketingFeeNormal;
    uint256 public sellMarketingFeeMax;

    uint256 public buyUSDCDividendRewardsFeeMin;
    uint256 public buyUSDCDividendRewardsFeeNormal;
    uint256 public buyUSDCDividendRewardsFeeMax;

    uint256 public sellUSDCDividendRewardsFeeMin;
    uint256 public sellUSDCDividendRewardsFeeNormal;
    uint256 public sellUSDCDividendRewardsFeeMax;

    mapping(address => uint256) private sellcooldown;

    mapping (address => bool) private isExcludedFromFees;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event MarketingWalletUpdated(address indexed newMarketingWallet, address indexed oldMarketingWallet);

    constructor() ERC20("AUREUS", "AUR") {
    	usdcDividendTracker = new USDCDividendTracker();

        minTransactionTier = 50000000 * (10**18);
        maxTransactionTier = 500000000 * (10**18);
    	
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        // Create a uniswap pair for this new token
        address _uniswapWETHPair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        address _uniswapUSDCPair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), USDC);

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapUSDCPair;

        _setAutomatedMarketMakerPair(_uniswapWETHPair, true);
        _setAutomatedMarketMakerPair(_uniswapUSDCPair, true);
        
        excludeFromDividend(owner());
        excludeFromDividend(deadAddress);
        excludeFromDividend(marketingWallet);
        excludeFromDividend(address(this));
        excludeFromDividend(address(_uniswapV2Router));
        excludeFromDividend(address(usdcDividendTracker));
        
        // exclude from paying fees or having max transaction amount
        excludeFromFees(devWallet, true);
        excludeFromFees(marketingWallet, true);
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 100000000000 * (10**18));
    }

    receive() external payable {}

  	function prepareForPartnerOrExchangeListing(address _partnerOrExchangeAddress) external onlyOwner {
  	    usdcDividendTracker.excludeFromDividends(_partnerOrExchangeAddress);
        excludeFromFees(_partnerOrExchangeAddress, true);
  	}

    function updateMaxAmounts(uint256 _maxWallet, uint256 _maxBuyAmount, uint256 _maxSellAmount, uint256 _swapAmount) external onlyOwner {
        maxWalletToken = _maxWallet * (10**18); 
        maxBuyTransactionAmount = _maxBuyAmount * (10**18);
        maxSellTransactionAmount = _maxSellAmount * (10**18);
        swapTokensAtAmount = _swapAmount * (10**18);
    }

    function updateTransactionTier(uint256 _minTier, uint256 _maxTier) external onlyOwner {
        minTransactionTier = _minTier * (10**18);
        maxTransactionTier = _maxTier * (10**18);
    }
  	
  	function updateMarketingWallet(address _newWallet) external onlyOwner {
  	    require(_newWallet != marketingWallet, "The marketing wallet is already this address");
        excludeFromFees(_newWallet, true);
        emit MarketingWalletUpdated(marketingWallet, _newWallet);
  	    marketingWallet = _newWallet;
  	}

    function afterPreSale() external onlyOwner {
        tradingIsEnabled = true;

        buyMarketingFeeMin = 4;
        buyMarketingFeeNormal = 2;
        buyMarketingFeeMax = 1;

        sellMarketingFeeMin = 4;
        sellMarketingFeeNormal = 5;
        sellMarketingFeeMax = 6;

        buyUSDCDividendRewardsFeeMin = 4;
        buyUSDCDividendRewardsFeeNormal = 3;
        buyUSDCDividendRewardsFeeMax = 2;

        sellUSDCDividendRewardsFeeMin = 4;
        sellUSDCDividendRewardsFeeNormal = 5;
        sellUSDCDividendRewardsFeeMax = 6;

        swapTokensAtAmount = 50000000 * (10**18);
        maxBuyTransactionAmount = 2500000000 * (10**18);
        maxSellTransactionAmount = 2500000000 * (10**18);
        maxWalletToken = 2500000000 * (10**18);
    }
    
    function updateBuyMarketingFee(uint8 _feeMin, uint8 _feeNormal, uint8 _feeMax) external onlyOwner {
        buyMarketingFeeMin = _feeMin;
        buyMarketingFeeNormal = _feeNormal;
        buyMarketingFeeMax = _feeMax;
    }

    function updateSellMarketingFee(uint8 _feeMin, uint8 _feeNormal, uint8 _feeMax) external onlyOwner {
        sellMarketingFeeMin = _feeMin;
        sellMarketingFeeNormal = _feeNormal;
        sellMarketingFeeMax = _feeMax;
    }

    function updateBuyDividendRewardFee(uint8 _feeMin, uint8 _feeNormal, uint8 _feeMax) external onlyOwner {
        buyUSDCDividendRewardsFeeMin = _feeMin;
        buyUSDCDividendRewardsFeeNormal = _feeNormal;
        buyUSDCDividendRewardsFeeMax = _feeMax;
    }

    function updateSellDividendRewardFee(uint8 _feeMin, uint8 _feeNormal, uint8 _feeMax) external onlyOwner {
        sellUSDCDividendRewardsFeeMin = _feeMin;
        sellUSDCDividendRewardsFeeNormal = _feeNormal;
        sellUSDCDividendRewardsFeeMax = _feeMax;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(isExcludedFromFees[account] != excluded, "EtherBack: Account is already exluded from fees");
        isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeFromDividend(address account) public onlyOwner {
        usdcDividendTracker.excludeFromDividends(address(account));
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) external onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "The DEX pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private onlyOwner {
        require(automatedMarketMakerPairs[pair] != value, "Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            usdcDividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }
    
    function updateMinimumBalanceForDividends(uint256 newMinimumBalance) external onlyOwner {
        usdcDividendTracker.updateMinimumTokenBalanceForDividends(newMinimumBalance);
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        usdcDividendTracker.updateClaimWait(claimWait);
    }

    function getUSDCClaimWait() external view returns(uint256) {
        return usdcDividendTracker.claimWait();
    }

    function getTotalUSDCDividendsDistributed() external view returns (uint256) {
        return usdcDividendTracker.totalDividendsDistributed();
    }

    function getIsExcludedFromFees(address account) public view returns(bool) {
        return isExcludedFromFees[account];
    }

    function withdrawableUSDCDividendOf(address account) external view returns(uint256) {
    	return usdcDividendTracker.withdrawableDividendOf(account);
  	}

	function usdcDividendTokenBalanceOf(address account) external view returns (uint256) {
		return usdcDividendTracker.balanceOf(account);
	}
	
    function getAccountUSDCDividendsInfo(address account)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return usdcDividendTracker.getAccount(account);
    }

	function getAccountUSDCDividendsInfoAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	return usdcDividendTracker.getAccountAtIndex(index);
    }

    function claim() external {
		usdcDividendTracker.processAccount(payable(msg.sender));
    }

    function getLastUSDCDividendProcessedIndex() external view returns(uint256) {
    	return usdcDividendTracker.getLastProcessedIndex();
    }
    
    function getNumberOfUSDCDividendTokenHolders() external view returns(uint256) {
        return usdcDividendTracker.getNumberOfTokenHolders();
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        
        bool excludedAccount = isExcludedFromFees[from] || isExcludedFromFees[to];

        if (!tradingIsEnabled && !excludedAccount){
            require(!automatedMarketMakerPairs[from] && !automatedMarketMakerPairs[to] , "You cannot add liquidity before the trading active.");
        }
        
        if (
            tradingIsEnabled &&
            automatedMarketMakerPairs[from] &&
            !excludedAccount
        ) {
            require(
                amount <= maxBuyTransactionAmount,
                "Transfer amount exceeds the maxTxAmount."
            );
            
            uint256 contractBalanceRecepient = balanceOf(to);
            require(
                contractBalanceRecepient + amount <= maxWalletToken,
                "Exceeds maximum wallet token amount."
            );
        } else if (
        	tradingIsEnabled &&
            automatedMarketMakerPairs[to] &&
            !excludedAccount
        ) {
            require(amount <= maxSellTransactionAmount, "Sell transfer amount exceeds the maxSellTransactionAmount.");
            
            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= swapTokensAtAmount;
            
            if (!swapping && canSwap) {
                swapping = true;

                uint256 tokenForDev = contractTokenBalance.div(6);
                uint256 tokenForMarketing = contractTokenBalance.div(3);
                uint256 tokenForDividends = contractTokenBalance.div(2);

                swapTokensForUSDC(tokenForDev, devWallet);
                swapTokensForUSDC(tokenForMarketing, marketingWallet);
                swapTokensForUSDC(tokenForDividends, address(usdcDividendTracker));

                uint256 usdcTrackerBalance = IERC20(USDC).balanceOf(address(usdcDividendTracker));
                try usdcDividendTracker.distributeDividends(usdcTrackerBalance) {} catch {}

                swapping = false;
            }
        }

        bool takeFee = tradingIsEnabled && !swapping && !excludedAccount;

        if(takeFee) {
            if(automatedMarketMakerPairs[from]){
                // Buy tokens
                if(amount < minTransactionTier){
                    totalFees = buyMarketingFeeMin + buyUSDCDividendRewardsFeeMin;
                }else if( minTransactionTier <= amount && amount < maxTransactionTier){
                    totalFees = buyMarketingFeeNormal + buyUSDCDividendRewardsFeeNormal;
                }else if( maxTransactionTier <= amount){
                    totalFees = buyMarketingFeeMax + buyUSDCDividendRewardsFeeMax;
                }
            }else if(automatedMarketMakerPairs[to]) {
                require(sellcooldown[from] < block.timestamp);
                sellcooldown[from] = block.timestamp + (60 seconds);

                // Sell tokens
                if(amount < minTransactionTier){
                    totalFees = sellMarketingFeeMin + sellUSDCDividendRewardsFeeMin;
                }else if( minTransactionTier <= amount && amount < maxTransactionTier){
                    totalFees = sellMarketingFeeNormal + sellUSDCDividendRewardsFeeNormal;
                }else if( maxTransactionTier <= amount){
                    totalFees = sellMarketingFeeMax + sellUSDCDividendRewardsFeeMax;
                }
            }

            uint256 fees = amount.mul(totalFees).div(100);

        	amount = amount.sub(fees); totalFees = 0;

            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);

        try usdcDividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try usdcDividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}
    }

    function swapTokensForUSDC(uint256 _tokenAmount, address _recipient) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = USDC;

        _approve(address(this), address(uniswapV2Router), _tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _tokenAmount,
            0,
            path,
            _recipient,
            block.timestamp
        );
    }
}