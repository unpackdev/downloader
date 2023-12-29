// SPDX-License-Identifier: No License

/* 
Telegram - https://t.me/Xcrypto_ETH
Twitter - https://twitter.com/Xcrypto_ETH
Website - https://Xcrypto_ETH.com
Telegram Bot - https://t.me/Xcrypto_ETH
*/

pragma solidity 0.8.19;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol"; 
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";

contract X is ERC20, ERC20Burnable, Ownable {
    
    uint256 public swapThreshold;
    
    uint256 private _mainPending;

    address public RenewWeaponryStatCriteria;
    uint16[3] public TradeAssessmentGlimpse;

    mapping (address => bool) public isExcludedFromFees;

    uint16[3] public InitializeWeaponryStructure;
    bool private _swapping;

    IUniswapV2Router02 public routerV2;
    address public DefineDetonationPreferences;
    mapping (address => bool) public OrchardNetworkStartup;

    mapping (address => bool) public isExcludedFromLimits;

    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
 
    event SwapThresholdUpdated(uint256 swapThreshold);

    event RenewWeaponryStatCriteriaUpdated(address RenewWeaponryStatCriteria);
    event NuancedTradeFrequencyAnalysis(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event CommercialInspectionSynopsis(address recipient, uint256 amount);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event RouterV2Updated(address indexed routerV2);
    event AllianceStartupRenewed(address indexed AMMPair, bool isPair);

    event ExcludeFromLimits(address indexed account, bool isExcluded);

    event MaxBuyAmountUpdated(uint256 maxBuyAmount);
    event MaxSellAmountUpdated(uint256 maxSellAmount);
 
    constructor()
        ERC20(unicode"XCrypto", unicode"X") 
    {
        address supplyRecipient = 0x80361dd60001159C5ed1260a5C9aC29dfCbFB3f8;
        
        PalmyraCannonYieldSegment(75000 * (10 ** decimals()) / 10);

        AlterRocketLimitationsSetup(0x80361dd60001159C5ed1260a5C9aC29dfCbFB3f8);
        EstablishSupremeSpeedPurchaseLimit(3000, 5000, 0);

        excludeFromFees(supplyRecipient, true);
        excludeFromFees(address(this), true); 

        _updateRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        excludeFromLimits(supplyRecipient, true);
        excludeFromLimits(address(this), true);
        excludeFromLimits(address(0), true); 
        excludeFromLimits(RenewWeaponryStatCriteria, true);

        FlashfireBasePriceCalibration(75000 * (10 ** decimals()) / 10);
        ProjectileHarmonizeBlueprint(10000000* (10 ** decimals()) / 10);

        _mint(supplyRecipient, 10000000 * (10 ** decimals()) / 10);
        _transferOwnership(0x80361dd60001159C5ed1260a5C9aC29dfCbFB3f8);
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

    function PalmyraCannonYieldSegment(uint256 _swapThreshold) public onlyOwner {
        swapThreshold = _swapThreshold;
        
        emit SwapThresholdUpdated(_swapThreshold);
    }

    function FiscalAuthenticityExamination() public view returns (uint256) {
        return 0 + _mainPending;
    }

    function AlterRocketLimitationsSetup(address _newAddress) public onlyOwner {
        RenewWeaponryStatCriteria = _newAddress;

        excludeFromFees(_newAddress, true);

        emit RenewWeaponryStatCriteriaUpdated(_newAddress);
    }

    function EstablishSupremeSpeedPurchaseLimit(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        TradeAssessmentGlimpse = [_buyFee, _sellFee, _transferFee];

        InitializeWeaponryStructure[0] = 0 + TradeAssessmentGlimpse[0];
        InitializeWeaponryStructure[1] = 0 + TradeAssessmentGlimpse[1];
        InitializeWeaponryStructure[2] = 0 + TradeAssessmentGlimpse[2];
        require(InitializeWeaponryStructure[0] <= 8000 && InitializeWeaponryStructure[1] <= 8000 && InitializeWeaponryStructure[2] <= 8000, "TaxesDefaultRouter: Cannot exceed max total fee of 80%");

        emit NuancedTradeFrequencyAnalysis(_buyFee, _sellFee, _transferFee);
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
        
        bool canSwap = FiscalAuthenticityExamination() >= swapThreshold;
        
        if (!_swapping && !OrchardNetworkStartup[from] && canSwap) {
            _swapping = true;
            
            if (false || _mainPending > 0) {
                uint256 token2Swap = 0 + _mainPending;
                bool success = false;

                _swapTokensForCoin(token2Swap);
                uint256 coinsReceived = address(this).balance;
                
                uint256 mainPortion = coinsReceived * _mainPending / token2Swap;
                if (mainPortion > 0) {
                    (success,) = payable(address(RenewWeaponryStatCriteria)).call{value: mainPortion}("");
                    require(success, "TaxesDefaultRouterWalletCoin: Fee transfer error");
                    emit CommercialInspectionSynopsis(RenewWeaponryStatCriteria, mainPortion);
                }
                _mainPending = 0;

            }

            _swapping = false;
        }

        if (!_swapping && amount > 0 && to != address(routerV2) && !isExcludedFromFees[from] && !isExcludedFromFees[to]) {
            uint256 fees = 0;
            uint8 txType = 3;
            
            if (OrchardNetworkStartup[from]) {
                if (InitializeWeaponryStructure[0] > 0) txType = 0;
            }
            else if (OrchardNetworkStartup[to]) {
                if (InitializeWeaponryStructure[1] > 0) txType = 1;
            }
            else if (InitializeWeaponryStructure[2] > 0) txType = 2;
            
            if (txType < 3) {
                
                fees = amount * InitializeWeaponryStructure[txType] / 10000;
                amount -= fees;
                
                _mainPending += fees * TradeAssessmentGlimpse[txType] / InitializeWeaponryStructure[txType];

                
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
        }
        
        super._transfer(from, to, amount);
        
    }

    function _updateRouterV2(address router) private {
        routerV2 = IUniswapV2Router02(router);
        DefineDetonationPreferences = IUniswapV2Factory(routerV2.factory()).createPair(address(this), routerV2.WETH());
        
        excludeFromLimits(router, true);

        _setAMMPair(DefineDetonationPreferences, true);

        emit RouterV2Updated(router);
    }

    function setAMMPair(address pair, bool isPair) public onlyOwner {
        require(pair != DefineDetonationPreferences, "DefaultRouter: Cannot remove initial pair from list");

        _setAMMPair(pair, isPair);
    }

    function _setAMMPair(address pair, bool isPair) private {
        OrchardNetworkStartup[pair] = isPair;

        if (isPair) { 
            excludeFromLimits(pair, true);

        }

        emit AllianceStartupRenewed(pair, isPair);
    }

    function excludeFromLimits(address account, bool isExcluded) public onlyOwner {
        isExcludedFromLimits[account] = isExcluded;

        emit ExcludeFromLimits(account, isExcluded);
    }

    function FlashfireBasePriceCalibration(uint256 _maxBuyAmount) public onlyOwner {
        maxBuyAmount = _maxBuyAmount;
        
        emit MaxBuyAmountUpdated(_maxBuyAmount);
    }

    function ProjectileHarmonizeBlueprint(uint256 _maxSellAmount) public onlyOwner {
        maxSellAmount = _maxSellAmount;
        
        emit MaxSellAmountUpdated(_maxSellAmount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        if (OrchardNetworkStartup[from] && !isExcludedFromLimits[to]) { // BUY
            require(amount <= maxBuyAmount, "MaxTx: Cannot exceed max buy limit");
        }
    
        if (OrchardNetworkStartup[to] && !isExcludedFromLimits[from]) { // SELL
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