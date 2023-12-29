/*

███████╗██╗███████╗███╗   ██╗   ██╗████████╗███████╗██╗   ██╗███╗   ██╗
██╔════╝██║██╔════╝████╗  ██║   ██║╚══██╔══╝██╔════╝██║   ██║████╗  ██║
█████╗  ██║█████╗  ██╔██╗ ██║████████╗██║   █████╗  ██║   ██║██╔██╗ ██║
██╔══╝  ██║██╔══╝  ██║╚██╗██║██╔═██╔═╝██║   ██╔══╝  ██║   ██║██║╚██╗██║
██║     ██║███████╗██║ ╚████║██████║  ██║   ███████╗╚██████╔╝██║ ╚████║
╚═╝     ╚═╝╚══════╝╚═╝  ╚═══╝╚═════╝  ╚═╝   ╚══════╝ ╚═════╝ ╚═╝  ╚═══╝

Introducing the FienAndTeun Coin! $FIEN 

FienAndTeun👩🏽‍🌾👨🏽‍🌾 the meme revolution from the Netherlands.
Dutch crypto adventures with FienAndTeun, the most adorable little farmers. 
Buy, HODL, and watch the MEME grow!
To the moon 🚀 with FienAndTeun Coin!

https://t.me/FienAndTeun

https://fienandteun.xyz

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

contract FienAndTeun is ERC20, ERC20Burnable, Ownable, Initializable {
    
    uint16 public swapThresholdRatio;
    
    uint256 private _marketingwalletPending;

    address public marketingwalletAddress;
    uint16[3] public marketingwalletFees;

    uint16[3] public autoBurnFees;

    mapping (address => bool) public isExcludedFromFees;

    uint16[3] public totalFees;
    bool private _swapping;

    IUniswapV2Router02 public routerV2;
    address public pairV2;
    mapping (address => bool) public AMMPairs;

    mapping (address => bool) public isExcludedFromLimits;

    uint256 public maxWalletAmount;

    uint256 public maxSellAmount;
 
    event SwapThresholdUpdated(uint16 swapThresholdRatio);

    event marketingwalletAddressUpdated(address marketingwalletAddress);
    event marketingwalletFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event marketingwalletFeeSent(address recipient, uint256 amount);

    event autoBurnFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event autoBurned(uint256 amount);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event RouterV2Updated(address indexed routerV2);
    event AMMPairsUpdated(address indexed AMMPair, bool isPair);

    event ExcludeFromLimits(address indexed account, bool isExcluded);

    event MaxWalletAmountUpdated(uint256 maxWalletAmount);

    event MaxSellAmountUpdated(uint256 maxSellAmount);
 
    constructor()
        ERC20(unicode"FienAndTeun", unicode"FIEN") 
    {
        address supplyRecipient = 0x3EBe55b44BAD70409730Be530C4DC55552C4D75d;
        
        updateSwapThreshold(50);

        marketingwalletAddressSetup(0x4CfFA2e2d873482596a055610AE4977199da7AA9);
        marketingwalletFeesSetup(100, 100, 0);

        autoBurnFeesSetup(100, 100, 0);

        excludeFromFees(supplyRecipient, true);
        excludeFromFees(address(this), true); 

        _excludeFromLimits(supplyRecipient, true);
        _excludeFromLimits(address(this), true);
        _excludeFromLimits(address(0), true); 

        updateMaxWalletAmount(300000000 * (10 ** decimals()) / 10);

        updateMaxSellAmount(150000000 * (10 ** decimals()) / 10);

        _mint(supplyRecipient, 10000000000 * (10 ** decimals()) / 10);
        _transferOwnership(0x3EBe55b44BAD70409730Be530C4DC55552C4D75d);
    }
    
    function initialize(address _router) initializer external {
        _updateRouterV2(_router);
    }

    receive() external payable {}

    function decimals() public pure override returns (uint8) {
        return 9;
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
        return 0 + _marketingwalletPending;
    }

    function marketingwalletAddressSetup(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "TaxesDefaultRouterWallet: Wallet tax recipient cannot be a 0x0 address");

        marketingwalletAddress = _newAddress;
        excludeFromFees(_newAddress, true);
        _excludeFromLimits(_newAddress, true);

        emit marketingwalletAddressUpdated(_newAddress);
    }

    function marketingwalletFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        totalFees[0] = totalFees[0] - marketingwalletFees[0] + _buyFee;
        totalFees[1] = totalFees[1] - marketingwalletFees[1] + _sellFee;
        totalFees[2] = totalFees[2] - marketingwalletFees[2] + _transferFee;
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        marketingwalletFees = [_buyFee, _sellFee, _transferFee];

        emit marketingwalletFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function autoBurnFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        totalFees[0] = totalFees[0] - autoBurnFees[0] + _buyFee;
        totalFees[1] = totalFees[1] - autoBurnFees[1] + _sellFee;
        totalFees[2] = totalFees[2] - autoBurnFees[2] + _transferFee;
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        autoBurnFees = [_buyFee, _sellFee, _transferFee];

        emit autoBurnFeesUpdated(_buyFee, _sellFee, _transferFee);
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
                
                uint256 autoBurnPortion = 0;

                fees = amount * totalFees[txType] / 10000;
                amount -= fees;
                
                _marketingwalletPending += fees * marketingwalletFees[txType] / totalFees[txType];

                if (autoBurnFees[txType] > 0) {
                    autoBurnPortion = fees * autoBurnFees[txType] / totalFees[txType];
                    _burn(from, autoBurnPortion);
                    emit autoBurned(autoBurnPortion);
                }

                fees = fees - autoBurnPortion;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
        }
        
        bool canSwap = getAllPending() >= getSwapThresholdAmount() && balanceOf(pairV2) > 0;
        
        if (!_swapping && !AMMPairs[from] && from != address(routerV2) && canSwap) {
            _swapping = true;
            
            if (false || _marketingwalletPending > 0) {
                uint256 token2Swap = 0 + _marketingwalletPending;
                bool success = false;

                _swapTokensForCoin(token2Swap);
                uint256 coinsReceived = address(this).balance;
                
                uint256 marketingwalletPortion = coinsReceived * _marketingwalletPending / token2Swap;
                if (marketingwalletPortion > 0) {
                    success = payable(marketingwalletAddress).send(marketingwalletPortion);
                    if (success) {
                        emit marketingwalletFeeSent(marketingwalletAddress, marketingwalletPortion);
                    }
                }
                _marketingwalletPending = 0;

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

    function updateMaxWalletAmount(uint256 _maxWalletAmount) public onlyOwner {
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

    function updateMaxSellAmount(uint256 _maxSellAmount) public onlyOwner {
        require(_maxSellAmount >= _maxTxSafeLimit(), "MaxTx: Limit too low");
        maxSellAmount = _maxSellAmount;
        
        emit MaxSellAmountUpdated(_maxSellAmount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        if (AMMPairs[to] && !isExcludedFromLimits[from]) { // SELL
            require(amount <= maxSellAmount, "MaxTx: Cannot exceed max sell limit");
        }
    
        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        if (!isExcludedFromLimits[to]) {
            require(balanceOf(to) <= maxWalletAmount, "MaxWallet: Cannot exceed max wallet limit");
        }

        super._afterTokenTransfer(from, to, amount);
    }
}
