// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}

contract CUCKToken {
    using SafeMath for uint256;

    string public name = "$CUCK$";
    string public symbol = "CUCK";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000 * 10 ** uint256(decimals);
    uint256 public taxPercentage = 2; // 2% tax on buys and sells
    uint256 public maxWalletBalance = totalSupply * 7 / 100; // 7% of the total supply

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public uniswapV2Pair;  // Address of the Uniswap pair
    address public taxWallet = 0x589e31364f8fcBacb9FE1eDC93a10BdD11D4Fc17;  // Set to the specified tax wallet address

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event TaxWalletChanged(address indexed previousWallet, address indexed newWallet);

    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    function calculateTax(uint256 value) internal view returns (uint256) {
        return value * taxPercentage / 100;
    }

    function isUniswapPair(address to) internal view returns (bool) {
        return to == uniswapV2Pair;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0), "Invalid recipient");
        require(value > 0, "Value must be greater than 0");
        require(balanceOf[msg.sender] >= value, "Insufficient balance");

        uint256 tax = isUniswapPair(to) ? calculateTax(value) : 0;
        uint256 tokensToTransfer = value - tax;

        balanceOf[msg.sender] -= value;
        balanceOf[to] += tokensToTransfer;
        balanceOf[taxWallet] += tax;

        emit Transfer(msg.sender, to, tokensToTransfer);
        emit Transfer(msg.sender, taxWallet, tax);

        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(value <= balanceOf[from], "Insufficient balance");
        require(value <= allowance[from][msg.sender], "Allowance exceeded");
        require(to != address(0), "Invalid recipient");

        uint256 tax = isUniswapPair(to) ? calculateTax(value) : 0;
        uint256 tokensToTransfer = value - tax;

        balanceOf[from] -= value;
        balanceOf[to] += tokensToTransfer;
        balanceOf[taxWallet] += tax;
        allowance[from][msg.sender] -= value;

        emit Transfer(from, to, tokensToTransfer);
        emit Transfer(from, taxWallet, tax);

        return true;
    }

    function setUniswapV2Pair(address _uniswapV2Pair) public {
        require(uniswapV2Pair == address(0), "Uniswap pair address already set");
        uniswapV2Pair = _uniswapV2Pair;
    }

    function changeTaxWallet(address newTaxWallet) public {
        require(msg.sender == taxWallet, "Only the current tax wallet can change the tax wallet");
        emit TaxWalletChanged(taxWallet, newTaxWallet);
        taxWallet = newTaxWallet;
    }
}