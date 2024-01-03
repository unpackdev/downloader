// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;
import "./CommonImports.sol";
import "./IERC20Burnable.sol";
import "./IUniswapV2Router02.sol";
import "./IBalancer.sol";

interface IFreeFromUpTo {
    function freeFromUpTo(address from, uint256 value) external returns (uint256 freed);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract BalancerNew is Ownable, IBalancer {
    using SafeMath for uint256;

    address internal UniRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address payable public override treasury;
    IERC20Burnable token;
    IUniswapV2Router02 routerInterface = IUniswapV2Router02(UniRouter);
    address internal WETH = routerInterface.WETH();

    constructor() public {
        treasury = msg.sender;
    }

    function setToken(address tokenAddr) public onlyOwner {
        token = IERC20Burnable(tokenAddr);
    }

    function setTreasury(address treasuryN) external override{
        require(msg.sender == address(token), "only token");
        treasury = payable(treasuryN);
    }

    receive () external payable {}

    /** Path stuff **/
    function getPath(address tokent,bool isSell) internal view returns (address[] memory path){
        path = new address[](2);
        path[0] = isSell ? tokent : WETH;
        path[1] = isSell ? WETH : tokent;
        return path;
    }

    function getSellPath(address tokent) public view returns (address[] memory path) {
        path = getPath(tokent,true);
    }

    function getBuyPath(address tokent) public view returns (address[] memory path){
        path = getPath(tokent,false);
    }
    /** Path stuff end **/

    function rebalance(address rewardRecp) external override returns (uint256) {
        require(msg.sender == address(token), "only token");
        swapEthForTokens();
        uint256 lockableBalance = token.balanceOf(address(this));
        uint256 callerReward = token.getCallerCut(lockableBalance);
        token.transfer(rewardRecp, callerReward);
        token.burn(lockableBalance.sub(callerReward,"Underflow on burn"));
        return lockableBalance.sub(callerReward,"underflow on return");
    }

    function swapEthForTokens() private {

        uint256 treasuryAmount = token.getCallerCut(address(this).balance);
        (bool success,) = treasury.call{value: treasuryAmount}("");
        require(success,"treasury send failed");

        routerInterface.swapExactETHForTokensSupportingFeeOnTransferTokens{value: address(this).balance}(
                0,
                getBuyPath(address(token)),
                address(this),
                block.timestamp.add(200)
            );
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        //Approve before swap
        token.approve(UniRouter,tokenAmount);
        routerInterface.swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokenAmount,
                0,
                getSellPath(address(token)),
                address(this),
                block.timestamp.add(200)
        );
    }



    function addLiq(uint256 tokenAmount,uint256 ethamount) private {
        //Approve before adding liq
        token.approve(UniRouter,tokenAmount);
        routerInterface.addLiquidityETH{value:ethamount}(
            address(token),
            tokenAmount,
            0,
            ethamount.div(2),//Atleast half of eth should be added
            address(token),
            block.timestamp.add(200)
        );
    }

    function AddLiq() external override returns (bool) {
        //Sell half of the amount to ETH
        uint256 tokenAmount  = token.balanceOf(address(this)).div(2);
        //Swap half of it to eth
        swapTokensForETH(tokenAmount);
        //Add liq with remaining eth and tokens
        addLiq(token.balanceOf(address(this)),address(this).balance);
        //If any eth remains swap to token
        if(address(this).balance > 0)
            swapEthForTokens();
        return true;
    }

}