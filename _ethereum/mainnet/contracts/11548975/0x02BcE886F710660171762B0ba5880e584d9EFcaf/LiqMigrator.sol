// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./IUniswapV2Router.sol";
import "./IERC20.sol";
import "./Ownable.sol";

interface ITokenMigrator {
  function OriginToken (  ) external view returns ( address );
  function DestToken (  ) external view returns ( address );
  function owner (  ) external view returns ( address );
  function pauseSwap (  ) external;
  function recoverERC20 ( address tokenAddress ) external;
  function renounceOwnership (  ) external;
  function setBurn ( bool fBurn ) external;
  function swapTokens ( uint256 tokensToSwap ) external;
  function totalSwapped (  ) external view returns ( uint256 );
  function transferOwnership ( address newOwner ) external;
  function unpauseSwap (  ) external;
}

contract LiqMigratorNew is Ownable{

    address UniRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address LPPairOriginToken;

    IUniswapV2Router  public  uniswapInterface = IUniswapV2Router(UniRouter);
    ITokenMigrator public tokenMigrator;

    constructor (address tokenMigratoraddr,address LPPair) public {
        tokenMigrator = ITokenMigrator(tokenMigratoraddr);
        LPPairOriginToken = LPPair;
    }

    function removeETHLiquidityFromToken() public onlyOwner {
        //Approve token and lp token to be spent
         IERC20(tokenMigrator.OriginToken()).approve(UniRouter,getTokenBalance(tokenMigrator.OriginToken()));
         IERC20(LPPairOriginToken).approve(UniRouter,getTokenBalance(LPPairOriginToken));

        // remove liquidity
        uniswapInterface.removeLiquidityETH(tokenMigrator.OriginToken(), getTokenBalance(LPPairOriginToken), 1, 1, address(this), now + 20);
    }

    receive() external payable {
        if(msg.sender != UniRouter){
            revert();
        }
    }

    function SwapTokens() public onlyOwner {
        //Approve spend of rl3r tokens by swapper contact
        IERC20(tokenMigrator.OriginToken()).approve(address(tokenMigrator),getTokenBalance(tokenMigrator.OriginToken()));
        //Swap it
        tokenMigrator.swapTokens(getTokenBalance(tokenMigrator.OriginToken()));
    }

    function AddLiq() public onlyOwner {
        uint256 tokenBalance = getTokenBalance(tokenMigrator.DestToken());
        //Approve uniswap router to spend token and weth
        IERC20(tokenMigrator.DestToken()).approve(UniRouter,tokenBalance);

        uniswapInterface.addLiquidityETH
        {value : address(this).balance }
        (
            tokenMigrator.DestToken(),
            tokenBalance,
            tokenBalance,
            address(this).balance,
            owner(),
            now
        );
    }

    function recoverERC20(address tokenAddress) public onlyOwner {
        IERC20(tokenAddress).transfer(msg.sender, getTokenBalance(tokenAddress));
    }

    function getTokenBalance(address tokenAddress) public view returns (uint256){
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function MigrateLiq() public onlyOwner{
        removeETHLiquidityFromToken();
        SwapTokens();
        AddLiq();
        //Finally unpause the swap contract
        tokenMigrator.unpauseSwap();
    }

    function unpauseSwap() public onlyOwner {
        tokenMigrator.unpauseSwap();
    }

    function pauseSwap() public onlyOwner {
        tokenMigrator.pauseSwap();
    }

    function recoverERC20FromSwapContract(address token) public onlyOwner{
        tokenMigrator.recoverERC20(token);
    }

    function returnSwapContractOwnership() public onlyOwner {
        tokenMigrator.transferOwnership(owner());
    }

}
