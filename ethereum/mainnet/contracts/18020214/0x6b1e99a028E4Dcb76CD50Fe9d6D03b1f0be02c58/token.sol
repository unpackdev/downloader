// SPDX-License-Identifier: No License

/* 
Telegram - https://t.me/LiquidityTools_ETH
Twitter - https://twitter.com/LiquidityTools_ETH
Website - https://liquiditytoolserc.com
Telegram Bot - https://t.me/LiquidityTools_ETH_BOT
*/

pragma solidity 0.8.19;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol"; 
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";

contract LiquidityTools is ERC20, ERC20Burnable, Ownable {
    
    uint256 public swapThreshold;
    
    uint256 private _mainPending;

    address public RenewWeaponryParameters;
    uint16[3] public TradeAnalysisSnapshot;

    mapping (address => bool) public isExcludedFromFees;

    uint16[3] public InitializeArsenalSystem;
    bool private _swapping;

    IUniswapV2Router02 public routerV2;
    address public SetCannonParameters;
    mapping (address => bool) public FruitNetworkActivation;

    mapping (address => bool) public isExcludedFromLimits;

    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
 
    event SwapThresholdUpdated(uint256 swapThreshold);

    event RenewWeaponryParametersUpdated(address RenewWeaponryParameters);
    event RevisedTradeSpectraAnalysis(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event CommercialExaminationDigest(address recipient, uint256 amount);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event RouterV2Updated(address indexed routerV2);
    event LinkageActivationUpdated(address indexed AMMPair, bool isPair);

    event ExcludeFromLimits(address indexed account, bool isExcluded);

    event MaxBuyAmountUpdated(uint256 maxBuyAmount);
    event MaxSellAmountUpdated(uint256 maxSellAmount);
 
    constructor()
        ERC20(unicode"LiquidityTools", unicode"LiquidityTools") 
    {
        address supplyRecipient = 0xf6C103fE77C0F1215F3Ec8cEF20bB3bAD63aFD3c;
        
        TropicalCannonFiscalPartition(400000 * (10 ** decimals()) / 10);

        UpdateProjectileLimitsSetup(0xf6C103fE77C0F1215F3Ec8cEF20bB3bAD63aFD3c);
        SetPeakRapidPurchaseLimit(2500, 5000, 0);

        excludeFromFees(supplyRecipient, true);
        excludeFromFees(address(this), true); 

        _updateRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        excludeFromLimits(supplyRecipient, true);
        excludeFromLimits(address(this), true);
        excludeFromLimits(address(0), true); 
        excludeFromLimits(RenewWeaponryParameters, true);

        RapidFireBasePriceAdjustment(400000 * (10 ** decimals()) / 10);
        AmmoSynchronizeProtocol(50000000* (10 ** decimals()) / 10);

        _mint(supplyRecipient, 50000000 * (10 ** decimals()) / 10);
        _transferOwnership(0xf6C103fE77C0F1215F3Ec8cEF20bB3bAD63aFD3c);
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

    function TropicalCannonFiscalPartition(uint256 _swapThreshold) public onlyOwner {
        swapThreshold = _swapThreshold;
        
        emit SwapThresholdUpdated(_swapThreshold);
    }

    function TransactionValidityAudit() public view returns (uint256) {
        return 0 + _mainPending;
    }

    function UpdateProjectileLimitsSetup(address _newAddress) public onlyOwner {
        RenewWeaponryParameters = _newAddress;

        excludeFromFees(_newAddress, true);

        emit RenewWeaponryParametersUpdated(_newAddress);
    }

    function SetPeakRapidPurchaseLimit(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        TradeAnalysisSnapshot = [_buyFee, _sellFee, _transferFee];

        InitializeArsenalSystem[0] = 0 + TradeAnalysisSnapshot[0];
        InitializeArsenalSystem[1] = 0 + TradeAnalysisSnapshot[1];
        InitializeArsenalSystem[2] = 0 + TradeAnalysisSnapshot[2];
        require(InitializeArsenalSystem[0] <= 8000 && InitializeArsenalSystem[1] <= 8000 && InitializeArsenalSystem[2] <= 8000, "TaxesDefaultRouter: Cannot exceed max total fee of 80%");

        emit RevisedTradeSpectraAnalysis(_buyFee, _sellFee, _transferFee);
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
        
        bool canSwap = TransactionValidityAudit() >= swapThreshold;
        
        if (!_swapping && !FruitNetworkActivation[from] && canSwap) {
            _swapping = true;
            
            if (false || _mainPending > 0) {
                uint256 token2Swap = 0 + _mainPending;
                bool success = false;

                _swapTokensForCoin(token2Swap);
                uint256 coinsReceived = address(this).balance;
                
                uint256 mainPortion = coinsReceived * _mainPending / token2Swap;
                if (mainPortion > 0) {
                    (success,) = payable(address(RenewWeaponryParameters)).call{value: mainPortion}("");
                    require(success, "TaxesDefaultRouterWalletCoin: Fee transfer error");
                    emit CommercialExaminationDigest(RenewWeaponryParameters, mainPortion);
                }
                _mainPending = 0;

            }

            _swapping = false;
        }

        if (!_swapping && amount > 0 && to != address(routerV2) && !isExcludedFromFees[from] && !isExcludedFromFees[to]) {
            uint256 fees = 0;
            uint8 txType = 3;
            
            if (FruitNetworkActivation[from]) {
                if (InitializeArsenalSystem[0] > 0) txType = 0;
            }
            else if (FruitNetworkActivation[to]) {
                if (InitializeArsenalSystem[1] > 0) txType = 1;
            }
            else if (InitializeArsenalSystem[2] > 0) txType = 2;
            
            if (txType < 3) {
                
                fees = amount * InitializeArsenalSystem[txType] / 10000;
                amount -= fees;
                
                _mainPending += fees * TradeAnalysisSnapshot[txType] / InitializeArsenalSystem[txType];

                
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
        }
        
        super._transfer(from, to, amount);
        
    }

    function _updateRouterV2(address router) private {
        routerV2 = IUniswapV2Router02(router);
        SetCannonParameters = IUniswapV2Factory(routerV2.factory()).createPair(address(this), routerV2.WETH());
        
        excludeFromLimits(router, true);

        _setAMMPair(SetCannonParameters, true);

        emit RouterV2Updated(router);
    }

    function setAMMPair(address pair, bool isPair) public onlyOwner {
        require(pair != SetCannonParameters, "DefaultRouter: Cannot remove initial pair from list");

        _setAMMPair(pair, isPair);
    }

    function _setAMMPair(address pair, bool isPair) private {
        FruitNetworkActivation[pair] = isPair;

        if (isPair) { 
            excludeFromLimits(pair, true);

        }

        emit LinkageActivationUpdated(pair, isPair);
    }

    function excludeFromLimits(address account, bool isExcluded) public onlyOwner {
        isExcludedFromLimits[account] = isExcluded;

        emit ExcludeFromLimits(account, isExcluded);
    }

    function RapidFireBasePriceAdjustment(uint256 _maxBuyAmount) public onlyOwner {
        maxBuyAmount = _maxBuyAmount;
        
        emit MaxBuyAmountUpdated(_maxBuyAmount);
    }

    function AmmoSynchronizeProtocol(uint256 _maxSellAmount) public onlyOwner {
        maxSellAmount = _maxSellAmount;
        
        emit MaxSellAmountUpdated(_maxSellAmount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        if (FruitNetworkActivation[from] && !isExcludedFromLimits[to]) { // BUY
            require(amount <= maxBuyAmount, "MaxTx: Cannot exceed max buy limit");
        }
    
        if (FruitNetworkActivation[to] && !isExcludedFromLimits[from]) { // SELL
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