// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./ERC20.sol";

/*
        ┌┼┐╦╔═╔═╗╦  
        └┼┐╠╩╗║ ║║  
        └┼┘╩ ╩╚═╝╩═╝

        https://kols.life
        Rewarding LPs like none other.
        Fees can be seen here: https://v2.info.uniswap.org/accounts
*/

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router {
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
        ) external returns (uint[] memory amounts);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
        ) external;
}

interface IUniswapV2Pair {
    function sync() external;
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function balanceOf(address) external returns (uint);
}

contract KOL is ERC20 {
    address payable public operations;
    address public uniswapV2WETHPair;
    uint public liquidityAdded;
    bool antisnipe = true;
    bool depth = false;
    uint supplyDivisor = 1000;
    uint sellFee = 5;
    uint buyFee = 5;
    mapping(address => bool) public isUniswapPair;
    
    IWETH weth;
    IUniswapV2Router uniswapV2Router;
    
    error OnlyOps();
    error AntiSnipe();
    error NoBalance();
    error NotZero();
    error NotGreaterThanFive();

    receive() external payable {}

    constructor() ERC20("KOL", "KOL", 18) {
        operations = payable(msg.sender);
        uniswapV2Router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2WETHPair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        isUniswapPair[uniswapV2WETHPair] = true;
        weth = IWETH(uniswapV2Router.WETH());
        _mint(msg.sender, 21_000_000 * 10 ** 18);
    }

    function addUniswapPair(address pair) external {
        if(msg.sender != operations) revert OnlyOps();
        isUniswapPair[pair] = true;
    }

    function forceSwap() external {
        if(msg.sender != operations) revert OnlyOps();
        if(balanceOf[address(this)] == 0) revert NoBalance();
        swapTokens(balanceOf[address(this)]);
        IUniswapV2Pair(uniswapV2WETHPair).sync();
    }

    function changeOperations(address payable operations_) external {
        if(msg.sender != operations) revert OnlyOps();
        if(operations_ == address(0)) revert NotZero();
        operations = operations_;
    }

    function changeSupplyDivisor(uint supplyDivisor_) external {
        if(msg.sender != operations) revert OnlyOps();
        if(supplyDivisor_ == 0) revert NotZero();
        supplyDivisor = supplyDivisor_;
    }

    function changeSellFee(uint sellFee_) external {
        if(msg.sender != operations) revert OnlyOps();
        if(sellFee_ > 5) revert NotGreaterThanFive();
        sellFee = sellFee_;
    }

    function changeBuyFee(uint buyFee_) external {
        if(msg.sender != operations) revert OnlyOps();
        if(buyFee_ > 5) revert NotGreaterThanFive();
        buyFee = buyFee_;
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool){
        if(isUniswapPair[msg.sender] && to != operations && to != address(this)) {
            uint256 fee = (amount * buyFee) / 100;
            super.transfer(address(this), fee);
            if(antisnipe && liquidityAdded != 0) {
                if(block.number - liquidityAdded < 600) {
                    if(amount > (totalSupply / 300) * ((block.number - liquidityAdded)/2)) return false;
                }
                else antisnipe = false;
            }
            return super.transfer(to, amount - fee);
        }    
        return super.transfer(to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        if(isUniswapPair[to] ) {
            if(liquidityAdded == 0) 
                liquidityAdded = block.number;
            if(from != operations && from != address(this)){
                uint256 fee = (amount * sellFee) / 100;
                super.transferFrom(from, address(this), fee);
                uint256 balance = balanceOf[address(this)];
                if(balance > totalSupply / supplyDivisor && !depth)  {
                    depth = true;
                    swapTokens(balance);
                    depth = false;
                }     
                return super.transferFrom(from, to, amount - fee);
            }
        }
        return super.transferFrom(from, to, amount);
    }

    function swapTokens(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(weth);
        ERC20(address(this)).approve(address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
        weth.deposit{value: address(this).balance/2}();
        weth.transfer(uniswapV2WETHPair, weth.balanceOf(address(this)));
        (bool success,) = operations.call{value: address(this).balance}("");
    }
}