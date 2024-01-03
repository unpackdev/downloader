import "./IUniswapV2Router.sol";
import "./IERC20.sol";
import "./Ownable.sol";

interface ITokenMigrator {
  function RL3R (  ) external view returns ( address );
  function RLR (  ) external view returns ( address );
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
    //Contract that swaps rl3r to rlr
    address RLRSwapper = 0x9BA7df487877A7E216856FBEeD93CE5920722cCa;
    address LPPairRL3R = 0xc930Fedc53A8426203C9203079CA76D49f65b964;
    address TimeLockContract = 0x4cB704CAdD196d0d0aFc84aAd7f9DddE407c5aB5;

    IUniswapV2Router  public  uniswapInterface = IUniswapV2Router(UniRouter);

    ITokenMigrator public tokenMigrator = ITokenMigrator(RLRSwapper);

    function removeETHLiquidityFromToken() public onlyOwner {
        //Approve token and lp token to be spent
         IERC20(tokenMigrator.RL3R()).approve(UniRouter,getTokenBalance(tokenMigrator.RL3R()));
         IERC20(LPPairRL3R).approve(UniRouter,getTokenBalance(LPPairRL3R));

        // remove liquidity
        uniswapInterface.removeLiquidityETH(tokenMigrator.RL3R(), getTokenBalance(LPPairRL3R), 1, 1, address(this), now + 20);
    }

    receive() external payable {
        if(msg.sender != UniRouter){
            revert();
        }
    }

    function SwapRL3RToRLR() public onlyOwner {
        //Approve spend of rl3r tokens by swapper contact
        IERC20(tokenMigrator.RL3R()).approve(RLRSwapper,getTokenBalance(tokenMigrator.RL3R()));
        //Swap it
        tokenMigrator.swapTokens(getTokenBalance(tokenMigrator.RL3R()));
    }

    function AddLiqRLR() public onlyOwner {
        uint256 tokenBalance = getTokenBalance(tokenMigrator.RLR());
        //Approve uniswap router to spend token and weth
        IERC20(tokenMigrator.RLR()).approve(UniRouter,tokenBalance);

        uniswapInterface.addLiquidityETH
        {value : address(this).balance }
        (
            tokenMigrator.RLR(),
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
        SwapRL3RToRLR();
        AddLiqRLR();
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
