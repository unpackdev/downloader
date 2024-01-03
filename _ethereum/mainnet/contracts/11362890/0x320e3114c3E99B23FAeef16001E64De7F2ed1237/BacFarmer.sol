//SPDX-License-Identifier: UNLICENSED
pragma solidity =0.6.12;
//Import router interface
import "./IUniswapRouterV02.sol";
//Import SafeMath
import "./SafeMath.sol";
//Import IERC20
import "./IERC20.sol";
//Import Ownable
import "./Ownable.sol";

import "./TransferHelper.sol";

interface IBasisCashPool {
  function DURATION (  ) external view returns ( uint256 );
  function balanceOf ( address account ) external view returns ( uint256 );
  function basisCash (  ) external view returns ( address );
  function dai (  ) external view returns ( address );
  function deposits ( address ) external view returns ( uint256 );
  function earned ( address account ) external view returns ( uint256 );
  function exit (  ) external;
  function getReward (  ) external;
  function lastTimeRewardApplicable (  ) external view returns ( uint256 );
  function lastUpdateTime (  ) external view returns ( uint256 );
  function notifyRewardAmount ( uint256 reward ) external;
  function owner (  ) external view returns ( address );
  function periodFinish (  ) external view returns ( uint256 );
  function renounceOwnership (  ) external;
  function rewardDistribution (  ) external view returns ( address );
  function rewardPerToken (  ) external view returns ( uint256 );
  function rewardPerTokenStored (  ) external view returns ( uint256 );
  function rewardRate (  ) external view returns ( uint256 );
  function rewards ( address ) external view returns ( uint256 );
  function setRewardDistribution ( address _rewardDistribution ) external;
  function stake ( uint256 amount ) external;
  function starttime (  ) external view returns ( uint256 );
  function totalSupply (  ) external view returns ( uint256 );
  function transferOwnership ( address newOwner ) external;
  function userRewardPerTokenPaid ( address ) external view returns ( uint256 );
  function withdraw ( uint256 amount ) external;
}

contract BACFarmerv3 is Ownable{
    using SafeMath for uint;
    using SafeMath for uint256;

    address public UniRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    uint256 constant INFINITE_ALLOWANCE = 0xfe00000000000000000000000000000000000000000000000000000000000000;

    //Pool addresses
    address public DaiPool = 0xEBd12620E29Dc6c452dB7B96E1F190F3Ee02BDE8;
    address public USDTPool = 0x2833bdc5B31269D356BDf92d0fD8f3674E877E44;
    address public USDCPool = 0x51882184b7F9BEEd6Db9c617846140DA1d429fD4;
    address public SUSDPool = 0xDc42a21e38C3b8028b01A6B00D8dBC648f93305C;

    //Asset addresses
    address public BAS  = 0x3449FC1Cd036255BA1EB19d65fF4BA2b8903A69a;
    address public USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public SUSD = 0x57Ab1ec28D129707052df4dF418D58a2D46d5f51;


    //Pool interfaces
    IBasisCashPool iDaiPool = IBasisCashPool(DaiPool);
    IBasisCashPool iUSDTPool = IBasisCashPool(USDTPool);
    IBasisCashPool iUSDCPool = IBasisCashPool(USDCPool);
    IBasisCashPool iSUSDPool = IBasisCashPool(SUSDPool);


    address selfAddr = address(this);

    //Bools for internal stuff
    bool approved = false;
    bool reinvestDAi = false;


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


    function hasTokens(address token) internal view returns (bool) {
        return getTokenBalance(token) > 0;
    }

    function ApproveInf(address token,address spender) internal{
        TransferHelper.safeApprove(token,spender,INFINITE_ALLOWANCE);
    }

    function doApprovals() public {
        //Approve bas to swap to dai
        ApproveInf(BAS,UniRouter);
        //Approve tokens for the pools
        ApproveInf(USDT,USDTPool);
        ApproveInf(USDC,USDCPool);
        ApproveInf(DAI,DaiPool);
        ApproveInf(SUSD,SUSDPool);
        approved = true;
    }

    function PullTokenBalance(address token) internal {
        TransferHelper.safeTransferFrom(token,owner(),selfAddr,getTokenBalanceOfAddr(token,owner()));
    }

    function pullStables() public onlyOwner {
        PullTokenBalance(USDT);
        PullTokenBalance(USDC);
        PullTokenBalance(DAI);
        PullTokenBalance(SUSD);
    }

    function toggleReinvest() public onlyOwner {
        reinvestDAi = !reinvestDAi;
    }

    function depositAll() public onlyOwner {
        //Get balances
        uint256 usdtBal = getTokenBalance(USDT);
        uint256 usdcBal = getTokenBalance(USDC);
        uint256 daiBal = getTokenBalance(DAI);
        uint256 susdBal = getTokenBalance(SUSD);

        //Check balance and deposit
        if(usdtBal > 0)
            iUSDTPool.stake(usdtBal);

        if(usdcBal > 0)
            iUSDCPool.stake(usdcBal);

        if(daiBal > 0)
            iDaiPool.stake(daiBal);

        if(susdBal > 0)
            iSUSDPool.stake(susdBal);
    }

    function withdrawAll() public onlyOwner {
        //Call exit on all pools,which gives collateral and rewards
        iSUSDPool.exit();
        iUSDCPool.exit();
        iDaiPool.exit();
        iUSDTPool.exit();
    }

    function getRewards() public onlyWhitelisted {
        //Get bas rewards
        iSUSDPool.getReward();
        iUSDCPool.getReward();
        iDaiPool.getReward();
        iUSDTPool.getReward();
    }

    function recoverERC20(address tokenAddress) public onlyOwner {
        TransferHelper.safeTransfer(tokenAddress,owner(),getTokenBalance(tokenAddress));
    }

    function getPathForTokenToToken(address token1,address token2) private pure returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = token1;
        path[1] = token2;
        return path;
    }

    function swapWithPath(address[] memory path) internal{
        uint256 token1Balance = getTokenBalance(path[0]);
        IUniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(token1Balance,0,path,selfAddr,now + 2 hours);
    }

    function swapTokenfortoken(address token1,address token2) internal{
        swapWithPath(getPathForTokenToToken(token1,token2));
    }

    function takeProfits() public onlyWhitelisted {
        getRewards();
        if(getTokenBalance(BAS) > 0)
            swapTokenfortoken(BAS,DAI);
        uint256 daiBal = getTokenBalance(DAI);
        if(reinvestDAi && daiBal > 0) {
            //ReInvest DAI back in pool
            iDaiPool.stake(daiBal);
        }
    }

    function withdrawStables() public onlyOwner {
        withdrawAll();
        //Sell profits to dai
        if(getTokenBalance(BAS) > 0) {
            swapTokenfortoken(BAS,DAI);
        }
        //Get balances
        uint256 usdtBal = getTokenBalance(USDT);
        uint256 usdcBal = getTokenBalance(USDC);
        uint256 daiBal = getTokenBalance(DAI);
        uint256 susdBal = getTokenBalance(SUSD);
        //Withdraw the stables from contract
        if(usdtBal > 0)
            recoverERC20(USDT);
        if(usdcBal > 0)
            recoverERC20(USDC);
        if(daiBal > 0)
            recoverERC20(DAI);
        if(susdBal > 0)
            recoverERC20(SUSD);
    }

}