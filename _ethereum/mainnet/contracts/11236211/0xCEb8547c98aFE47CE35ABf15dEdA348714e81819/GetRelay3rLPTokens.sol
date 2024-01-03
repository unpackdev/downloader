// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
import "./TokenHelper.sol";
import "./UniswapV2Library.sol";

import "./IUniswapV2Router.sol";
import "./IWETH.sol";

contract GetRelay3rLPTokens{
    //define constants
    bool hasApproved = false;
    address owner = msg.sender;
    uint constant public INF = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    address self = address(this);

    address public  UniswapRouter;
    IERC20 public KeeperInterface;
    IUniswapV2Router uniswapInterface;
    IERC20 public pairInterface;
    IWETH wethInterface;
    constructor(address UniRouter,address KeeperToken) public{
        UniswapRouter = UniRouter;
        KeeperInterface = IERC20(KeeperToken);
        uniswapInterface = IUniswapV2Router(UniswapRouter);
        pairInterface = IERC20(UniswapV2Library.pairFor(uniswapInterface.factory(),address(KeeperInterface),uniswapInterface.WETH()));
        wethInterface = IWETH(uniswapInterface.WETH());
    }


     function getPathForETHToToken() private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = uniswapInterface.WETH();
        path[1] = address(KeeperInterface);
        return path;
    }

    function doInfiniteApprove(IERC20 token) internal{
        token.approve(UniswapRouter, INF);
    }

    function DoApprove() internal {
        doInfiniteApprove(KeeperInterface);
        doInfiniteApprove(pairInterface);
        doInfiniteApprove(wethInterface);
    }

    function getKeeperBalance() public view returns (uint256){
       return tokenHelper.getTokenBalance(address(KeeperInterface));
    }

    function getWETHBalance() public view returns (uint256){
        return tokenHelper.getTokenBalance(uniswapInterface.WETH());
    }

    receive() external payable {
        if(msg.sender != UniswapRouter || msg.sender != address(wethInterface))
            deposit();
    }

    function deposit() public payable{
        if(!hasApproved){
            DoApprove();
        }
        //Convert ETH to WETH
        wethInterface.deposit{value:msg.value}();
        convertWETHToKP3R();
        addLiq(msg.sender);
        //Send back the eth dust given from refund
        if(getWETHBalance() > 0){
            wethInterface.withdraw(getWETHBalance());
            (bool success,  ) = msg.sender.call{value : address(this).balance}("");
            require(success,"Refund failed");
        }
    }

    function convertWETHToKP3R() internal {
        uniswapInterface.swapExactTokensForTokensSupportingFeeOnTransferTokens(getWETHBalance() / 2,1,getPathForETHToToken(),self,INF);
    }

    function addLiq(address dest) internal {
        //finally add liquidity
        uniswapInterface.addLiquidity(address(KeeperInterface),uniswapInterface.WETH(),getKeeperBalance(),getWETHBalance(),1,1,dest,INF);
    }

    function withdrawFunds() public {
        tokenHelper.recoverERC20(uniswapInterface.WETH(),owner);
        tokenHelper.recoverERC20((address(KeeperInterface)),owner);
    }
}
