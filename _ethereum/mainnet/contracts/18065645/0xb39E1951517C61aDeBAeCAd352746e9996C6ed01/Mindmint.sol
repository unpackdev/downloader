// SPDX-License-Identifier: No License
pragma solidity 0.8.10;

import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";

import "./Pausable.sol";

contract Mindmint is ERC20, ERC20Burnable, Ownable, Pausable {
    
    mapping (address => bool) public blacklisted;

    uint256 public swapThreshold;
    
    uint256 private _taxwalletPending;

    address public taxwalletAddress;
    uint16[3] public taxwalletFees;

    mapping (address => bool) public isExcludedFromFees;

    uint16[3] public totalFees;
    bool private _swapping;

    IUniswapV2Router02 public routerV2;
    address public pairV2;
    mapping (address => bool) public AMMPairs;

    mapping (address => bool) public isExcludedFromLimits;

    uint256 public maxSellAmount;
    uint256 public maxTransferAmount;
 
    event BlacklistUpdated(address indexed account, bool isBlacklisted);

    event SwapThresholdUpdated(uint256 swapThreshold);

    event taxwalletAddressUpdated(address taxwalletAddress);
    event taxwalletFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event taxwalletFeeSent(address recipient, uint256 amount);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event RouterV2Updated(address indexed routerV2);
    event AMMPairsUpdated(address indexed AMMPair, bool isPair);

    event ExcludeFromLimits(address indexed account, bool isExcluded);

    event MaxSellAmountUpdated(uint256 maxSellAmount);
    event MaxTransferAmountUpdated(uint256 maxTransferAmount);
 
    constructor()
        ERC20(unicode"Mindmint", unicode"MMT") 
    {
        address supplyRecipient = 0xD21F72dEe6DdE13eE01B73819E302b239e4f74Ca;
        
        updateSwapThreshold(5000000 * (10 ** decimals()) / 10);

        taxwalletAddressSetup(0x8C516F774634a0B9bdB2E0Fe4130eF1160640e49);
        taxwalletFeesSetup(0, 0, 0);

        excludeFromFees(supplyRecipient, true);
        excludeFromFees(address(this), true); 

        _excludeFromLimits(supplyRecipient, true);
        _excludeFromLimits(address(this), true);
        _excludeFromLimits(address(0), true); 
        _excludeFromLimits(taxwalletAddress, true);

        updateMaxSellAmount(10000000 * (10 ** decimals()) / 10);
        updateMaxTransferAmount(10000000 * (10 ** decimals()) / 10);

        _mint(supplyRecipient, 10000000000 * (10 ** decimals()) / 10);
        _transferOwnership(0xD21F72dEe6DdE13eE01B73819E302b239e4f74Ca);
    }

    receive() external payable {}

    function decimals() public pure override returns (uint8) {
        return 18;
    }
    
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function blacklist(address account, bool isBlacklisted) external onlyOwner {
        blacklisted[account] = isBlacklisted;
        emit BlacklistUpdated(account, isBlacklisted);
    }

    function _swapTokensForCoin(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = routerV2.WETH();

        _approve(address(this), address(routerV2), tokenAmount);
        routerV2.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function updateSwapThreshold(uint256 _swapThreshold) public onlyOwner {
        swapThreshold = _swapThreshold;
        emit SwapThresholdUpdated(_swapThreshold);
    }

    function getAllPending() public view returns (uint256) {
        return 0 + _taxwalletPending;
    }

    function taxwalletAddressSetup(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "TaxesDefaultRouterWallet: Wallet tax recipient cannot be a 0x0 address");
        taxwalletAddress = _newAddress;
        excludeFromFees(_newAddress, true);
        emit taxwalletAddressUpdated(_newAddress);
    }

    function taxwalletFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        totalFees[0] = totalFees[0] - taxwalletFees[0] + _buyFee;
        totalFees[1] = totalFees[1] - taxwalletFees[1] + _sellFee;
        totalFees[2] = totalFees[2] - taxwalletFees[2] + _transferFee;
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");
        taxwalletFees = [_buyFee, _sellFee, _transferFee];
        emit taxwalletFeesUpdated(_buyFee, _sellFee, _transferFee);
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
        bool canSwap = getAllPending() >= swapThreshold;
        if (!_swapping && !AMMPairs[from] && canSwap) {
            _swapping = true;
            
            if (false || _taxwalletPending > 0) {
                uint256 token2Swap = 0 + _taxwalletPending;
                bool success = false;

                _swapTokensForCoin(token2Swap);
                uint256 coinsReceived = address(this).balance;
                
                uint256 taxwalletPortion = coinsReceived * _taxwalletPending / token2Swap;
                if (taxwalletPortion > 0) {
                    success = payable(taxwalletAddress).send(taxwalletPortion);
                    if (success) {
                        emit taxwalletFeeSent(taxwalletAddress, taxwalletPortion);
                    }
                }
                _taxwalletPending = 0;
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
                _taxwalletPending += fees * taxwalletFees[txType] / totalFees[txType];
            }
            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
        }
        super._transfer(from, to, amount);
    }

    function _updateRouterV2(address router) external onlyOwner {
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

    function updateMaxSellAmount(uint256 _maxSellAmount) public onlyOwner {
        maxSellAmount = _maxSellAmount;
        
        emit MaxSellAmountUpdated(_maxSellAmount);
    }

    function updateMaxTransferAmount(uint256 _maxTransferAmount) public onlyOwner {
        maxTransferAmount = _maxTransferAmount;
        
        emit MaxTransferAmountUpdated(_maxTransferAmount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        require(!blacklisted[from] && !blacklisted[to], "Blacklist: Sender or recipient is blacklisted");

        if (AMMPairs[to] && !isExcludedFromLimits[from]) { // SELL
            require(amount <= maxSellAmount, "MaxTx: Cannot exceed max sell limit");
        }
    
        if (!AMMPairs[to] && !isExcludedFromLimits[from]) { // OTHER
            require(amount <= maxTransferAmount, "MaxTx: Cannot exceed max transfer limit");
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