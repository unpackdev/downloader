// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

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

contract Zoo is ERC20, ERC20Burnable, ERC20Permit, Ownable {
    uint public tax;
    uint256 public swapTokensAtAmount;
    uint256 public maxTaxSwap;
    address public taxWallet;
    bool private swapping;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public uniswapV2Pair;

    mapping(address => bool) private isExcludedFromFees;
    mapping(address => bool) public automatedMarketMakerPairs;

    constructor(address uniswapRouterAddress)
        ERC20("MeAtTheZoo", "ZOO")
        ERC20Permit("MeAtTheZoo")
    {
        uniswapV2Router = IUniswapV2Router02(
            uniswapRouterAddress //Uniswap V2 Router
        );
//        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
//            .createPair(address(this), uniswapV2Router.WETH());

//        setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        excludeFromFees(msg.sender, true);
        excludeFromFees(address(this), true);

        _mint(msg.sender,     50000000 * 10 ** decimals());
        _mint(address(this), 950000000 * 10 ** decimals());

        taxWallet = msg.sender;
        tax = 50; // 5%
        swapTokensAtAmount = totalSupply() * 20 / 10000; // 0.2%
        maxTaxSwap = totalSupply() * 50 / 10000; // 0.5%
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
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

    function setMaxTaxSwap(uint256 newMax) public onlyOwner {
        maxTaxSwap = newMax;
    }

    function setTaxWallet(address newWallet) public onlyOwner {
        taxWallet = newWallet;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        isExcludedFromFees[account] = excluded;
    }

    function setSwapTokensAtAmount(uint256 newAmount) public onlyOwner {
        swapTokensAtAmount = newAmount;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        automatedMarketMakerPairs[pair] = value;
    }

    function withdrawEth(address toAddr) public onlyOwner {
        (bool success, ) = toAddr.call{
            value: address(this).balance
        } ("");
        require(success);
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

    // New function to create the Uniswap pair and add liquidity
    function createUniswapPairAndAddLiquidity() external payable onlyOwner {
        require(uniswapV2Pair == address(0), "Pair already created");

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        setAutomatedMarketMakerPair(uniswapV2Pair, true);

         uint256 tokenAmount = 950000000 * 10 ** decimals();
         uint256 ethAmount = msg.value;
         addLiquidity(tokenAmount, ethAmount);
    }

    // Optional: Function to add liquidity
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // Slippage is unavoidable
            0, // Slippage is unavoidable
            owner(),
            block.timestamp
        );
    }
}
