/*

88                        88                           ,adba,              88                        88
88                        88                           8I  I8              88                        88
88                        88                           "8bdP'              88                        88
88,dPPYba,   88       88  88,dPPYba,   88       88    ,d8"8b  88   ,adPPYb,88  88       88   ,adPPYb,88  88       88
88P'    "8a  88       88  88P'    "8a  88       88  .dP'   Yb,8I  a8"    `Y88  88       88  a8"    `Y88  88       88
88       d8  88       88  88       d8  88       88  8P      888'  8b       88  88       88  8b       88  88       88
88b,   ,a8"  "8a,   ,a88  88b,   ,a8"  "8a,   ,a88  8b,   ,dP8b   "8a,   ,d88  "8a,   ,a88  "8a,   ,d88  "8a,   ,a88
8Y"Ybbd8"'    `"YbbdP'Y8  8Y"Ybbd8"'    `"YbbdP'Y8  `Y8888P"  Yb   `"8bbdP"Y8   `"YbbdP'Y8   `"8bbdP"Y8   `"YbbdP'Y8

https://t.me/bubududuerc
https://twitter.com/DUDU_erc
https://twitter.com/BUBU_erc
https://www.bubududu.xyz/

*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract DUDU is ERC20, Ownable {

    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    IUniswapV2Router02 public immutable uniswapV2Router;
    IERC20 public immutable bubuToken;
    address public immutable uniswapV2Pair;
    address public immutable deployer;
    address public immutable marketingWallet;
    uint256 public immutable bubuSupplyForInitialTrading;
    address public bubuVaultWallet;
    address public duduVaultWallet;

    uint256 public mintAmount = 888888888888000000000000000000;  // 888,888,888,888, 18 decimals
    uint256 public swapTokensAtAmount = mintAmount * 5 / 10000;  // 0.05% max before swapBack
    uint256 public maxSwapAmount      = mintAmount * 50 / 10000; // 0.50% max sold per swapBack
    uint256 public maxHoldingAmount   = mintAmount * 60 / 10000; // 0.60% max wallet holdings

    uint256 public maxFees      = 20; // lowers on each update, cannot increase
    uint256 public totalFees    = 5;  // total percent
    uint256 public bubuVaultFee = 3;  // percent to bubuVault
    uint256 public duduVaultFee = 1;  // percent to duduVault
    uint256 public marketingFee = 1;  // percent to marketing

    bool private swapping;
    bool public swapEnabled = true;
    bool public bubuOnly = true;
    bool public limitOn = true;

    mapping (address => bool) public blacklist;
    mapping (address => bool) public isExcludedFromFees;
    mapping (address => bool) public tradingPairs;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event BubuVaultWalletUpdated(address indexed newBubuVaultWallet, address indexed oldBubuVaultWallet);
    event DuduVaultWalletUpdated(address indexed newDuduVaultWallet, address indexed oldDuduVaultWallet);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    modifier onlyDeployer() {
        // some things need to be callable even after renounce
        require(msg.sender == deployer, "shoo");
        _;
    }

    constructor(address bubuAddress, address _marketingWallet, address _buybackWallet, address _tempBubuVaultWallet, address _tempDuduVaultWallet) ERC20("DUDU", "DUDU") {

        bubuToken = IERC20(bubuAddress);
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
          .createPair(address(this), WETH_ADDRESS);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        bubuSupplyForInitialTrading = bubuToken.totalSupply() - bubuToken.balanceOf(0x000000000000000000000000000000000000dEaD);

        deployer = address(owner());
        marketingWallet = _marketingWallet;
        bubuVaultWallet = _tempBubuVaultWallet; // temporary fee receiver
        duduVaultWallet = _tempDuduVaultWallet; // temporary fee receiver

        excludeFromFees(deployer, true); // Owner address
        excludeFromFees(address(this), true); // CA
        excludeFromFees(address(0xdead), true); // Burn address
        excludeFromFees(_buybackWallet, true);
        excludeFromFees(_marketingWallet, true);
        excludeFromFees(_tempBubuVaultWallet, true);
        excludeFromFees(_tempDuduVaultWallet, true);

        /* _mint only called once and CANNOT be called again */
        _mint(deployer, mintAmount);
    }

    receive() external payable {}

    // DEPLOYER-ONLY FUNCTIONS
    function updateSwapEnabled(bool enabled) public onlyDeployer {
        swapEnabled = enabled;
    }

    function updateBubuVaultWallet(address _bubuVaultWallet) public onlyDeployer {
        emit BubuVaultWalletUpdated(_bubuVaultWallet, bubuVaultWallet);
        bubuVaultWallet = _bubuVaultWallet;
    }

    function updateDuduVaultWallet(address _duduVaultWallet) public onlyDeployer {
        emit DuduVaultWalletUpdated(_duduVaultWallet, duduVaultWallet);
        duduVaultWallet = _duduVaultWallet;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyDeployer {
        require(pair != uniswapV2Pair, "The pair cannot be removed from tradingPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        tradingPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateSwapTokensAtAmount(uint256 newAmount) external onlyDeployer returns (bool) {
        require(newAmount >= totalSupply() / 100000, "Swap amount cannot be lower than 0.001% total supply.");
        require(newAmount <= totalSupply() / 200, "Swap amount cannot be higher than 0.5% total supply.");
        swapTokensAtAmount = newAmount;
        return true;
    }

    function excludeFromFees(address account, bool excluded) public onlyDeployer {
        isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function updateFees(uint256 _bubuVaultFee, uint256 _duduVaultFee, uint256 _marketingFee) external onlyDeployer {
        // THIS FUNCTION LETS TEAM CHANGE FEE DESTINATION EVEN AFTER LAUNCH
        // FEES CAN ONLY BE DECREASED, NEVER INCREASED
        // FEES CANNOT BE SET BELOW 5%
        require(_bubuVaultFee > _duduVaultFee);
        bubuVaultFee = _bubuVaultFee;
        duduVaultFee = _duduVaultFee;
        marketingFee = _marketingFee;
        totalFees = _bubuVaultFee + _duduVaultFee + _marketingFee;
        require(totalFees <= maxFees, "Cannot increase fee");
        maxFees = totalFees; // ENSURES WE CAN ONLY DECREASE FEES
        require(totalFees >= 5, "Cannot set fee below 5%");
    }
    // FIN DEPLOYER-ONLY FUNCTIONS

    // OWNER-ONLY FUNCTIONS
    function setBlacklist(address _address, bool _isBlacklisted) external onlyOwner {
        blacklist[_address] = _isBlacklisted;
    }

    function setRule(bool _bubuOnly, bool _limitOn, uint256 _maxHoldingAmount) external onlyOwner {
        bubuOnly = _bubuOnly;
        limitOn = _limitOn;
        maxHoldingAmount = _maxHoldingAmount;
    }
    // FIN OWNER-ONLY FUNCTIONS

    function getMaxBuyFromBubuHoldings(address buyer) public view returns (uint256) {
        uint256 bubuBalance = bubuToken.balanceOf(buyer);
        if (bubuBalance < 10000 * 10**18) {
            return 0;
        }
        uint256 maxDuduBuy = bubuBalance * 3 * totalSupply() / bubuSupplyForInitialTrading;
        if (maxDuduBuy > maxHoldingAmount) {
            return maxHoldingAmount;
        }
        return maxDuduBuy;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!blacklist[to] && !blacklist[from], "bl");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        bool isBuy = tradingPairs[from];
        bool isSell = tradingPairs[to];
        bool excluded = isExcludedFromFees[from] || isExcludedFromFees[to];

        if (
            bubuOnly &&
            isBuy &&
            from != owner() &&
            to != owner() &&
            to != address(0xdead) &&
            !swapping
        ) {
            // a token buy during initial BUBU-only trading phase
            require(amount + balanceOf(to) <= getMaxBuyFromBubuHoldings(to), "bubu loves dudu");
        }

        if (
            limitOn &&
            isBuy &&
            from != owner() &&
            to != owner() &&
            to != address(0xdead) &&
            !swapping
        ) {
            // a token buy while we have limits on
            require(amount + balanceOf(to) <= maxHoldingAmount, "Too many tokens");
        }

    		uint256 swapAmount = balanceOf(address(this));
        bool canSwap = swapAmount >= swapTokensAtAmount;
        bool takeFee = !swapping;
        if (excluded) {
            takeFee = false;
        }

        if (canSwap && swapEnabled && !swapping && isSell && !excluded) {
            swapping = true;
            swapBack(swapAmount > maxSwapAmount ? maxSwapAmount : swapAmount);
            swapping = false;
        }

        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            if (isSell) {
                fees = amount * totalFees / 100;
                super._transfer(from, address(this), fees);
                amount -= fees;
            } else if (isBuy) {
          	    fees = amount * totalFees / 100;
                super._transfer(from, address(this), fees);
                amount -= fees;
            }
        }

        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH_ADDRESS;

        if (allowance(address(this), address(uniswapV2Router)) < tokenAmount) {
            _approve(address(this), address(uniswapV2Router), 2**256 - 1);
        }

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function swapBack(uint256 tokenAmount) private {
        swapTokensForEth(tokenAmount);
        bool success;
        uint256 ethToDisperse = address(this).balance;
        if (marketingFee > 0) {
            (success,) = marketingWallet.call{value: ethToDisperse * marketingFee / totalFees}("");
            require(success);
        }
        if (duduVaultFee > 0) {
            (success,) = duduVaultWallet.call{value: ethToDisperse * duduVaultFee / totalFees}("");
            require(success);
        }
        (success,) = bubuVaultWallet.call{value: address(this).balance}("");
        require(success);
    }
}
