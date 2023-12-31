// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract ERC20Contract is ERC20, ERC20Burnable, Ownable {

    mapping (address => bool) private isExcludedFromFee;
    mapping(address => uint256) private holderLastTransferTimestamp;
    uint256 public buyTax;
    uint256 public sellTax;
    uint256 public burnPercent;
    uint256 public lpPercent;
    uint256 public maxSupply;
    uint256 public maxTxAmount;
    uint256 public maxWalletSize;
    uint256 public taxSwapThreshold;
    uint256 public maxTaxSwap;
    bool public transferDelayEnabled = true;
    bool public tradingEnabled = false;
    address[] public payees;
    uint256[] public shares;
    address public creator;
    IUniswapV2Router02 public swapRouter;
    address public swapPair;

    struct Fees {
        uint16 buyTax;
        uint16 sellTax;
        uint16 burnPercent;
        uint16 lpPercent;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        Fees memory _fees,
        uint256 _maxSupply,
        uint16 _devShare,
        address _devAddress,
        address[] memory _payees,
        uint16[] memory _shares,
        address _owner
    ) ERC20(_name, _symbol) {
        creator = _owner;
        buyTax = _fees.buyTax;
        sellTax = _fees.sellTax;
        burnPercent = _fees.burnPercent;
        lpPercent = _fees.lpPercent;
        payees = _payees;
        shares = _shares;
        maxSupply = _maxSupply * 10 ** decimals();
        maxTxAmount =   maxSupply / 100;
        maxWalletSize = (maxSupply / 100) * 2;
        taxSwapThreshold = maxSupply / 1000;
        maxTaxSwap = (maxSupply / 1000) * 5;
        isExcludedFromFee[_owner] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[address(0xdead)] = true;
        for (uint256 i = 0; i < payees.length; i++) {
            isExcludedFromFee[payees[i]] = true;
        }
        uint256 devTokens = (maxSupply / 100) * _devShare;
        _mint(_devAddress, devTokens);
        _mint(_owner, maxSupply - devTokens);
        transferOwnership(_owner);
    }

    function removeLimits() external onlyOwner {
        maxTxAmount = maxSupply;
        maxWalletSize = maxSupply;
        transferDelayEnabled = false;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
      return (a > b) ? b : a;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(tradingEnabled || from == owner(), "Trading not live.");
        uint256 toSend = 0;
        uint256 burnAmount = 0;
        uint256 lpAmount = 0;
        uint256 lpTokens = 0;
        uint256 lpETH = 0;
        uint256 balance = 0;
        uint256 taxAmount = 0;
        bool success;
        if (!isExcludedFromFee[from] && !isExcludedFromFee[to]) {
            if (transferDelayEnabled && to != address(swapRouter) && to != address(swapPair)) {
              require(holderLastTransferTimestamp[tx.origin] < block.number,"Only one transfer per block allowed.");
              holderLastTransferTimestamp[tx.origin] = block.number;
            }
            if (from == swapPair && to != address(swapRouter) && buyTax > 0) {
                require(amount <= maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= maxWalletSize, "Exceeds the _maxWalletSize.");
                taxAmount = (amount / 100) * buyTax;
            }
            if (to == swapPair && sellTax > 0) {
                taxAmount = (amount / 100) * sellTax;
            }
            if (taxAmount > 0) {
                super._transfer(from, address(this), taxAmount);
            }
            uint256 tokenBalance = min(balanceOf(address(this)), maxTaxSwap);
            if (to == swapPair && tokenBalance > taxSwapThreshold) {
                if (lpPercent > 0) lpAmount = (tokenBalance / 100) * lpPercent;
                if (lpAmount > 0) lpTokens = lpAmount / 2;
                if (burnPercent > 0) burnAmount = (tokenBalance / 100) * burnPercent;
                uint256 tokensToSwap = tokenBalance - burnAmount - lpTokens;
                if (tokensToSwap > 0) {
                    swapTokensForEth(tokensToSwap);
                    balance = address(this).balance;
                    lpETH = balance * (lpTokens / tokensToSwap);
                    if (lpETH > 0 && lpTokens > 0) addLiquidity(lpTokens, lpETH);
                    balance = address(this).balance;
                    if (balance > 0) {
                        for (uint256 i = 0; i < payees.length; i++) {
                            toSend = min((balance / 100) * shares[i], address(this).balance);
                            (success,) = payable(payees[i]).call{value: toSend}("");
                        }
                    }
                }
                if (burnAmount > 0) super._burn(address(this), min(burnAmount, balanceOf(address(this))));
            }
        }
        super._transfer(from, to, amount - taxAmount);
    }

    function addLiquidity(uint256 _tokenAmount, uint256 _ethAmount) private {
        swapRouter.addLiquidityETH{value: _ethAmount}(
            address(this),
            _tokenAmount,
            0,
            0,
            creator,
            block.timestamp
        );
    }

    function createPair() external onlyOwner() {
        require(swapPair == address(0),"Pair already created.");
        swapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(swapRouter), maxSupply);
        swapPair = IUniswapV2Factory(swapRouter.factory()).createPair(address(this), swapRouter.WETH());
        IERC20(swapPair).approve(address(swapRouter), type(uint).max);
    }

    function openTrading() external onlyOwner() {
        tradingEnabled = true;
    }

    function swapTokensForEth(uint256 _tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = swapRouter.WETH();
        swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function manualSwap() external {
        require(msg.sender == creator, "Unauthorized");
        uint256 toSend = 0;
        uint256 burnAmount = 0;
        uint256 lpAmount = 0;
        uint256 lpTokens = 0;
        uint256 lpETH = 0;
        uint256 balance = 0;
        bool success;
        uint256 tokenBalance = balanceOf(address(this));
        if (lpPercent > 0) lpAmount = (tokenBalance / 100) * lpPercent;
        if (lpAmount > 0) lpTokens = lpAmount / 2;
        if (burnPercent > 0) burnAmount = (tokenBalance / 100) * burnPercent;
        uint256 tokensToSwap = tokenBalance - burnAmount - lpTokens;
        if (tokensToSwap > 0) {
            swapTokensForEth(tokensToSwap);
            balance = address(this).balance;
            lpETH = balance * (lpTokens / tokensToSwap);
            if (lpETH > 0 && lpTokens > 0) addLiquidity(lpTokens, lpETH);
            balance = address(this).balance;
            if (balance > 0) {
                for (uint256 i = 0; i < payees.length; i++) {
                    toSend = min((balance / 100) * shares[i], address(this).balance);
                    (success,) = payable(payees[i]).call{value: toSend}("");
                }
            }
        }
        if (burnAmount > 0) super._burn(address(this), min(burnAmount, balanceOf(address(this))));
    }

    receive() external payable {}
}