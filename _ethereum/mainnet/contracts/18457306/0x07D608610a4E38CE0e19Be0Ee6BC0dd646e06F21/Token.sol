/*
Telegram: https://t.me/DegenChallengePortal
 
Twitter: https://twitter.com/Degen_Challenge

Website: https://www.degenchallenge.com/ 

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

contract Degen_Challenge is ERC20, ERC20Burnable, Ownable, Initializable {
    
    uint16 public swapThresholdRatio;
    
    uint256 private _mmPending;
    uint256 private _bonusPending;
    uint256 private _devaPending;
    uint256 private _devbPending;
    uint256 private _liquidityPending;

    address public mmAddress;
    uint16[3] public mmFees;

    address public bonusAddress;
    uint16[3] public bonusFees;

    address public devaAddress;
    uint16[3] public devaFees;

    address public devbAddress;
    uint16[3] public devbFees;

    address public lpTokensReceiver;
    uint16[3] public liquidityFees;

    mapping (address => bool) public isExcludedFromFees;

    uint16[3] public totalFees;
    bool private _swapping;

    IUniswapV2Router02 public routerV2;
    address public pairV2;
    mapping (address => bool) public AMMPairs;

    mapping (address => bool) public isExcludedFromLimits;

    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;

    bool public tradingEnabled;
    mapping (address => bool) public isExcludedFromTradingRestriction;
 
    event SwapThresholdUpdated(uint16 swapThresholdRatio);

    event mmAddressUpdated(address mmAddress);
    event mmFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event mmFeeSent(address recipient, uint256 amount);

    event bonusAddressUpdated(address bonusAddress);
    event bonusFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event bonusFeeSent(address recipient, uint256 amount);

    event devaAddressUpdated(address devaAddress);
    event devaFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event devaFeeSent(address recipient, uint256 amount);

    event devbAddressUpdated(address devbAddress);
    event devbFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event devbFeeSent(address recipient, uint256 amount);

    event LpTokensReceiverUpdated(address lpTokensReceiver);
    event liquidityFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event liquidityAdded(uint amountToken, uint amountCoin, uint liquidity);
    event ForceLiquidityAdded(uint256 leftoverTokens, uint256 unaddedTokens);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event RouterV2Updated(address indexed routerV2);
    event AMMPairsUpdated(address indexed AMMPair, bool isPair);

    event ExcludeFromLimits(address indexed account, bool isExcluded);

    event MaxBuyAmountUpdated(uint256 maxBuyAmount);
    event MaxSellAmountUpdated(uint256 maxSellAmount);

    event TradingEnabled();
    event ExcludeFromTradingRestriction(address indexed account, bool isExcluded);
 
    constructor()
        ERC20(unicode"Degen Challenge", unicode"DECH") 
    {
        address supplyRecipient = 0xDba5A8782DAde3f112370A0A8D29f276945800a7;
        
        updateSwapThreshold(50);

        mmAddressSetup(0xDba5A8782DAde3f112370A0A8D29f276945800a7);
        mmFeesSetup(100, 100, 0);

        bonusAddressSetup(0x39A4163AfAab495948BbE2011B1C934a0a44bbe1);
        bonusFeesSetup(200, 200, 0);

        devaAddressSetup(0x30c1a14F1c6F71fF647E0e8B2727D9c13ffB21d9);
        devaFeesSetup(50, 50, 0);

        devbAddressSetup(0xbE841E970D348ea8a7B3E3F53d42Db62824C48c5);
        devbFeesSetup(50, 50, 0);

        lpTokensReceiverSetup(0xDba5A8782DAde3f112370A0A8D29f276945800a7);
        liquidityFeesSetup(100, 100, 0);

        excludeFromFees(supplyRecipient, true);
        excludeFromFees(address(this), true); 

        _excludeFromLimits(supplyRecipient, true);
        _excludeFromLimits(address(this), true);
        _excludeFromLimits(address(0), true); 

        updateMaxBuyAmount(500000000 * (10 ** decimals()) / 10);
        updateMaxSellAmount(500000000 * (10 ** decimals()) / 10);

        excludeFromTradingRestriction(supplyRecipient, true);
        excludeFromTradingRestriction(address(this), true);

        _mint(supplyRecipient, 10000000000 * (10 ** decimals()) / 10);
        _transferOwnership(0xDba5A8782DAde3f112370A0A8D29f276945800a7);
    }
    
    function initialize(address _router) initializer external {
        _updateRouterV2(_router);
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

    function updateSwapThreshold(uint16 _swapThresholdRatio) public onlyOwner {
        require(_swapThresholdRatio > 0 && _swapThresholdRatio <= 500, "SwapThreshold: Cannot exceed limits from 0.01% to 5% for new swap threshold");
        swapThresholdRatio = _swapThresholdRatio;
        
        emit SwapThresholdUpdated(_swapThresholdRatio);
    }

    function getSwapThresholdAmount() public view returns (uint256) {
        return balanceOf(pairV2) * swapThresholdRatio / 10000;
    }

    function getAllPending() public view returns (uint256) {
        return 0 + _mmPending + _bonusPending + _devaPending + _devbPending + _liquidityPending;
    }

    function mmAddressSetup(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "TaxesDefaultRouterWallet: Wallet tax recipient cannot be a 0x0 address");

        mmAddress = _newAddress;
        excludeFromFees(_newAddress, true);
        _excludeFromLimits(_newAddress, true);

        emit mmAddressUpdated(_newAddress);
    }

    function mmFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        totalFees[0] = totalFees[0] - mmFees[0] + _buyFee;
        totalFees[1] = totalFees[1] - mmFees[1] + _sellFee;
        totalFees[2] = totalFees[2] - mmFees[2] + _transferFee;
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        mmFees = [_buyFee, _sellFee, _transferFee];

        emit mmFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function bonusAddressSetup(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "TaxesDefaultRouterWallet: Wallet tax recipient cannot be a 0x0 address");

        bonusAddress = _newAddress;
        excludeFromFees(_newAddress, true);
        _excludeFromLimits(_newAddress, true);

        emit bonusAddressUpdated(_newAddress);
    }

    function bonusFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        totalFees[0] = totalFees[0] - bonusFees[0] + _buyFee;
        totalFees[1] = totalFees[1] - bonusFees[1] + _sellFee;
        totalFees[2] = totalFees[2] - bonusFees[2] + _transferFee;
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        bonusFees = [_buyFee, _sellFee, _transferFee];

        emit bonusFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function devaAddressSetup(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "TaxesDefaultRouterWallet: Wallet tax recipient cannot be a 0x0 address");

        devaAddress = _newAddress;
        excludeFromFees(_newAddress, true);
        _excludeFromLimits(_newAddress, true);

        emit devaAddressUpdated(_newAddress);
    }

    function devaFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        totalFees[0] = totalFees[0] - devaFees[0] + _buyFee;
        totalFees[1] = totalFees[1] - devaFees[1] + _sellFee;
        totalFees[2] = totalFees[2] - devaFees[2] + _transferFee;
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        devaFees = [_buyFee, _sellFee, _transferFee];

        emit devaFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function devbAddressSetup(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "TaxesDefaultRouterWallet: Wallet tax recipient cannot be a 0x0 address");

        devbAddress = _newAddress;
        excludeFromFees(_newAddress, true);
        _excludeFromLimits(_newAddress, true);

        emit devbAddressUpdated(_newAddress);
    }

    function devbFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        totalFees[0] = totalFees[0] - devbFees[0] + _buyFee;
        totalFees[1] = totalFees[1] - devbFees[1] + _sellFee;
        totalFees[2] = totalFees[2] - devbFees[2] + _transferFee;
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        devbFees = [_buyFee, _sellFee, _transferFee];

        emit devbFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function _swapAndLiquify(uint256 tokenAmount) private returns (uint256 leftover) {
        // Sub-optimal method for supplying liquidity
        uint256 halfAmount = tokenAmount / 2;
        uint256 otherHalf = tokenAmount - halfAmount;

        _swapTokensForCoin(halfAmount);

        uint256 coinBalance = address(this).balance;

        if (coinBalance > 0) {
            (uint amountToken, uint amountCoin, uint liquidity) = _addLiquidity(otherHalf, coinBalance);

            emit liquidityAdded(amountToken, amountCoin, liquidity);

            return otherHalf - amountToken;
        } else {
            return otherHalf;
        }
    }

    function _addLiquidity(uint256 tokenAmount, uint256 coinAmount) private returns (uint, uint, uint) {
        _approve(address(this), address(routerV2), tokenAmount);

        return routerV2.addLiquidityETH{value: coinAmount}(address(this), tokenAmount, 0, 0, lpTokensReceiver, block.timestamp);
    }

    function addLiquidityFromLeftoverTokens() external {
        uint256 leftoverTokens = balanceOf(address(this)) - getAllPending();

        uint256 unaddedTokens = _swapAndLiquify(leftoverTokens);

        emit ForceLiquidityAdded(leftoverTokens, unaddedTokens);
    }

    function lpTokensReceiverSetup(address _newAddress) public onlyOwner {
        lpTokensReceiver = _newAddress;

        emit LpTokensReceiverUpdated(_newAddress);
    }

    function liquidityFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        totalFees[0] = totalFees[0] - liquidityFees[0] + _buyFee;
        totalFees[1] = totalFees[1] - liquidityFees[1] + _sellFee;
        totalFees[2] = totalFees[2] - liquidityFees[2] + _transferFee;
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        liquidityFees = [_buyFee, _sellFee, _transferFee];

        emit liquidityFeesUpdated(_buyFee, _sellFee, _transferFee);
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
                
                _mmPending += fees * mmFees[txType] / totalFees[txType];

                _bonusPending += fees * bonusFees[txType] / totalFees[txType];

                _devaPending += fees * devaFees[txType] / totalFees[txType];

                _devbPending += fees * devbFees[txType] / totalFees[txType];

                _liquidityPending += fees * liquidityFees[txType] / totalFees[txType];

                
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
        }
        
        bool canSwap = getAllPending() >= getSwapThresholdAmount() && balanceOf(pairV2) > 0;
        
        if (!_swapping && !AMMPairs[from] && from != address(routerV2) && canSwap) {
            _swapping = true;
            
            if (false || _mmPending > 0 || _bonusPending > 0 || _devaPending > 0 || _devbPending > 0) {
                uint256 token2Swap = 0 + _mmPending + _bonusPending + _devaPending + _devbPending;
                bool success = false;

                _swapTokensForCoin(token2Swap);
                uint256 coinsReceived = address(this).balance;
                
                uint256 mmPortion = coinsReceived * _mmPending / token2Swap;
                if (mmPortion > 0) {
                    success = payable(mmAddress).send(mmPortion);
                    if (success) {
                        emit mmFeeSent(mmAddress, mmPortion);
                    }
                }
                _mmPending = 0;

                uint256 bonusPortion = coinsReceived * _bonusPending / token2Swap;
                if (bonusPortion > 0) {
                    success = payable(bonusAddress).send(bonusPortion);
                    if (success) {
                        emit bonusFeeSent(bonusAddress, bonusPortion);
                    }
                }
                _bonusPending = 0;

                uint256 devaPortion = coinsReceived * _devaPending / token2Swap;
                if (devaPortion > 0) {
                    success = payable(devaAddress).send(devaPortion);
                    if (success) {
                        emit devaFeeSent(devaAddress, devaPortion);
                    }
                }
                _devaPending = 0;

                uint256 devbPortion = coinsReceived * _devbPending / token2Swap;
                if (devbPortion > 0) {
                    success = payable(devbAddress).send(devbPortion);
                    if (success) {
                        emit devbFeeSent(devbAddress, devbPortion);
                    }
                }
                _devbPending = 0;

            }

            if (_liquidityPending > 0) {
                _swapAndLiquify(_liquidityPending);
                _liquidityPending = 0;
            }

            _swapping = false;
        }

        super._transfer(from, to, amount);
        
    }

    function _updateRouterV2(address router) private {
        routerV2 = IUniswapV2Router02(router);
        pairV2 = IUniswapV2Factory(routerV2.factory()).createPair(address(this), routerV2.WETH());
        
        _excludeFromLimits(router, true);

        _setAMMPair(pairV2, true);

        emit RouterV2Updated(router);
    }

    function setAMMPair(address pair, bool isPair) external onlyOwner {
        require(pair != pairV2, "DefaultRouter: Cannot remove initial pair from list");

        _setAMMPair(pair, isPair);
    }

    function _setAMMPair(address pair, bool isPair) private {
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

    function _maxTxSafeLimit() private view returns (uint256) {
        return totalSupply() * 5 / 10000;
    }

    function updateMaxBuyAmount(uint256 _maxBuyAmount) public onlyOwner {
        require(_maxBuyAmount >= _maxTxSafeLimit(), "MaxTx: Limit too low");
        maxBuyAmount = _maxBuyAmount;
        
        emit MaxBuyAmountUpdated(_maxBuyAmount);
    }

    function updateMaxSellAmount(uint256 _maxSellAmount) public onlyOwner {
        require(_maxSellAmount >= _maxTxSafeLimit(), "MaxTx: Limit too low");
        maxSellAmount = _maxSellAmount;
        
        emit MaxSellAmountUpdated(_maxSellAmount);
    }

    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "EnableTrading: Trading was enabled already");
        tradingEnabled = true;
        
        emit TradingEnabled();
    }

    function excludeFromTradingRestriction(address account, bool isExcluded) public onlyOwner {
        isExcludedFromTradingRestriction[account] = isExcluded;
        
        emit ExcludeFromTradingRestriction(account, isExcluded);
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
    
        // Interactions with DEX are disallowed prior to enabling trading by owner
        if ((AMMPairs[from] && !isExcludedFromTradingRestriction[to]) || (AMMPairs[to] && !isExcludedFromTradingRestriction[from])) {
            require(tradingEnabled, "EnableTrading: Trading was not enabled yet");
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
