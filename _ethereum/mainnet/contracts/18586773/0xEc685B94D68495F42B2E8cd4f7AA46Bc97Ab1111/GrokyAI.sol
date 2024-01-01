// SPDX-License-Identifier: MIT
/*
  Website: https://groky-ai.xyz/
  Twitter/X: https://twitter.com/Groky_AI_
  Telegram: https://t.me/GrokyAI

  /$$$$$$                      /$$                        /$$$$$$  /$$$$$$
 /$$__  $$                    | $$                       /$$__  $$|_  $$_/
| $$  \__/  /$$$$$$   /$$$$$$ | $$   /$$ /$$   /$$      | $$  \ $$  | $$
| $$ /$$$$ /$$__  $$ /$$__  $$| $$  /$$/| $$  | $$      | $$$$$$$$  | $$
| $$|_  $$| $$  \__/| $$  \ $$| $$$$$$/ | $$  | $$      | $$__  $$  | $$
| $$  \ $$| $$      | $$  | $$| $$_  $$ | $$  | $$      | $$  | $$  | $$
|  $$$$$$/| $$      |  $$$$$$/| $$ \  $$|  $$$$$$$      | $$  | $$ /$$$$$$
 \______/ |__/       \______/ |__/  \__/ \____  $$      |__/  |__/|______/
                                         /$$  | $$
                                        |  $$$$$$/
                                         \______/
*/

pragma solidity ^0.8.20;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (
        uint amountToken,
        uint amountETH,
        uint liquidity
    );
}

contract GrokyAI {
    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    string public name = "Groky AI";
    string public symbol = "GROKY";
    uint8 public decimals = 18;

    IUniswapV2Router02 public router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Factory public factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    address public pair;
    address public owner;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        pair = factory.createPair(address(this), router.WETH());
        owner = msg.sender;
    }

    function transfer(address recipient, uint amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function openTrading() external payable {
        require(totalSupply == 0, "Already opened trading");
        require(msg.sender == owner, "Only owner");

        // Mint
        balanceOf[address(this)] += 10000000 * 10 ** decimals;
        totalSupply += 10000000 * 10 ** decimals;
        emit Transfer(address(0), address(this), 10000000 * 10 ** decimals);

        // Approve
        allowance[address(this)][address(router)] = totalSupply;
        emit Approval(address(this), address(router), totalSupply);

        // Add liquidity
        router.addLiquidityETH{value: msg.value}(
            address(this),
            totalSupply,
            0,
            0,
            address(msg.sender),
            block.timestamp
        );
    }

    function renounceOwnership() external {
        require(msg.sender == owner, "Only owner");
        owner = address(0);
        emit OwnershipTransferred(msg.sender, address(0));
    }
}