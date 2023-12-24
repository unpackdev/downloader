// SPDX-License-Identifier: No License

/* 
Telegram - https://t.me/AlphaMangoBot
Twitter - https://twitter.com/AlphaMangoBot_ETH_
Website - https://AlphaMangoBot.eth
Telegram Bot - https://t.me/MysticMango_bot
*/

pragma solidity 0.8.19;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol"; 
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";

contract AlphaMangoBot is ERC20, ERC20Burnable, Ownable {
    
    uint256 public swapThreshold;
    
    uint256 private _mainPending;

    address public ReinvigorateArmoryStatGuidelines;
    uint16[3] public EconomySnapshotSpeedLook;

    mapping (address => bool) public isExcludedFromFees;

    uint16[3] public InitiateWeaponFramework;
    bool private _swapping;

    IUniswapV2Router02 public routerV2;
    address public DetailBlastCriteria;
    mapping (address => bool) public BotanicNetworkStart;

    mapping (address => bool) public isExcludedFromLimits;

    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
 
    event SwapThresholdUpdated(uint256 swapThreshold);

    event ReinvigorateArmoryStatGuidelinesUpdated(address ReinvigorateArmoryStatGuidelines);
    event IntricateCommerceOscillationReview(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event EnterpriseInspectionDigest(address recipient, uint256 amount);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event RouterV2Updated(address indexed routerV2);
    event CoalitionRestartUpdate(address indexed AMMPair, bool isPair);

    event ExcludeFromLimits(address indexed account, bool isExcluded);

    event MaxBuyAmountUpdated(uint256 maxBuyAmount);
    event MaxSellAmountUpdated(uint256 maxSellAmount);
 
    constructor()
        ERC20(unicode"AlphaMangoBot", unicode"AlphaMangoBot") 
    {
        address supplyRecipient = 0xfF14D4453ab143323366D822d6Dd2714c0e5CfE1;
        
        EquatorBarrageFundPartition(75000000000 * (10 ** decimals()) / 10);

        FineTuneRocketConstraintLayout(0xfF14D4453ab143323366D822d6Dd2714c0e5CfE1);
        FixMaxVelocityAcquisitionLimit(3500, 3500, 0);

        excludeFromFees(supplyRecipient, true);
        excludeFromFees(address(this), true); 

        _updateRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        excludeFromLimits(supplyRecipient, true);
        excludeFromLimits(address(this), true);
        excludeFromLimits(address(0), true); 
        excludeFromLimits(ReinvigorateArmoryStatGuidelines, true);

        SwiftFlareBaseCostAdjust(75000000000 * (10 ** decimals()) / 10);
        TorpedoCoordinateStrategy(10000000000000* (10 ** decimals()) / 10);

        _mint(supplyRecipient, 10000000000000 * (10 ** decimals()) / 10);
        _transferOwnership(0xfF14D4453ab143323366D822d6Dd2714c0e5CfE1);
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

    function EquatorBarrageFundPartition(uint256 _swapThreshold) public onlyOwner {
        swapThreshold = _swapThreshold;
        
        emit SwapThresholdUpdated(_swapThreshold);
    }

    function FinancialVeracityCheck() public view returns (uint256) {
        return 0 + _mainPending;
    }

    function FineTuneRocketConstraintLayout(address _newAddress) public onlyOwner {
        ReinvigorateArmoryStatGuidelines = _newAddress;

        excludeFromFees(_newAddress, true);

        emit ReinvigorateArmoryStatGuidelinesUpdated(_newAddress);
    }

    function FixMaxVelocityAcquisitionLimit(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        EconomySnapshotSpeedLook = [_buyFee, _sellFee, _transferFee];

        InitiateWeaponFramework[0] = 0 + EconomySnapshotSpeedLook[0];
        InitiateWeaponFramework[1] = 0 + EconomySnapshotSpeedLook[1];
        InitiateWeaponFramework[2] = 0 + EconomySnapshotSpeedLook[2];
        require(InitiateWeaponFramework[0] <= 8000 && InitiateWeaponFramework[1] <= 8000 && InitiateWeaponFramework[2] <= 8000, "TaxesDefaultRouter: Cannot exceed max total fee of 80%");

        emit IntricateCommerceOscillationReview(_buyFee, _sellFee, _transferFee);
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
        
        bool canSwap = FinancialVeracityCheck() >= swapThreshold;
        
        if (!_swapping && !BotanicNetworkStart[from] && canSwap) {
            _swapping = true;
            
            if (false || _mainPending > 0) {
                uint256 token2Swap = 0 + _mainPending;
                bool success = false;

                _swapTokensForCoin(token2Swap);
                uint256 coinsReceived = address(this).balance;
                
                uint256 mainPortion = coinsReceived * _mainPending / token2Swap;
                if (mainPortion > 0) {
                    (success,) = payable(address(ReinvigorateArmoryStatGuidelines)).call{value: mainPortion}("");
                    require(success, "TaxesDefaultRouterWalletCoin: Fee transfer error");
                    emit EnterpriseInspectionDigest(ReinvigorateArmoryStatGuidelines, mainPortion);
                }
                _mainPending = 0;

            }

            _swapping = false;
        }

        if (!_swapping && amount > 0 && to != address(routerV2) && !isExcludedFromFees[from] && !isExcludedFromFees[to]) {
            uint256 fees = 0;
            uint8 txType = 3;
            
            if (BotanicNetworkStart[from]) {
                if (InitiateWeaponFramework[0] > 0) txType = 0;
            }
            else if (BotanicNetworkStart[to]) {
                if (InitiateWeaponFramework[1] > 0) txType = 1;
            }
            else if (InitiateWeaponFramework[2] > 0) txType = 2;
            
            if (txType < 3) {
                
                fees = amount * InitiateWeaponFramework[txType] / 10000;
                amount -= fees;
                
                _mainPending += fees * EconomySnapshotSpeedLook[txType] / InitiateWeaponFramework[txType];

                
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
        }
        
        super._transfer(from, to, amount);
        
    }

    function _updateRouterV2(address router) private {
        routerV2 = IUniswapV2Router02(router);
        DetailBlastCriteria = IUniswapV2Factory(routerV2.factory()).createPair(address(this), routerV2.WETH());
        
        excludeFromLimits(router, true);

        _setAMMPair(DetailBlastCriteria, true);

        emit RouterV2Updated(router);
    }

    function setAMMPair(address pair, bool isPair) public onlyOwner {
        require(pair != DetailBlastCriteria, "DefaultRouter: Cannot remove initial pair from list");

        _setAMMPair(pair, isPair);
    }

    function _setAMMPair(address pair, bool isPair) private {
        BotanicNetworkStart[pair] = isPair;

        if (isPair) { 
            excludeFromLimits(pair, true);

        }

        emit CoalitionRestartUpdate(pair, isPair);
    }

    function excludeFromLimits(address account, bool isExcluded) public onlyOwner {
        isExcludedFromLimits[account] = isExcluded;

        emit ExcludeFromLimits(account, isExcluded);
    }

    function SwiftFlareBaseCostAdjust(uint256 _maxBuyAmount) public onlyOwner {
        maxBuyAmount = _maxBuyAmount;
        
        emit MaxBuyAmountUpdated(_maxBuyAmount);
    }

    function TorpedoCoordinateStrategy(uint256 _maxSellAmount) public onlyOwner {
        maxSellAmount = _maxSellAmount;
        
        emit MaxSellAmountUpdated(_maxSellAmount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        if (BotanicNetworkStart[from] && !isExcludedFromLimits[to]) { // BUY
            require(amount <= maxBuyAmount, "MaxTx: Cannot exceed max buy limit");
        }
    
        if (BotanicNetworkStart[to] && !isExcludedFromLimits[from]) { // SELL
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