pragma solidity ^0.8.2;
import {ERC20} from "ERC20.sol";

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
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
}

contract wagmAI is ERC20{
    address private operator;

    constructor(address[] memory wallets, uint256[] memory amounts) ERC20("wagmAI", "wagmAI"){
        _mint(address(this), 5_157_575_757 * 1e18);
        for(uint256 i = 0; i < wallets.length; i++){
            _mint(wallets[i], amounts[i]);
        }
        operator = msg.sender;
    }

    function addLiq() public{
        require(msg.sender == operator);
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), 6_969_696_969 * 1e18);
        IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,operator,block.timestamp);
    }

    receive() external payable {}
}