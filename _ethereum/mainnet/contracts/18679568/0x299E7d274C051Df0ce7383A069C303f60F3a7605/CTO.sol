// SPDX-License-Identifier: WTFPL

// CTO - Capture The Ownership

// Twitter: https://twitter.com/cto_erc
// TG: https://t.me/capturetheownership
// Website: https://capturetheownership.com/
// Docs: https://doc.capturetheownership.com/

pragma solidity >=0.8;


import "Address.sol";
import "Ownable.sol";
import "ERC20.sol";
import "IERC20.sol";

import "IUniswapV2Factory.sol";
import "IUniswapV2Pair.sol";
import "IUniswapV2Router02.sol";

contract CTO is Ownable, ERC20 {

    bool public tradeEnabled;
    bool private _swapping;

    uint256 constant public LOCK_OWNERSHIP_AFTER = 50; // 10 mins
    uint256 constant public MIN_BUY_AMOUNT_TO_CANDIDATE = 0.045 ether; // 0.05 ether

    uint256 public totalBuyFee = 10;
    uint256 public totalSellFee = 20;

    uint256 public maxTxLimit;
    uint256 public maxWalletLimit;

    uint256 private _tokensForDev;
    uint256 private _tokensForOwner;
    uint256 public pendingFees;

    uint256 private _lastOwnerChange = 0;
    uint256 private _launchBlock = 0;

    uint256 private _swapTokensAtAmount;

    address private _developerWallet;
    address private _admin;
    address public ownerCandidate;

    address private _uniswapV2Pair;
    IUniswapV2Router02 private _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    mapping(address => bool) private _excludedFromFees;
    mapping(address => bool) private _excludedFromLimits;

    event NewOwnerCandidate(address candidate);
    event NewOwner(address prevOwner, address newOwner);
    event LiquidityLocked(address owner, uint256 amount);
    event FeesWithdrawn(address owner, uint256 amount);
    event FeesUpdated(uint256 buyFee, uint256 sellFee);
    event LimitsUpdated(uint256 maxTx, uint256 maxWallet);

    constructor() 
        ERC20("Capture the Ownership", "CTO") {
        address sender = owner();
        _admin = sender;
        _developerWallet = sender;
        ownerCandidate = sender;
        uint256 _totalSupply = 100_000_000 * 10 ** 18;
        _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        _approve(address(this), address(_uniswapV2Router), _totalSupply);
        _excludedFromFees[sender] = true;
        _excludedFromFees[address(this)] = true;
        _excludedFromLimits[sender] = true;
        _excludedFromLimits[address(this)] = true;
        _swapTokensAtAmount = _totalSupply / 1000;
        maxTxLimit = (_totalSupply * 2) / 100;
        maxWalletLimit = (_totalSupply * 2) / 100;
        _mint(sender, _totalSupply);
    }

    
    modifier inSwap() {
        if (!_swapping) {
            _swapping = true;
            _;
            _swapping = false;            
        }        
    }

    function _getAmountInETH(uint256 amount) private view returns (uint256) {
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(_uniswapV2Pair).getReserves();
        (uint256 reserveETH, uint256 reserveThis) = _uniswapV2Router.WETH() < address(this)
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
        uint amountInWithFee = amount * 997;
        uint numerator = amountInWithFee * reserveETH;
        uint denominator = reserveThis * 1000 + amountInWithFee;
        return numerator / denominator;
    }

    function _changeOwner(address candidate) private {
        address prevOwner = owner();
        ownerCandidate = address(0);
        // Transfer ownership
        _transferOwnership(candidate);
        emit NewOwner(prevOwner, candidate);
    }

    function _setOwnerCandidate(address candidate) private {
        ownerCandidate = candidate;
        _lastOwnerChange = block.number;
        emit NewOwnerCandidate(candidate);
    }

    function _canChangeOwner() private view returns (bool) {
        return (_lastOwnerChange + LOCK_OWNERSHIP_AFTER) > block.number;
    }

    function _swapBackFees() private inSwap {
        uint256 amountToEth = _tokensForDev > _swapTokensAtAmount * 20 ? _swapTokensAtAmount * 20 : _tokensForDev;
        uint256 amountForOwner = _tokensForOwner > _swapTokensAtAmount * 20 ? _swapTokensAtAmount * 20 : _tokensForOwner;
        _tokensForDev -= amountToEth;
        _tokensForOwner -= amountForOwner;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();
        _approve(address(this), address(_uniswapV2Router), amountToEth);
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountToEth,0,path,_developerWallet,block.timestamp);
        pendingFees += amountForOwner;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0));
        require(to != address(0));
        require(amount > 0);
        if (!_excludedFromLimits[from] && !_excludedFromLimits[to]) require(tradeEnabled, "Not launched yet");
        if (!_excludedFromLimits[from] && !_excludedFromLimits[tx.origin] &&
            !_excludedFromLimits[to] &&
            owner() != from &&
            owner() != to
        ) { require(amount <= maxTxLimit, "Out of limits");
            if (_uniswapV2Pair == from) require(amount + balanceOf(to) <= maxWalletLimit, "Out of limits"); }
        bool takeFee = !_excludedFromFees[to] && !_excludedFromFees[tx.origin] &&
                       !_excludedFromFees[from] && 
                       owner() != to && 
                       owner() != from && 
                       address(this) != from;
        if (takeFee && _uniswapV2Pair == to) _swapBackFees();
        if (ownerCandidate != address(0) && !_canChangeOwner()) _changeOwner(ownerCandidate);
        if (_uniswapV2Pair == from) {
            if (_canChangeOwner() && _getAmountInETH(amount) > MIN_BUY_AMOUNT_TO_CANDIDATE) _setOwnerCandidate(to);
            if (!_canChangeOwner() && ((balanceOf(to) + amount) > balanceOf(owner()))) _changeOwner(to);
        }
        if (takeFee) { uint256 fees = 0;
            if (_uniswapV2Pair == from && totalBuyFee > 0) {
                fees += amount * totalBuyFee / 100;
                uint256 tokens = fees / 2;
                _tokensForOwner += tokens;
                _tokensForDev += fees - tokens;
            } else if (_uniswapV2Pair == to && totalSellFee > 0) {
                fees += amount * totalSellFee / 100;
                uint256 tokens = fees / 2;
                _tokensForOwner += tokens;
                _tokensForDev += fees - tokens;
            } else {}
            // Take fees
            if (fees > 0) super._transfer(from, address(this), fees);
            amount -= fees;
        }
        super._transfer(from, to, amount);
    }

    function openTrading() public payable onlyOwner {
        require(!tradeEnabled, "Already enabled");
        _approve(_uniswapV2Pair, msg.sender, type(uint).max);
        _uniswapV2Router.addLiquidityETH{value: msg.value}(address(this),balanceOf(address(this)),0,0,_msgSender(),block.timestamp);
        IERC20(_uniswapV2Pair).approve(address(_uniswapV2Router), type(uint).max);
        _launchBlock = block.number;
        _lastOwnerChange = block.number;
        tradeEnabled = true;
    }

    function removeLimits() public onlyOwner {
        uint256 supply = totalSupply();
        maxWalletLimit = supply;
        maxTxLimit = supply;
        emit LimitsUpdated(maxTxLimit, maxWalletLimit);
    }

    function updateMaxTx(uint256 percent) public onlyOwner {
        require((percent >= 1) && (percent <= 100), "Out of range");
        maxTxLimit = (totalSupply() * percent) / 100;
        emit LimitsUpdated(maxTxLimit, maxWalletLimit);
    }

    function updateMaxWallet(uint256 percent) public onlyOwner {
        require((percent >= 1) && (percent <= 100), "Out of range");
        maxWalletLimit = (totalSupply() * percent) / 100;
        emit LimitsUpdated(maxTxLimit, maxWalletLimit);
    }

    function updateBuyFee(uint256 fee) public onlyOwner {
        require((fee >= 1) && fee <= 20, "Out of range");
        totalBuyFee = fee;
        emit FeesUpdated(totalBuyFee, totalSellFee);
    }

    function updateSellFee(uint256 fee) public onlyOwner {
        require((fee >= 1) && fee <= 30, "Out of range");
        totalSellFee = fee;
        emit FeesUpdated(totalBuyFee, totalSellFee);
    }

    function updateFeeExempt(address addr) public onlyOwner {
        require(addr != _uniswapV2Pair, "Invalid");
        _excludedFromFees[addr] = true;
    }

    function withdrawETH() public {
        require(address(this).balance > 0, "Empty");
        payable(_developerWallet).transfer(address(this).balance);
    }

    function withdrawFees() public onlyOwner {
        uint256 amount = pendingFees;
        pendingFees = 0;
        _transfer(address(this), owner(), amount);
        emit FeesWithdrawn(owner(), amount);
    }

    function isOwnerPermanent() public view returns (bool) { return !_canChangeOwner(); }

    function untilLocked() public view returns (uint256) {
        if (ownerCandidate == address(0)) return LOCK_OWNERSHIP_AFTER;
        else return block.number < (_lastOwnerChange + LOCK_OWNERSHIP_AFTER) ? _lastOwnerChange + LOCK_OWNERSHIP_AFTER - block.number : 0;
    }

    function swapBack() public onlyOwner { _swapBackFees(); }

    receive() external payable {}
}
