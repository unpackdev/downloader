// SPDX-License-Identifier: GPL
pragma solidity ^0.8.9;

/*

Website: https://tyrion.finance
TG: https://t.me/tyrionfinance
Twitter: https://twitter.com/tyrionfinance

*/

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Permit.sol";
import "./Ownable.sol";
import "./Math.sol";

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract Tyrion is ERC20, ERC20Burnable, ERC20Permit, Ownable {
    uint public tax;
    uint256 public swapTokensAtAmount;
    uint256 public maxTaxSwap;
    uint256 public maxWalletSize;
    address public taxWallet;
    bool private swapping;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    mapping(address => bool) public isExcludedFromFees;
    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => bool) public blacklist;
    uint256 public uniswapDeployBlock;
    bool public isBlacklistActive;

    constructor(address uniswapAddress)
        ERC20("Tyrion.finance", "TYRION")
        ERC20Permit("Tyrion.finance")
    {
        // Uniswap on mainnet 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        if (uniswapAddress != address(0)) {
            uniswapV2Router = IUniswapV2Router02(uniswapAddress);
            uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
                .createPair(address(this), uniswapV2Router.WETH());
        }

        setAutomatedMarketMakerPair(address(uniswapV2Pair), true);
        excludeFromFees(msg.sender, true);
        excludeFromFees(address(this), true);

        _mint(msg.sender, 1000000000 * 10 ** decimals());

        taxWallet = msg.sender;
        tax = 50; // 5%
        swapTokensAtAmount = totalSupply() * 2 / 10000; // 0.02%
        maxTaxSwap = totalSupply() * 20 / 10000; // 0.2%
        maxWalletSize = totalSupply() * 3 / 100; // 3%
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!blacklist[from], "From address is blacklisted");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (maxWalletSize > 0 && automatedMarketMakerPairs[from]) {
            require(balanceOf(to) + amount <= maxWalletSize, "Recipient's wallet size exceeded");
        }

        // Blacklist buyers in first 3 blocks of Uniswap pool launch
        if (block.number <= uniswapDeployBlock + 3 && automatedMarketMakerPairs[from]) {
            blacklist[to] = true;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            !swapping &&
            automatedMarketMakerPairs[to] &&
            !isExcludedFromFees[from] &&
            !isExcludedFromFees[to]
        ) {
            swapping = true;
            swapTokensForEth(Math.min(contractTokenBalance, maxTaxSwap));
            swapping = false;
        }

        bool takeFee = (tax > 0) && !swapping;

        // If any account belongs to _isExcludedFromFee account then remove the fee
        if (isExcludedFromFees[from] || isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        // Only take fees on buys/sells, do not take on wallet transfers
        if (takeFee && (automatedMarketMakerPairs[to] || automatedMarketMakerPairs[from])) {
            fees = (amount * tax) / 1000;
        }

        if (fees > 0) {
            super._transfer(from, address(this), fees);
            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function setTaxPercent(uint newTax) public onlyOwner {
        require(newTax <= 50, "Can't set higher tax than 5%");
        tax = newTax;
    }

    function setMaxWalletSize(uint256 newSize) public onlyOwner {
        maxWalletSize = newSize;
    }

    function setMaxTaxSwap(uint256 newMax) public onlyOwner {
        maxTaxSwap = newMax;
    }

    function setTaxWallet(address newWallet) public onlyOwner {
        taxWallet = newWallet;
    }

    function setSwapTokensAtAmount(uint256 newAmount) public onlyOwner {
        swapTokensAtAmount = newAmount;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        isExcludedFromFees[account] = excluded;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        automatedMarketMakerPairs[pair] = value;
    }

    function setBlacklist(address account, bool value) public onlyOwner {
        require(
            isBlacklistActive || (!isBlacklistActive && !value),
            "You can no longer blacklist addresses when the blacklist is deactivated"
        );
        blacklist[account] = value;
    }

    function getBlacklist(address account) public view returns (bool) {
        return blacklist[account];
    }

    function deactivateBlacklist() public onlyOwner {
        isBlacklistActive = false;
    }

    function withdrawEth(address toAddr) public onlyOwner {
        (bool success, ) = toAddr.call{
            value: address(this).balance
        } ("");
        require(success);
    }

    function launchUniswapPool(uint256 poolTokens) external payable onlyOwner {
        require(poolTokens > 0, "Must provide liquidity");
        require(msg.value > 0, "Must provide liquidity");

        uniswapDeployBlock = block.number;
        isBlacklistActive = true;

        transfer(address(this), poolTokens);
        _approve(address(this), address(uniswapV2Router), poolTokens);

        uniswapV2Router.addLiquidityETH{ value: msg.value }(
            address(this),
            poolTokens,
            0,
            0,
            owner(),
            block.timestamp
        );
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // Generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // Make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // Accept any amount of ETH; ignore slippage
            path,
            address(taxWallet),
            block.timestamp
        );
    }

    receive() external payable {}
}
