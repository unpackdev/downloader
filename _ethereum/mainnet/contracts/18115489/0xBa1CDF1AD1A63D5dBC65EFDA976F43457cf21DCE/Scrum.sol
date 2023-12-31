// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title SCRUM
 * @author memesonmondays.eth
 *
 *   ──────▄▄██▓████▓██▄▄
 *   ────▄███╳█▓█╳╳█▓█╳███▄
 *   ───████╳╳█▓█╳╳█▓█╳╳████
 *   ───████╳╳█▓█╳╳█▓█╳╳████
 *   ────▀███╳█▓█╳╳█▓█╳███▀
 *   ──────▀▀██▓████▓██▀▀
 *
 *     https://scrumtoken.xyz
 *   https://MemesOnMondays.com
 *  https://x.com/memesonmondays
 */

import "./ERC20.sol";
import "./Ownable.sol";

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract Scrum is ERC20, Ownable {
    address router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public factory;
    address public weth;
    address public pool;
    address[] public path;
    address public team;
    uint immutable taxRate = 100; // basis points = 1%
    uint immutable maxSupply = 1_000_000_000 * 10 ** decimals();
    bool inTransfer = false;

    /**
     * @dev Constructor method initializes the ERC20 Token.
     * @notice Mints tokens to contract and marketing wallet.
     * Sets up initial liquidity pool but liquidity cannot 
     * be added in the same tx
     */
    constructor() ERC20("SCRUM", "SCRUM") {
        factory = IUniswapV2Router(router).factory();
        weth = IUniswapV2Router(router).WETH();
        path.push(address(this));
        path.push(weth);
        team = msg.sender;
        _mint(address(this), maxSupply);
        pool = IUniswapV2Factory(factory).createPair(address(this), weth);
    }

    /**
     * @dev Public onlyOwner function to provide liquidity to
     * the established Uniswap v2 pool. LP tokens are locked
     * forever in the contract.
     * @dev Send ETH with the call to add to ETH side of pool
     * @notice Approves max spend by the router to save calls
     * @notice Renounces ownership at end of function
     */
    function addLiquidity() external onlyOwner payable {
        _approve(address(this), router, type(uint256).max);
        IUniswapV2Router(router).addLiquidityETH{value: msg.value}(
            address(this),
            maxSupply,
            0,
            0,
            address(this),
            block.timestamp
        );
        renounceOwnership();
    }

    /**
     * @dev external function to trade tax tokens for weth and
     * send to team wallet. Permissionless, anyone can call
     */
    function returnTax() external {
        uint tokenAmount = balanceOf(address(this));
        if (tokenAmount > 0) {
            IUniswapV2Router(router).swapExactTokensForTokens(
                tokenAmount,
                0,
                path,
                team,
                block.timestamp
            );
        }
    }

    /**
     * @dev internal override function to add tax to transfers
     * @param sender address of the sender of funds
     * @param recipient address of the receiver of funds
     * @param amount amount of funds in wei (18 decimals)
     */
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        if (sender != address(this) && recipient != address(this) && inTransfer == false) {
            inTransfer = true;
            uint taxedAmount = amount * taxRate / 10000;
            uint sendAmount = amount - taxedAmount;
            super._transfer(sender, recipient, sendAmount);
            super._transfer(sender, address(this), taxedAmount);
            inTransfer = false;
        } else {
            super._transfer(sender, recipient, amount);
        }
    }

    receive() external payable {}
    fallback() external payable {}
}