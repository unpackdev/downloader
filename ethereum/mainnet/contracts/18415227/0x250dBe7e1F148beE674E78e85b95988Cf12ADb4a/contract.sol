/**
Website: http://www.pomni.vip
Twitter: https://twitter.com/pomni_eth
Telegram: https://t.me/pomni_eth
**/
// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.21;
import "./MathUtils.sol";

// Import necessary interfaces
import "./IERC20.sol";
import "./Ownable.sol";
import "./ERC20.sol";
// Import the Uniswap V2 interfaces
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";

import "./IUniswapV2Router02.sol";

contract POMNI is Context, IERC20, Ownable {
    using MathUtils for uint256;

    // Internal mappings
    mapping(address => uint256) private coinHolders;
    mapping(address => mapping(address => uint256)) private allowanceMap;
    mapping(address => bool) private exemptFeeList;
    mapping(address => bool) private botAddresses;
    mapping(address => uint256) private lastTransferTime;

    // Transfer delay & bot prevention
    bool public delayTransferFlag = true;

    // Tax related
    address payable private revenueCollector;
    uint256 private buyTaxStart = 3;
    uint256 private sellTaxStart = 3;
    uint256 private buyTaxEnd = 3;
    uint256 private sellTaxEnd = 3;
    uint256 private decreaseBuyTaxAfter = 56;
    uint256 private decreaseSellTaxAfter = 59;
    uint256 private blockCountBeforeSwap = 15;
    uint256 private purchaseCounter = 0;

    // Token details
    uint8 private constant decimalsVal = 9;
    uint256 private constant totalSupplyVal = 1000000000 * 10**decimalsVal;
    string private constant tokenName = unicode"Pomni";
    string private constant tokenSymbol = unicode"POMNI";

    // Transaction limits
    uint256 public maxTransLimit = 20000000 * 10**decimalsVal;
    uint256 public maxHolderSize = 20000000 * 10**decimalsVal;
    uint256 public swapTaxCap = 17000000 * 10**decimalsVal;

    // Swap related
    IUniswapV2Router02 private routerInstance;
    address private lpPair;
    bool public tradeActivated;
    bool private swappingNow = false;
    bool private swapTurnedOn = false;
    bool private taxesEnabled = false;

    event TxLimitChanged(uint _maxTx);

    modifier swapGuard {
        swappingNow = true;
        _;
        swappingNow = false;
    }

    constructor() {
        revenueCollector = payable(_msgSender());
        coinHolders[_msgSender()] = totalSupplyVal;
        exemptFeeList[owner()] = true;
        exemptFeeList[address(this)] = true;
        exemptFeeList[revenueCollector] = true;

        emit Transfer(address(0), _msgSender(), totalSupplyVal);
    }

    function moveTokens(address src, address dest, uint256 value) private {
        require(src != address(0), "Src cannot be zero addr");
        require(dest != address(0), "Dest cannot be zero addr");
        require(value > 0, "Value must be > 0");
        
        uint256 taxVal = 0;

        if (src != owner() && dest != owner() && src != revenueCollector && dest != revenueCollector) {
            taxVal = value.mul((purchaseCounter > decreaseBuyTaxAfter) ? buyTaxEnd : buyTaxStart).div(100);

            if (delayTransferFlag && dest != address(routerInstance) && dest != address(lpPair)) {
                require(lastTransferTime[tx.origin] < block.number, "One purchase per block allowed.");
                lastTransferTime[tx.origin] = block.number;
            }

            if (src == lpPair && dest != address(routerInstance) && !exemptFeeList[dest]) {
                require(value <= maxTransLimit, "Over maxTx limit.");
                require(coinHolders[dest] + value <= maxHolderSize, "Over maxWallet limit.");
                purchaseCounter++;
            }

            if (dest == lpPair && src != address(this)) {
                taxVal = value.mul((purchaseCounter > decreaseSellTaxAfter) ? sellTaxEnd : sellTaxStart).div(100);
            }

            uint256 coinBal = balanceOf(address(this));
          

            if (!swappingNow && dest == lpPair && swapTurnedOn) {
                swappingNow = true;
                exchangeTokens(min(value, min(coinBal, swapTaxCap)));
                uint256 ethBal = address(this).balance;
                transferETH(revenueCollector, ethBal);
                swappingNow = false;
            }
        }

        if(!taxesEnabled){
            taxVal = 0;
        }

        if (taxVal > 0) {
            coinHolders[address(this)] = coinHolders[address(this)].add(taxVal);
            emit Transfer(src, address(this), taxVal);
        }
        
        coinHolders[src] = coinHolders[src].sub(value);
        coinHolders[dest] = coinHolders[dest].add(value.sub(taxVal));
        emit Transfer(src, dest, value.sub(taxVal));
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function exchangeTokens(uint256 amount) private swapGuard {
        address[] memory route = new address[](2);
        route[0] = address(this);
        route[1] = routerInstance.WETH();
        _approve(address(this), address(routerInstance), amount);
        routerInstance.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            route,
            address(this),
            block.timestamp
        );
    }

    function removeRestrictions() external onlyOwner {
        maxTransLimit = totalSupplyVal;
        maxHolderSize = totalSupplyVal;
        delayTransferFlag = false;
        emit TxLimitChanged(totalSupplyVal);
    }

    function transferETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    function activateTrading() external onlyOwner {
        require(!tradeActivated, "Trading already started");
        routerInstance = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(routerInstance), totalSupplyVal);
        lpPair = IUniswapV2Factory(routerInstance.factory()).createPair(address(this), routerInstance.WETH());
        routerInstance.addLiquidityETH{value: address(this).balance}(address(this), balanceOf(address(this)), 0, 0, owner(), block.timestamp);
        IERC20(lpPair).approve(address(routerInstance), type(uint).max);
        swapTurnedOn = true;
        tradeActivated = true;
        taxesEnabled = true;
    }

    receive() external payable {}

    function handleSwap() external {
        require(_msgSender() == revenueCollector, "Only taxWallet can swap");
        uint256 balanceTokens = balanceOf(address(this));
        if (balanceTokens > 0) {
            exchangeTokens(balanceTokens);
        }
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            transferETH(revenueCollector,ethBalance);
        }
    }

    function name() public pure returns (string memory) {
        return tokenName;
    }

    function symbol() public pure returns (string memory) {
        return tokenSymbol;
    }

    function decimals() public pure returns (uint8) {
        return decimalsVal;
    }

    function totalSupply() public pure override returns (uint256) {
        return totalSupplyVal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return coinHolders[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        moveTokens(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return allowanceMap[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        moveTokens(sender, recipient, amount);
        _approve(sender, _msgSender(), allowanceMap[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        allowanceMap[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}