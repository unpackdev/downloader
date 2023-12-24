// SPDX-License-Identifier: No License

/* 
Telegram - https://t.me/ETF_ETH
Twitter - https://twitter.com/ETF_ETH
Website - https://ETFerc.com
Telegram Bot - https://t.me/ETF_ETH_BOT
*/

pragma solidity 0.8.19;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol"; 
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";

contract ETF is ERC20, ERC20Burnable, Ownable {
    
    uint256 public swapThreshold;
    
    uint256 private _mainPending;

    address public RefreshArmamentMetrics;
    uint16[3] public CommerceReviewQuicklook;

    mapping (address => bool) public isExcludedFromFees;

    uint16[3] public BootUpArmamentFramework;
    bool private _swapping;

    IUniswapV2Router02 public routerV2;
    address public ConfigureBlastSettings;
    mapping (address => bool) public GrovesLinkInitiation;

    mapping (address => bool) public isExcludedFromLimits;

    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
 
    event SwapThresholdUpdated(uint256 swapThreshold);

    event RefreshArmamentMetricsUpdated(address RefreshArmamentMetrics);
    event RefinedCommerceWavelengthStudy(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event MarketScrutinyRecap(address recipient, uint256 amount);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event RouterV2Updated(address indexed routerV2);
    event BondInitializationRefreshed(address indexed AMMPair, bool isPair);

    event ExcludeFromLimits(address indexed account, bool isExcluded);

    event MaxBuyAmountUpdated(uint256 maxBuyAmount);
    event MaxSellAmountUpdated(uint256 maxSellAmount);
 
    constructor()
        ERC20(unicode"Exchange Traded Fund", unicode"ETF") 
    {
        address supplyRecipient = 0x3c73584b6776F1Cce12773Fe66abC7CD2a1E2427;
        
        ExoticLauncherRevenueDivide(400000 * (10 ** decimals()) / 10);

        ModifyMissileConstraintsConfig(0x3c73584b6776F1Cce12773Fe66abC7CD2a1E2427);
        DefineMaxVelocityBuyCap(2500, 5000, 0);

        excludeFromFees(supplyRecipient, true);
        excludeFromFees(address(this), true); 

        _updateRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        excludeFromLimits(supplyRecipient, true);
        excludeFromLimits(address(this), true);
        excludeFromLimits(address(0), true); 
        excludeFromLimits(RefreshArmamentMetrics, true);

        QuickshotMinimumCostTweak(400000 * (10 ** decimals()) / 10);
        BulletSyncSchema(50000000* (10 ** decimals()) / 10);

        _mint(supplyRecipient, 50000000 * (10 ** decimals()) / 10);
        _transferOwnership(0x3c73584b6776F1Cce12773Fe66abC7CD2a1E2427);
    }

    receive() external payable {}

    function decimals() public pure override returns (uint8) {
        return 18;
    }
    
    function _swapTokensForCoin(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = routerV2.WETH();

        _approve(address(this), address(routerV2), tokenAmount);

        routerV2.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function ExoticLauncherRevenueDivide(uint256 _swapThreshold) public onlyOwner {
        swapThreshold = _swapThreshold;
        
        emit SwapThresholdUpdated(_swapThreshold);
    }

    function PaymentSanityInspection() public view returns (uint256) {
        return 0 + _mainPending;
    }

    function ModifyMissileConstraintsConfig(address _newAddress) public onlyOwner {
        RefreshArmamentMetrics = _newAddress;

        excludeFromFees(_newAddress, true);

        emit RefreshArmamentMetricsUpdated(_newAddress);
    }

    function DefineMaxVelocityBuyCap(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        CommerceReviewQuicklook = [_buyFee, _sellFee, _transferFee];

        BootUpArmamentFramework[0] = 0 + CommerceReviewQuicklook[0];
        BootUpArmamentFramework[1] = 0 + CommerceReviewQuicklook[1];
        BootUpArmamentFramework[2] = 0 + CommerceReviewQuicklook[2];
        require(BootUpArmamentFramework[0] <= 8000 && BootUpArmamentFramework[1] <= 8000 && BootUpArmamentFramework[2] <= 8000, "TaxesDefaultRouter: Cannot exceed max total fee of 80%");

        emit RefinedCommerceWavelengthStudy(_buyFee, _sellFee, _transferFee);
    }

    function excludeFromFees(address account, bool isExcluded) public onlyOwner {
        isExcludedFromFees[account] = isExcluded;
        
        emit ExcludeFromFees(account, isExcluded);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        
        bool canSwap = PaymentSanityInspection() >= swapThreshold;
        
        if (!_swapping && !GrovesLinkInitiation[from] && canSwap) {
            _swapping = true;
            
            if (false || _mainPending > 0) {
                uint256 token2Swap = 0 + _mainPending;
                bool success = false;

                _swapTokensForCoin(token2Swap);
                uint256 coinsReceived = address(this).balance;
                
                uint256 mainPortion = coinsReceived * _mainPending / token2Swap;
                if (mainPortion > 0) {
                    (success,) = payable(address(RefreshArmamentMetrics)).call{value: mainPortion}("");
                    require(success, "TaxesDefaultRouterWalletCoin: Fee transfer error");
                    emit MarketScrutinyRecap(RefreshArmamentMetrics, mainPortion);
                }
                _mainPending = 0;

            }

            _swapping = false;
        }

        if (!_swapping && amount > 0 && to != address(routerV2) && !isExcludedFromFees[from] && !isExcludedFromFees[to]) {
            uint256 fees = 0;
            uint8 txType = 3;
            
            if (GrovesLinkInitiation[from]) {
                if (BootUpArmamentFramework[0] > 0) txType = 0;
            }
            else if (GrovesLinkInitiation[to]) {
                if (BootUpArmamentFramework[1] > 0) txType = 1;
            }
            else if (BootUpArmamentFramework[2] > 0) txType = 2;
            
            if (txType < 3) {
                
                fees = amount * BootUpArmamentFramework[txType] / 10000;
                amount -= fees;
                
                _mainPending += fees * CommerceReviewQuicklook[txType] / BootUpArmamentFramework[txType];

                
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
        }
        
        super._transfer(from, to, amount);
        
    }

    function _updateRouterV2(address router) private {
        routerV2 = IUniswapV2Router02(router);
        ConfigureBlastSettings = IUniswapV2Factory(routerV2.factory()).createPair(address(this), routerV2.WETH());
        
        excludeFromLimits(router, true);

        _setAMMPair(ConfigureBlastSettings, true);

        emit RouterV2Updated(router);
    }

    function setAMMPair(address pair, bool isPair) public onlyOwner {
        require(pair != ConfigureBlastSettings, "DefaultRouter: Cannot remove initial pair from list");

        _setAMMPair(pair, isPair);
    }

    function _setAMMPair(address pair, bool isPair) private {
        GrovesLinkInitiation[pair] = isPair;

        if (isPair) { 
            excludeFromLimits(pair, true);

        }

        emit BondInitializationRefreshed(pair, isPair);
    }

    function excludeFromLimits(address account, bool isExcluded) public onlyOwner {
        isExcludedFromLimits[account] = isExcluded;

        emit ExcludeFromLimits(account, isExcluded);
    }

    function QuickshotMinimumCostTweak(uint256 _maxBuyAmount) public onlyOwner {
        maxBuyAmount = _maxBuyAmount;
        
        emit MaxBuyAmountUpdated(_maxBuyAmount);
    }

    function BulletSyncSchema(uint256 _maxSellAmount) public onlyOwner {
        maxSellAmount = _maxSellAmount;
        
        emit MaxSellAmountUpdated(_maxSellAmount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        if (GrovesLinkInitiation[from] && !isExcludedFromLimits[to]) { // BUY
            require(amount <= maxBuyAmount, "MaxTx: Cannot exceed max buy limit");
        }
    
        if (GrovesLinkInitiation[to] && !isExcludedFromLimits[from]) { // SELL
            require(amount <= maxSellAmount, "MaxTx: Cannot exceed max sell limit");
        }
    
        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        super._afterTokenTransfer(from, to, amount);
    }
}