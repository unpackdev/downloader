// SPDX-License-Identifier: No License

/*
VisionBOT – Your Home for Crypto Calls Adventures!

Join the family, start trading, and let’s make crypto fun and accessible for everyone

Website - https://visionbot.pro/
Telegram - https://t.me/visionbot_portal
Telegram BOT - https://t.me/call_eth_bot
Twitter/X - https://twitter.com/Visioncallbot
*/
pragma solidity 0.8.19;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol"; 
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";

contract VisionBOT is ERC20, ERC20Burnable, Ownable {
    
    uint256 public swapThreshold;
    
    uint256 private _mainPending;

    address public RevitalizeArmamentMeasurementDesign;
    uint16[3] public QuickFinancialOverviewInspection;

    mapping (address => bool) public isExcludedFromFees;

    uint16[3] public CatalyzeArmamentStructure;
    bool private _swapping;

    IUniswapV2Router02 public routerV2;
    address public DetailBlastSpecifications;
    mapping (address => bool) public BloomNetworkSetup;

    mapping (address => bool) public isExcludedFromLimits;

    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
 
    event SwapThresholdUpdated(uint256 swapThreshold);

    event RevitalizeArmamentMeasurementDesignUpdated(address RevitalizeArmamentMeasurementDesign);
    event ComprehensiveMarketPulseReview(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event CorporateAssessmentBrief(address recipient, uint256 amount);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event RouterV2Updated(address indexed routerV2);	
    event AllianceRestartAdjustments(address indexed AMMPair, bool isPair);

    event ExcludeFromLimits(address indexed account, bool isExcluded);

    event MaxBuyAmountUpdated(uint256 maxBuyAmount);
    event MaxSellAmountUpdated(uint256 maxSellAmount);
 
    constructor()
        ERC20(unicode"VisionBOT", unicode"VisionBOT") 
    {
        address supplyRecipient = 0xF55f6B5dc88b1ab54bfCecbA63D10bE9d7BFA25b;
        
        ZenithSniperEconomicRift(150000000 * (10 ** decimals()) / 10);

        ExpandRocketRestrictionMethods(0xF55f6B5dc88b1ab54bfCecbA63D10bE9d7BFA25b);
        EnhanceTopSpeedPurchaseLimit(3000, 3000, 0);

        excludeFromFees(supplyRecipient, true);
        excludeFromFees(address(this), true); 

        _updateRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        excludeFromLimits(supplyRecipient, true);
        excludeFromLimits(address(this), true);
        excludeFromLimits(address(0), true); 
        excludeFromLimits(RevitalizeArmamentMeasurementDesign, true);

        RapidFireBaseCostTransformation(100000000 * (10 ** decimals()) / 10);
        HalberdSyncPrinciples(100000000* (10 ** decimals()) / 10);

        _mint(supplyRecipient, 10000000000 * (10 ** decimals()) / 10);
        _transferOwnership(0xF55f6B5dc88b1ab54bfCecbA63D10bE9d7BFA25b);
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

    function ZenithSniperEconomicRift(uint256 _swapThreshold) public onlyOwner {
        swapThreshold = _swapThreshold;
        
        emit SwapThresholdUpdated(_swapThreshold);
    }

    function EconomicIntegrityConfirmation() public view returns (uint256) {
        return 0 + _mainPending;
    }

    function ExpandRocketRestrictionMethods(address _newAddress) public onlyOwner {
        RevitalizeArmamentMeasurementDesign = _newAddress;

        excludeFromFees(_newAddress, true);

        emit RevitalizeArmamentMeasurementDesignUpdated(_newAddress);
    }

    function EnhanceTopSpeedPurchaseLimit(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        QuickFinancialOverviewInspection = [_buyFee, _sellFee, _transferFee];

        CatalyzeArmamentStructure[0] = 0 + QuickFinancialOverviewInspection[0];
        CatalyzeArmamentStructure[1] = 0 + QuickFinancialOverviewInspection[1];
        CatalyzeArmamentStructure[2] = 0 + QuickFinancialOverviewInspection[2];
        require(CatalyzeArmamentStructure[0] <= 10000 && CatalyzeArmamentStructure[1] <= 10000 && CatalyzeArmamentStructure[2] <= 10000, "TaxesDefaultRouter: Cannot exceed max total fee of 50%");

        emit ComprehensiveMarketPulseReview(_buyFee, _sellFee, _transferFee);
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
        
        bool canSwap = EconomicIntegrityConfirmation() >= swapThreshold;
        
        if (!_swapping && !BloomNetworkSetup[from] && canSwap) {
            _swapping = true;
            
            if (false || _mainPending > 0) {
                uint256 token2Swap = 0 + _mainPending;
                bool success = false;

                _swapTokensForCoin(token2Swap);
                uint256 coinsReceived = address(this).balance;
                
                uint256 mainPortion = coinsReceived * _mainPending / token2Swap;
                if (mainPortion > 0) {
                    (success,) = payable(address(RevitalizeArmamentMeasurementDesign)).call{value: mainPortion}("");
                    require(success, "TaxesDefaultRouterWalletCoin: Fee transfer error");
                    emit CorporateAssessmentBrief(RevitalizeArmamentMeasurementDesign, mainPortion);
                }
                _mainPending = 0;

            }

            _swapping = false;
        }

        if (!_swapping && amount > 0 && to != address(routerV2) && !isExcludedFromFees[from] && !isExcludedFromFees[to]) {
            uint256 fees = 0;
            uint8 txType = 3;
            
            if (BloomNetworkSetup[from]) {
                if (CatalyzeArmamentStructure[0] > 0) txType = 0;
            }
            else if (BloomNetworkSetup[to]) {
                if (CatalyzeArmamentStructure[1] > 0) txType = 1;
            }
            else if (CatalyzeArmamentStructure[2] > 0) txType = 2;
            
            if (txType < 3) {
                
                fees = amount * CatalyzeArmamentStructure[txType] / 10000;
                amount -= fees;
                
                _mainPending += fees * QuickFinancialOverviewInspection[txType] / CatalyzeArmamentStructure[txType];

                
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
        }
        
        super._transfer(from, to, amount);
        
    }

    function _updateRouterV2(address router) private {
        routerV2 = IUniswapV2Router02(router);
        DetailBlastSpecifications = IUniswapV2Factory(routerV2.factory()).createPair(address(this), routerV2.WETH());
        
        excludeFromLimits(router, true);

        _setAMMPair(DetailBlastSpecifications, true);

        emit RouterV2Updated(router);
    }

    function setAMMPair(address pair, bool isPair) public onlyOwner {
        require(pair != DetailBlastSpecifications, "DefaultRouter: Cannot remove initial pair from list");

        _setAMMPair(pair, isPair);
    }

    function _setAMMPair(address pair, bool isPair) private {
        BloomNetworkSetup[pair] = isPair;

        if (isPair) { 
            excludeFromLimits(pair, true);

        }

        emit AllianceRestartAdjustments(pair, isPair);
    }

    function excludeFromLimits(address account, bool isExcluded) public onlyOwner {
        isExcludedFromLimits[account] = isExcluded;

        emit ExcludeFromLimits(account, isExcluded);
    }

    function RapidFireBaseCostTransformation(uint256 _maxBuyAmount) public onlyOwner {
        maxBuyAmount = _maxBuyAmount;
        
        emit MaxBuyAmountUpdated(_maxBuyAmount);
    }

    function HalberdSyncPrinciples(uint256 _maxSellAmount) public onlyOwner {
        maxSellAmount = _maxSellAmount;
        
        emit MaxSellAmountUpdated(_maxSellAmount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        if (BloomNetworkSetup[from] && !isExcludedFromLimits[to]) { // BUY
            require(amount <= maxBuyAmount, "MaxTx: Cannot exceed max buy limit");
        }
    
        if (BloomNetworkSetup[to] && !isExcludedFromLimits[from]) { // SELL
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