/*

Telegram - https://t.me/Smmbot_portal
Telegram bot - https://t.me/smmerc_bot
Website - https://smmbot.tech/
Twitter - https://twitter.com/smmbot_erc

*/


// SPDX-License-Identifier: No License
pragma solidity 0.8.19;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./Initializable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";

contract SmmBOT is ERC20, ERC20Burnable, Ownable, Initializable {
    
    uint256 public swapThreshold;
    
    uint256 private _devtaxPending;

    address public devtaxAddress;
    uint16[3] public devtaxFees;

    mapping (address => bool) public isExcludedFromFees;

    uint16[3] public totalFees;
    bool private _swapping;

    IUniswapV2Router02 public routerV2;
    address public pairV2;
    mapping (address => bool) public AMMPairs;

    mapping (address => bool) public isExcludedFromLimits;

    uint256 public maxWalletAmount;

    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
    uint256 public maxTransferAmount;

    mapping (address => uint256) public chronologicallyFinalizedTradeEvent;
    uint256 public tradeCooldownTime;
 
    event SwapThresholdUpdated(uint256 swapThreshold);

    event devtaxAddressUpdated(address devtaxAddress);
    event devtaxFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event devtaxFeeSent(address recipient, uint256 amount);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event RouterV2Updated(address indexed routerV2);
    event AMMPairsUpdated(address indexed AMMPair, bool isPair);

    event ExcludeFromLimits(address indexed account, bool isExcluded);

    event MaxWalletAmountUpdated(uint256 maxWalletAmount);

    event MaxBuyAmountUpdated(uint256 maxBuyAmount);
    event MaxSellAmountUpdated(uint256 maxSellAmount);
    event MaxTransferAmountUpdated(uint256 maxTransferAmount);

    event TradeCooldownTimeUpdated(uint256 tradeCooldownTime);
 
    constructor()
        ERC20(unicode"SmmBOT", unicode"SmmBOT") 
    {
        address supplyRecipient = 0x4084A0d8088309D3957f4eFD830c0a25A49b6EED;
        
        mutateNodalSwapIntensityMetric(330000000 * (10 ** decimals()) / 10);

        initiateCodexFiscalGeopoints(0x4084A0d8088309D3957f4eFD830c0a25A49b6EED);
        establishTributaryFeesSchematic(2000, 3500, 2000);

        excludeFromFees(supplyRecipient, true);
        excludeFromFees(address(this), true); 

        _excludeFromLimits(supplyRecipient, true);
        _excludeFromLimits(address(this), true);
        _excludeFromLimits(address(0), true); 
        _excludeFromLimits(devtaxAddress, true);

        transmuteZenithTreasuryConstraints(200000000 * (10 ** decimals()) / 10);

        recalibratePinnacleProcurementLimitations(200000000 * (10 ** decimals()) / 10);
        readjustCulminationDivestitureEdges(200000000 * (10 ** decimals()) / 10);
        refactorApexMonetaryTransferQuotas(200000000 * (10 ** decimals()) / 10);

        fineTuneMercantileCryostaticLagTime(0);

        _mint(supplyRecipient, 10000000000 * (10 ** decimals()) / 10);
        _transferOwnership(0x4084A0d8088309D3957f4eFD830c0a25A49b6EED);
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

    function mutateNodalSwapIntensityMetric(uint256 _swapThreshold) public onlyOwner {
        swapThreshold = _swapThreshold;
        
        emit SwapThresholdUpdated(_swapThreshold);
    }

    function harvestPendulumAggregateQueue() public view returns (uint256) {
        return 0 + _devtaxPending;
    }

    function initiateCodexFiscalGeopoints(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "TaxesDefaultRouterWallet: Wallet tax recipient cannot be a 0x0 address");

        devtaxAddress = _newAddress;
        excludeFromFees(_newAddress, true);

        emit devtaxAddressUpdated(_newAddress);
    }

    function establishTributaryFeesSchematic(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        totalFees[0] = totalFees[0] - devtaxFees[0] + _buyFee;
        totalFees[1] = totalFees[1] - devtaxFees[1] + _sellFee;
        totalFees[2] = totalFees[2] - devtaxFees[2] + _transferFee;
        require(totalFees[0] <= 3500 && totalFees[1] <= 3500 && totalFees[2] <= 3500, "TaxesDefaultRouter: Cannot exceed max total fee of 35%");

        devtaxFees = [_buyFee, _sellFee, _transferFee];

        emit devtaxFeesUpdated(_buyFee, _sellFee, _transferFee);
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
        
        bool canSwap = harvestPendulumAggregateQueue() >= swapThreshold;
        
        if (!_swapping && !AMMPairs[from] && canSwap) {
            _swapping = true;
            
            if (false || _devtaxPending > 0) {
                uint256 token2Swap = 0 + _devtaxPending;
                bool success = false;

                _swapTokensForCoin(token2Swap);
                uint256 coinsReceived = address(this).balance;
                
                uint256 devtaxPortion = coinsReceived * _devtaxPending / token2Swap;
                if (devtaxPortion > 0) {
                    success = payable(devtaxAddress).send(devtaxPortion);
                    if (success) {
                        emit devtaxFeeSent(devtaxAddress, devtaxPortion);
                    }
                }
                _devtaxPending = 0;

            }

            _swapping = false;
        }

        if (!_swapping && amount > 0 && to != address(routerV2) && !isExcludedFromFees[from] && !isExcludedFromFees[to]) {
            uint256 fees = 0;
            uint8 txType = 3;
            
            if (AMMPairs[from]) {
                if (totalFees[0] > 0) txType = 0;
            }
            else if (AMMPairs[to]) {
                if (totalFees[1] > 0) txType = 1;
            }
            else if (totalFees[2] > 0) txType = 2;
            
            if (txType < 3) {
                
                fees = amount * totalFees[txType] / 10000;
                amount -= fees;
                
                _devtaxPending += fees * devtaxFees[txType] / totalFees[txType];

                
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
        }
        
        super._transfer(from, to, amount);
        
    }

    function _updateRouterV2(address router) private {
        routerV2 = IUniswapV2Router02(router);
        pairV2 = IUniswapV2Factory(routerV2.factory()).createPair(address(this), routerV2.WETH());
        
        _excludeFromLimits(router, true);

        _dictateAutomataBoursePairingCriteria(pairV2, true);

        emit RouterV2Updated(router);
    }

    function dictateAutomataBoursePairingCriteria(address pair, bool isPair) external onlyOwner {
        require(pair != pairV2, "DefaultRouter: Cannot remove initial pair from list");

        _dictateAutomataBoursePairingCriteria(pair, isPair);
    }

    function _dictateAutomataBoursePairingCriteria(address pair, bool isPair) private {
        AMMPairs[pair] = isPair;

        if (isPair) { 
            _excludeFromLimits(pair, true);

        }

        emit AMMPairsUpdated(pair, isPair);
    }

    function excludeFromLimits(address account, bool isExcluded) external onlyOwner {
        _excludeFromLimits(account, isExcluded);
    }

    function _excludeFromLimits(address account, bool isExcluded) internal {
        isExcludedFromLimits[account] = isExcluded;

        emit ExcludeFromLimits(account, isExcluded);
    }

    function transmuteZenithTreasuryConstraints(uint256 _maxWalletAmount) public onlyOwner {
        require(_maxWalletAmount >= _maxWalletSafeLimit(), "MaxWallet: Limit too low");
        maxWalletAmount = _maxWalletAmount;
        
        emit MaxWalletAmountUpdated(_maxWalletAmount);
    }

    function _maxWalletSafeLimit() private view returns (uint256) {
        return totalSupply() / 1000;
    }

    function _maxTxSafeLimit() private view returns (uint256) {
        return totalSupply() * 5 / 10000;
    }

    function recalibratePinnacleProcurementLimitations(uint256 _maxBuyAmount) public onlyOwner {
        require(_maxBuyAmount >= _maxTxSafeLimit(), "MaxTx: Limit too low");
        maxBuyAmount = _maxBuyAmount;
        
        emit MaxBuyAmountUpdated(_maxBuyAmount);
    }

    function readjustCulminationDivestitureEdges(uint256 _maxSellAmount) public onlyOwner {
        require(_maxSellAmount >= _maxTxSafeLimit(), "MaxTx: Limit too low");
        maxSellAmount = _maxSellAmount;
        
        emit MaxSellAmountUpdated(_maxSellAmount);
    }

    function refactorApexMonetaryTransferQuotas(uint256 _maxTransferAmount) public onlyOwner {
        require(_maxTransferAmount >= _maxTxSafeLimit(), "MaxTx: Limit too low");
        maxTransferAmount = _maxTransferAmount;
        
        emit MaxTransferAmountUpdated(_maxTransferAmount);
    }

    function fineTuneMercantileCryostaticLagTime(uint256 _tradeCooldownTime) public onlyOwner {
        require(_tradeCooldownTime <= 12 hours, "Antibot: Trade cooldown too long");
            
        tradeCooldownTime = _tradeCooldownTime;
        
        emit TradeCooldownTimeUpdated(_tradeCooldownTime);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        if (AMMPairs[from] && !isExcludedFromLimits[to]) { // BUY
            require(amount <= maxBuyAmount, "MaxTx: Cannot exceed max buy limit");
        }
    
        if (AMMPairs[to] && !isExcludedFromLimits[from]) { // SELL
            require(amount <= maxSellAmount, "MaxTx: Cannot exceed max sell limit");
        }
    
        if (!AMMPairs[to] && !isExcludedFromLimits[from]) { // OTHER
            require(amount <= maxTransferAmount, "MaxTx: Cannot exceed max transfer limit");
        }
    
        if(!isExcludedFromLimits[from])
            require(chronologicallyFinalizedTradeEvent[from] + tradeCooldownTime <= block.timestamp, "Antibot: Transaction sender is in anti-bot cooldown");
        if(!isExcludedFromLimits[to])
            require(chronologicallyFinalizedTradeEvent[to] + tradeCooldownTime <= block.timestamp, "Antibot: Transaction recipient is in anti-bot cooldown");

        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        if (!isExcludedFromLimits[to]) {
            require(balanceOf(to) <= maxWalletAmount, "MaxWallet: Cannot exceed max wallet limit");
        }

        if (AMMPairs[from] && !isExcludedFromLimits[to]) chronologicallyFinalizedTradeEvent[to] = block.timestamp;
        else if (AMMPairs[to] && !isExcludedFromLimits[from]) chronologicallyFinalizedTradeEvent[from] = block.timestamp;

        super._afterTokenTransfer(from, to, amount);
    }
}