// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

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

contract VenusToken is ERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => bool) public whitelisted;
    bool public marketOpened;
    bool public marketHalted;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    constructor() ERC20("Venus Token", "VNT") {
        _mint(_msgSender(), 20_000_000 * 10 ** decimals());
        _mint(address(this), 10_000_000 * 10 ** decimals());

        whitelisted[_msgSender()] = true;
        whitelisted[address(this)] = true;
    }

    receive() external payable {}

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if(to == uniswapV2Pair && !whitelisted[from]){
            require(!marketHalted, "Market is halted; will resume soon!");
        }

        super._transfer(from, to, amount);
    }

    function openMarket() external onlyOwner() {
        require(!marketOpened,"Market is already open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), totalSupply());
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this), 
            balanceOf(address(this)), 
            0, 
            0,
            owner(), 
            block.timestamp
        );
        
        whitelisted[uniswapV2Pair] = true;
        whitelisted[address(uniswapV2Router)] = true;

        marketOpened = true;
    }

    function whitelist(address account) external onlyOwner() {
        whitelisted[account] = true;
    }

    function updateMarketHalted(bool value) external onlyOwner() {
        marketHalted = value;
    }

    function withdrawETH(address account) external onlyOwner() {
        uint ethBalance = address(this).balance;
        payable(account).transfer(ethBalance);
    }

    function withdrawERC20(address token, address account) external onlyOwner() {
        IERC20 erc20 = IERC20(token);
        uint tokenBalance = erc20.balanceOf(address(this));
        erc20.transfer(account, tokenBalance);
    }
}