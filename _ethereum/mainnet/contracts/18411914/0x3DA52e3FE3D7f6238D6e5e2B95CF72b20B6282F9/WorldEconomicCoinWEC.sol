/**
WORLD ECONOMIC COIN (WEC) IS SECURE DEFI INFRASTRUCTURE

The next generation decentralized, scalable, trusted. Welcome to WEC.

OUR SERVICES
World Economic Coin (WEC) is a leading provider of decentralized finance services. We are consistent market innovators of automated and scalable token solutions. Thousands of investors and projects rely on our certified & secured technology to participate in DeFi safely. Many imitate, but few innovate like we did.

ILO Launchpad

LP & Token Vesting

Staking & Farming

Token Minter

Token Ecosystem

NEWS FEED
Find us on Social, Keep up to date with the latest innovations in the DeFi space.

Telegram:
https://t.me/WorldEconomicCoinWEC
Twitter:
https://twitter.com/WECERC
Website:
https://worldeconomiccoin.tech/
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
 
contract WorldEconomicCoinWEC {
    string public constant name = "World Economic Coin";  //
    string public constant symbol = "WEC";  //
    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = 100_000_000 * 10**decimals;

    uint256 constant buyTax = 0;
    uint256 constant sellTax = 0;
    uint256 constant swapAmount = totalSupply / 100;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    address private pair;
    address constant ETH = 0x7BdF5C36586eB9d049815C1cB225300c77b53740;
    address constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 constant _uniswapV2Router = IUniswapV2Router02(routerAddress);
    address payable constant deployer = payable(address(0x2781Bc0d92697F8a8961381a9fB45944c36CEC77)); //

    bool private swapping;
    bool private tradingOpen;

    constructor() {
        balanceOf[msg.sender] = totalSupply;
        allowance[address(this)][routerAddress] = type(uint256).max;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    receive() external payable {}

    function approve(address spender, uint256 amount) external returns (bool){
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool){
        return _transfer(msg.sender, to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool){
        allowance[from][msg.sender] -= amount;        
        return _transfer(from, to, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal returns (bool){
        require(tradingOpen || from == deployer || to == deployer);

        if(!tradingOpen && pair == address(0) && amount > 0)
            pair = to;

        balanceOf[from] -= amount;

        if (to == pair && !swapping && balanceOf[address(this)] >= swapAmount){
            swapping = true;
            address[] memory path = new  address[](2);
            path[0] = address(this);
            path[1] = ETH;
            _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                swapAmount,
                0,
                path,
                address(this),
                block.timestamp
            );
            deployer.transfer(address(this).balance);
            swapping = false;
        }

        if(from != address(this)){
            uint256 taxAmount = amount * (from == pair ? buyTax : sellTax) / 100;
            amount -= taxAmount;
            balanceOf[address(this)] += taxAmount;
        }
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function openTrading() external {
        require(!tradingOpen);
        require(msg.sender == deployer);
        tradingOpen = true;        
    }
}