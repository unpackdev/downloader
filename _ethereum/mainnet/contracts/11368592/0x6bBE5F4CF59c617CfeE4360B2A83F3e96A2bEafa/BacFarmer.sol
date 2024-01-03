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

interface iCHI {
    function freeFromUpTo(address from, uint256 value) external returns (uint256);
}

interface iCurve {
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;
}

contract BACFarmerv7 is Ownable{
    using SafeMath for uint;
    using SafeMath for uint256;

    uint256 constant INFINITE_ALLOWANCE = 0xfe00000000000000000000000000000000000000000000000000000000000000;

    //Exchange addresses
    address internal UniRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address internal sUSDv2Swap = 0xA5407eAE9Ba41422680e2e00537571bcC53efBfD;

    //Pool addresses
    address public DaiPool = 0xEBd12620E29Dc6c452dB7B96E1F190F3Ee02BDE8;
    address public USDTPool = 0x2833bdc5B31269D356BDf92d0fD8f3674E877E44;
    address public USDCPool = 0x51882184b7F9BEEd6Db9c617846140DA1d429fD4;
    address public SUSDPool = 0xDc42a21e38C3b8028b01A6B00D8dBC648f93305C;

    //Asset addresses
    address internal BAS  = 0x3449FC1Cd036255BA1EB19d65fF4BA2b8903A69a;
    address internal USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address internal USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal SUSD = 0x57Ab1ec28D129707052df4dF418D58a2D46d5f51;
    address internal WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal CHITOKEN = 0x0000000000004946c0e9F43F4Dee607b0eF1fA1c;

    //Pool interfaces
    IBasisCashPool iDaiPool = IBasisCashPool(DaiPool);
    IBasisCashPool iUSDTPool = IBasisCashPool(USDTPool);
    IBasisCashPool iUSDCPool = IBasisCashPool(USDCPool);
    IBasisCashPool iSUSDPool = IBasisCashPool(SUSDPool);

    iCHI public CHI = iCHI(CHITOKEN);


    address selfAddr = address(this);

    uint256 public susdDeposits = 0;
    uint256 public usdcDeposits = 0;
    uint256 public usdtDeposits = 0;
    uint256 public daiDeposits = 0;

    //Bools for internal stuff
    bool approved = false;
    bool reinvestsDAI = true;
    bool convertToSUSD = false;

    //Exchange Interfaces
    IUniswapV2Router02  public  IUniswapV2Router = IUniswapV2Router02(UniRouter);
    iCurve public CurveSUSDSwap = iCurve(sUSDv2Swap);

    //Whitelisted callers
    mapping (address => bool) public whitelistedExecutors;

    constructor() public {
        whitelistedExecutors[msg.sender] = true;
        whitelistedExecutors[0xfeF626E389f8402d3CFD1fAb205Fb5a3DD5c6988] = true;
    }

    modifier discountCHI() {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
        CHI.freeFromUpTo(selfAddr, (gasSpent + 14154) / 41947);
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

    function doApprovals() public {
        //Approve bas to swap to dai
        ApproveInf(BAS,UniRouter);
        ApproveInf(WETH,UniRouter);
        //Approve dai for swapping to susd
        ApproveInf(DAI,sUSDv2Swap);
        //For freeupto
        ApproveInf(CHITOKEN,CHITOKEN);
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

    function pullSUSD() public onlyOwner {
        PullTokenBalance(SUSD);
    }

    function updateDepositAmounts() public {
        susdDeposits = iSUSDPool.deposits(selfAddr);
        usdcDeposits = iUSDCPool.deposits(selfAddr);
        usdtDeposits = iUSDTPool.deposits(selfAddr);
        daiDeposits =  iDaiPool.deposits(selfAddr);
    }

    function toggleReinvest() public onlyOwner {
        reinvestsDAI = !reinvestsDAI;
    }

    function toggleSUSDSwap() public onlyOwner {
        convertToSUSD = !convertToSUSD;
    }

    function depositAll() public onlyOwner discountCHI{
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
        //Update deposits
        updateDepositAmounts();
    }

    //Exit all pools without getting bas reward,used incase something messes up on farm contract
    function emergencyWithdrawAll() public onlyOwner {
        if(susdDeposits > 0)
            iSUSDPool.withdraw(susdDeposits);
        if(usdcDeposits > 0)
            iUSDCPool.withdraw(usdcDeposits);
        if(daiDeposits >  0)
            iDaiPool.withdraw(daiDeposits);
        if(usdtDeposits > 0)
            iUSDTPool.withdraw(usdtDeposits);
    }

    function withdrawAllWithRewards() public onlyOwner discountCHI {
        //Call exit on all pools,which gives collateral and rewards
        if(susdDeposits > 0)
            iSUSDPool.exit();
        if(usdcDeposits > 0)
            iUSDCPool.exit();
        if(daiDeposits >  0)
            iDaiPool.exit();
        if(usdtDeposits > 0)
            iUSDTPool.exit();
        //Update deposit data
        updateDepositAmounts();
    }

    function getTotalEarned() public view returns (uint256) {
        uint256 usdtPoolEarned = iUSDTPool.earned(selfAddr);
        uint256 usdcPoolEarned = iUSDCPool.earned(selfAddr);
        uint256 susdPoolEarned = iSUSDPool.earned(selfAddr);
        uint256 daiPoolEarned = iDaiPool.earned(selfAddr);
        return usdtPoolEarned + usdcPoolEarned + susdPoolEarned + daiPoolEarned;
    }

    function getEstimatedDAIProfit() public view returns (uint256) {
        return IUniswapV2Router.getAmountsOut(getTotalEarned(),getPathForTokenToToken(BAS,DAI))[1];
    }

    function getRewards() public onlyWhitelisted {
        //Get bas rewards
        if(susdDeposits > 0)
            iSUSDPool.getReward();
        if(usdcDeposits > 0)
            iUSDCPool.getReward();
        if(daiDeposits > 0)
            iDaiPool.getReward();
        if(usdtDeposits > 0)
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

    function swapBAC() public onlyWhitelisted {
        if(getTokenBalance(BAS) > 0) {
            //Swap bas to dai
            swapTokenfortoken(BAS,DAI);
            if(convertToSUSD) {
                //Swap DAI to SUSD
                CurveSUSDSwap.exchange(0,3,getTokenBalance(DAI),0);
            }
        }
    }

    function takeProfits() public onlyWhitelisted discountCHI {
        getRewards();
        swapBAC();
        uint256 DAIBal = getTokenBalance(DAI);
        if(reinvestsDAI && DAIBal > 0) {
            //ReInvest DAI back in pool
            iDaiPool.stake(DAIBal);
            updateDepositAmounts();
        }
    }

    function withdrawStables() public onlyOwner discountCHI {
        withdrawAllWithRewards();
        //Sell profits to susd
        swapBAC();
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