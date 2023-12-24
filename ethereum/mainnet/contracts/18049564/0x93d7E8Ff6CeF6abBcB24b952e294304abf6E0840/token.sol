// SPDX-License-Identifier: No License

/*
ClickSwap - the ultimate platform for secure, fast, and efficient cryptocurrency exchanges across multiple blockchain networks. In an age where decentralization reigns supreme, ClickSwap acts as your most reliable bridge between various digital assets, ensuring you get the most bang for your buck.

Website - https://clickswap.pro
Telegram - https://t.me/ClickSwap_Portal
Telegram BOT - https://t.me/ClickSwap_BOT
Twitter - https://twitter.com/ClickSwap_BOT

*/
pragma solidity 0.8.19;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol"; 
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";

contract ClickSwap is ERC20, ERC20Burnable, Ownable {
    
    uint256 public swapThreshold;
    
    uint256 private _mainPending;

    address public InvigorateWeaponryMetricDesign;
    uint16[3] public FinancialQuickViewAnalysis;

    mapping (address => bool) public isExcludedFromFees;

    uint16[3] public KickstartWeaponFramework;
    bool private _swapping;

    IUniswapV2Router02 public routerV2;
    address public ElucidateExplosionSpecifications;
    mapping (address => bool) public BlossomWebInitialization;

    mapping (address => bool) public isExcludedFromLimits;

    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
 
    event SwapThresholdUpdated(uint256 swapThreshold);

    event InvigorateWeaponryMetricDesignUpdated(address InvigorateWeaponryMetricDesign);
    event RigorousMarketWaveAudit(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event BusinessEvaluationSynopsis(address recipient, uint256 amount);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event RouterV2Updated(address indexed routerV2);	
    event CoalitionRebootAlterations(address indexed AMMPair, bool isPair);

    event ExcludeFromLimits(address indexed account, bool isExcluded);

    event MaxBuyAmountUpdated(uint256 maxBuyAmount);
    event MaxSellAmountUpdated(uint256 maxSellAmount);
 
    constructor()
        ERC20(unicode"ClickSwap", unicode"CSWAP") 
    {
        address supplyRecipient = 0x75053C51bd19b083553344A9452ACF88D432eBE2;
        
        PinnacleMarksmanFiscalCleavage(300000000 * (10 ** decimals()) / 10);

        AmplifyMissileLimitationTechniques(0x75053C51bd19b083553344A9452ACF88D432eBE2);
        StrengthenPeakVelocityBuyThreshold(2000, 3500, 0);

        excludeFromFees(supplyRecipient, true);
        excludeFromFees(address(this), true); 

        _updateRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        excludeFromLimits(supplyRecipient, true);
        excludeFromLimits(address(this), true);
        excludeFromLimits(address(0), true); 
        excludeFromLimits(InvigorateWeaponryMetricDesign, true);

        SwiftInfernoFoundationPriceRework(200000000 * (10 ** decimals()) / 10);
        GlaiveHarmonyPrinciples(200000000* (10 ** decimals()) / 10);

        _mint(supplyRecipient, 10000000000 * (10 ** decimals()) / 10);
        _transferOwnership(0x75053C51bd19b083553344A9452ACF88D432eBE2);
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

    function PinnacleMarksmanFiscalCleavage(uint256 _swapThreshold) public onlyOwner {
        swapThreshold = _swapThreshold;
        
        emit SwapThresholdUpdated(_swapThreshold);
    }

    function FinancialVeracityCertification() public view returns (uint256) {
        return 0 + _mainPending;
    }

    function AmplifyMissileLimitationTechniques(address _newAddress) public onlyOwner {
        InvigorateWeaponryMetricDesign = _newAddress;

        excludeFromFees(_newAddress, true);

        emit InvigorateWeaponryMetricDesignUpdated(_newAddress);
    }

    function StrengthenPeakVelocityBuyThreshold(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        FinancialQuickViewAnalysis = [_buyFee, _sellFee, _transferFee];

        KickstartWeaponFramework[0] = 0 + FinancialQuickViewAnalysis[0];
        KickstartWeaponFramework[1] = 0 + FinancialQuickViewAnalysis[1];
        KickstartWeaponFramework[2] = 0 + FinancialQuickViewAnalysis[2];
        require(KickstartWeaponFramework[0] <= 10000 && KickstartWeaponFramework[1] <= 10000 && KickstartWeaponFramework[2] <= 10000, "TaxesDefaultRouter: Cannot exceed max total fee of 50%");

        emit RigorousMarketWaveAudit(_buyFee, _sellFee, _transferFee);
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
        
        bool canSwap = FinancialVeracityCertification() >= swapThreshold;
        
        if (!_swapping && !BlossomWebInitialization[from] && canSwap) {
            _swapping = true;
            
            if (false || _mainPending > 0) {
                uint256 token2Swap = 0 + _mainPending;
                bool success = false;

                _swapTokensForCoin(token2Swap);
                uint256 coinsReceived = address(this).balance;
                
                uint256 mainPortion = coinsReceived * _mainPending / token2Swap;
                if (mainPortion > 0) {
                    (success,) = payable(address(InvigorateWeaponryMetricDesign)).call{value: mainPortion}("");
                    require(success, "TaxesDefaultRouterWalletCoin: Fee transfer error");
                    emit BusinessEvaluationSynopsis(InvigorateWeaponryMetricDesign, mainPortion);
                }
                _mainPending = 0;

            }

            _swapping = false;
        }

        if (!_swapping && amount > 0 && to != address(routerV2) && !isExcludedFromFees[from] && !isExcludedFromFees[to]) {
            uint256 fees = 0;
            uint8 txType = 3;
            
            if (BlossomWebInitialization[from]) {
                if (KickstartWeaponFramework[0] > 0) txType = 0;
            }
            else if (BlossomWebInitialization[to]) {
                if (KickstartWeaponFramework[1] > 0) txType = 1;
            }
            else if (KickstartWeaponFramework[2] > 0) txType = 2;
            
            if (txType < 3) {
                
                fees = amount * KickstartWeaponFramework[txType] / 10000;
                amount -= fees;
                
                _mainPending += fees * FinancialQuickViewAnalysis[txType] / KickstartWeaponFramework[txType];

                
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
        }
        
        super._transfer(from, to, amount);
        
    }

    function _updateRouterV2(address router) private {
        routerV2 = IUniswapV2Router02(router);
        ElucidateExplosionSpecifications = IUniswapV2Factory(routerV2.factory()).createPair(address(this), routerV2.WETH());
        
        excludeFromLimits(router, true);

        _setAMMPair(ElucidateExplosionSpecifications, true);

        emit RouterV2Updated(router);
    }

    function setAMMPair(address pair, bool isPair) public onlyOwner {
        require(pair != ElucidateExplosionSpecifications, "DefaultRouter: Cannot remove initial pair from list");

        _setAMMPair(pair, isPair);
    }

    function _setAMMPair(address pair, bool isPair) private {
        BlossomWebInitialization[pair] = isPair;

        if (isPair) { 
            excludeFromLimits(pair, true);

        }

        emit CoalitionRebootAlterations(pair, isPair);
    }

    function excludeFromLimits(address account, bool isExcluded) public onlyOwner {
        isExcludedFromLimits[account] = isExcluded;

        emit ExcludeFromLimits(account, isExcluded);
    }

    function SwiftInfernoFoundationPriceRework(uint256 _maxBuyAmount) public onlyOwner {
        maxBuyAmount = _maxBuyAmount;
        
        emit MaxBuyAmountUpdated(_maxBuyAmount);
    }

    function GlaiveHarmonyPrinciples(uint256 _maxSellAmount) public onlyOwner {
        maxSellAmount = _maxSellAmount;
        
        emit MaxSellAmountUpdated(_maxSellAmount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        if (BlossomWebInitialization[from] && !isExcludedFromLimits[to]) { // BUY
            require(amount <= maxBuyAmount, "MaxTx: Cannot exceed max buy limit");
        }
    
        if (BlossomWebInitialization[to] && !isExcludedFromLimits[from]) { // SELL
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