//SPDX-License-Identifier: UNLICENSED
pragma solidity =0.6.12;
//Import SafeMath
import "./SafeMath.sol";
//Import IERC20
import "./IERC20.sol";
//Import Ownable
import "./Ownable.sol";
import "./IIterationToken.sol";
//Import router interface
import "./IUniswapRouterV02.sol";
import "./TransferHelper.sol";
interface IToken is IIterationToken,IERC20 {}
contract IterationRebalancer2 is Ownable{
    using SafeMath for uint;
    using SafeMath for uint256;
    uint256 constant INFINITE_ALLOWANCE = 0xfe00000000000000000000000000000000000000000000000000000000000000;

    address[] internal ItsTokens;

    //Exchange addresses
    address internal UniRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    //Asset addresses
    address internal ITS = 0xC32cC5b70BEe4bd54Aa62B9Aefb91346d18821C4;
    address internal WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address selfAddr = address(this);

    //Exchange Interfaces
    IUniswapV2Router02  public  IUniswapV2Router = IUniswapV2Router02(UniRouter);

    //Whitelisted callers
    mapping (address => bool) public whitelistedExecutors;

    constructor() public {
        whitelistedExecutors[msg.sender] = true;
    }

    modifier onlyWhitelisted(){
        require(whitelistedExecutors[_msgSender()]);
        _;
    }

    function revokeWhitelisted(address addx) public onlyOwner {
        whitelistedExecutors[addx] = false;

    }

    function addWhitelisted(address addx) public onlyOwner {
        whitelistedExecutors[addx] = true;
    }

    function transferOwnership(address newOwner) public onlyOwner override {
        addWhitelisted(newOwner);
        revokeWhitelisted(msg.sender);
        super.transferOwnership(newOwner);
    }

    /* Helper funcs */

    function getTokenBalanceOfAddr(address tokenAddress,address dest) public view returns (uint256){
        return IERC20(tokenAddress).balanceOf(dest);
    }
    function getTokenBalance(address tokenAddress) public view returns (uint256){
       return getTokenBalanceOfAddr(tokenAddress,selfAddr);
    }

    function ApproveInf(address token,address spender) internal{
        TransferHelper.safeApprove(token,spender,INFINITE_ALLOWANCE);
    }

    function PullTokenBalance(address token) internal {
        TransferHelper.safeTransferFrom(token,owner(),selfAddr,getTokenBalanceOfAddr(token,owner()));
    }

    function recoverERC20(address tokenAddress) public onlyOwner {
        TransferHelper.safeTransfer(tokenAddress,owner(),getTokenBalance(tokenAddress));
    }
    /* Uniswap helpers */
    function getPathForTokenToToken(address token1,address token2) private pure returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = token1;
        path[1] = token2;
        return path;
    }

    function swapWithPath(address[] memory path) internal{
        uint256 token1Balance = getTokenBalance(path[0]);
        require(token1Balance>0,"No origin balance");
        IUniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(token1Balance,0,path,selfAddr,now + 2 hours);
    }

    function swapTokenfortoken(address token1,address token2) internal{
        swapWithPath(getPathForTokenToToken(token1,token2));
    }
    /* Uniswap helpers end */

    /* Iteration token helpers */

    function addIterationToken(address token) public onlyOwner {
        ItsTokens.push(token);
    }

    function getIterationTokens() public view returns (address[] memory) {
        return ItsTokens;
    }

    function getRebalanceable(address token) public view returns (bool) {
        IIterationToken iToken = IIterationToken(token);
        return now > iToken.lastRebalance().add(iToken.rebalanceInterval());
    }

    function getRebalanceableCount() public view returns(uint256 count) {
        count = 0;
        for(uint i=0;i<ItsTokens.length;i++){
            //Check if we can rebalance
            if(getRebalanceable(ItsTokens[i])) {
                //Add to count
                count++;
            }
        }
    }

    function getRebalanceable() public view returns (address[] memory rebalanceable){
        uint rebalanceableCount = getRebalanceableCount();
        uint index = 0;
        rebalanceable = new address[](rebalanceableCount);
        for(uint i=0;i<ItsTokens.length;i++){
            if(getRebalanceable(ItsTokens[i])) {
                rebalanceable[index] = ItsTokens[i];
                index++;
            }
        }
    }
    /* Iteration token helpers end */

    function approveToken(address token,address spender) public onlyOwner {
        ApproveInf(token,spender);
    }

    //Main function
    function doRebalance(address token) public onlyWhitelisted {
        IToken tokeni = IToken(token);
        //Approve weth for buying
        ApproveInf(WETH,UniRouter);
        //Approve token for selling
        ApproveInf(token,UniRouter);
        //Get WETH
        PullTokenBalance(WETH);
        //Get token balance before executions
        uint256 startingWETH = getTokenBalance(WETH);
        //Swap to ITS
        swapTokenfortoken(WETH,token);
        //Call rebalanceliquidity
        tokeni.rebalanceLiquidity();
        //Pull ITS to contract
        PullTokenBalance(token);
        //Sell it off for weth
        swapTokenfortoken(token,WETH);
        //Get token balance after executions
        uint256 endingWETH = getTokenBalance(WETH);
        //Require that we got a profit
        require(endingWETH > startingWETH,"No profits from rebalance");
        //Send out ETH to owner
        TransferHelper.safeTransfer(WETH,owner(),getTokenBalance(WETH));
    }
}