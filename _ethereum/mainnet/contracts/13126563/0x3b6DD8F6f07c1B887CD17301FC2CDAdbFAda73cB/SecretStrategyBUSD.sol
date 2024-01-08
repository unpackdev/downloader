// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./IConvexDeposit.sol";
import "./IConvexWithdraw.sol";
import "./ICurvePool.sol";
import "./ICurvePool2.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./ITangoFactory.sol";
import "./IWETH.sol";
import "./ISecretBridge.sol";

contract Constant { 
    address public constant uniRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant sushiRouter = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    address public constant uniswapV2Factory =
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public constant wETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 public constant deadline =
        0xf000000000000000000000000000000000000000000000000000000000000000;
    address public constant ust = 0xa47c8bf37f92aBed4A126BDA807A7b7498661acD;
    address public constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant crv = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address public constant cvx = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    address public constant curveBUSDPool = 0xb6c057591E073249F2D9D88Ba59a46CFC9B59EdB;
    address public constant curveUSTPool = 0x890f4e345B1dAED0367A877a1612f86A1f86985f;
    address public constant curveLpToken = 0x3B3Ac5386837Dc563660FB6a0937DFAa5924333B;
    address public constant curveExchangeBUSD = 0x79a8C46DeA5aDa233ABaFFD40F3A0A2B1e5A4F27;
    address public constant convexDeposit = 0xF403C135812408BFbE8713b5A23a04b3D48AAE31;
    address public constant convexWithDrawAndClaim = 0x602c4cD53a715D8a7cf648540FAb0d3a2d546560;
    uint256 public constant pidBUSD = 3;
}

contract SecretStrategyBUSD is ITangoFactory, Constant, Ownable { 
    using SafeERC20 for IERC20;

    uint256 public secretUST;
    uint256 public reversedUST;
    uint256 public stakedBalance;
    uint256 public depositFee;
    uint256 public rewardFee;
    uint256 public totalDepositFee;
    uint256 public totalRewardFee;
    uint256 public totalUSTDeposited;
    address public router;

    modifier onlyRouter() {
        require(msg.sender == router,"Only-router");
        _;
    }

    event Invest(address _user, uint256 _amount);
    event Withdraw(address _user, uint256 _amount);
    constructor(address _router) {
        router = _router;
        IERC20(curveLpToken).safeApprove(curveBUSDPool, type(uint256).max);
        IERC20(curveLpToken).safeApprove(convexDeposit, type(uint256).max);
        IERC20(usdc).safeApprove(curveUSTPool, type(uint256).max);
        IERC20(dai).safeApprove(curveUSTPool, type(uint256).max);
        IERC20(ust).safeApprove(curveUSTPool, type(uint256).max);

        IERC20(usdc).safeApprove(curveBUSDPool, type(uint256).max);
        IERC20(dai).safeApprove(curveBUSDPool, type(uint256).max);
        transferOwnership(0xfc0962770A2A1d142f7b48cb40d04001c73Af840);
    }

    function adminSetFee(uint256 _depositFee, uint256 _rewardFee) external onlyOwner() {
        depositFee = _depositFee;
        rewardFee = _rewardFee;
    }

    function adminCollectFee(address _to) external onlyOwner() {
        IERC20(ust).safeTransfer(_to, totalDepositFee);
        IERC20(wETH).safeTransfer(_to, totalRewardFee);
        totalDepositFee = 0;
        totalRewardFee = 0;
    }

    function adminWithdrawToken(address _token, address _to) external onlyOwner() {
        IERC20(_token).safeTransfer(_to, IERC20(_token).balanceOf(address(this)));
    }

     /**
     * @dev swap token at UniswapV2Router with path fromToken - WETH - toToken
     * @param _fromToken is source token
     * @param _toToken is des token
     * @param _swapAmount is amount of source token to swap
     * @return _amountOut is the amount of _toToken 
     */
    function _uniswapSwapToken(
        address _router,
        address _fromToken,
        address _toToken,
        uint256 _swapAmount
    ) private returns (uint256 _amountOut) {
        if(IERC20(_fromToken).allowance(address(this), _router) == 0) {
            IERC20(_fromToken).safeApprove(_router, type(uint256).max);
        }        
        address[] memory path;
        if(_fromToken == wETH || _toToken == wETH) {
            path = new address[](2);
            path[0] = _fromToken == wETH ? wETH : _fromToken;
			path[1] = _toToken == wETH ? wETH : _toToken;
        } else { 
            path = new address[](3);
            path[0] = _fromToken;
            path[1] = wETH;
            path[2] = _toToken;
        }
       
        _amountOut = IUniswapV2Router02(_router)
            .swapExactTokensForTokens(
            _swapAmount,
            0,
            path,
            address(this),
            deadline
        )[path.length - 1];
    }

    /**
     * @dev add liquidity to Curve at UST poool
     * @param _curvePool is curve liqudity pool address
     * @param _param is [ust, dai, usdc, usdt]
     * @return amount of lp token
     */
    function _curveAddLiquidity(address _curvePool, uint256[4] memory _param) private returns(uint256) { 
        return ICurvePool(_curvePool).add_liquidity(_param, 0);
    }

    /**
     * @dev add liquidity to Curve at UST poool
     * @param _curvePool is curve liqudity pool address
     * @param _curveLpBalance is amount lp token
     * @param i is index of toke
     * @return amount of lp token
     */
    function _curveRemoveLiquidity(address _curvePool, uint256 _curveLpBalance, int128 i) private returns(uint256) { 
        return ICurvePool(_curvePool).remove_liquidity_one_coin(_curveLpBalance, i, 0);
    }

    function calculateLpAmount(address _curvePool, uint256 _daiAmount) private returns (uint256){
        return ICurvePool(_curvePool).calc_token_amount([_daiAmount, 0, 0, 0], false);
    }
    
    function exchangeUnderlying(address _curvePool, uint256 _dx, int128 i, int128 j) private returns (uint256) {
        return ICurvePool(_curvePool).exchange_underlying(i, j, _dx, 0);
    }
    function secretInvest(address _user, address _token, uint256 _amount) external override onlyRouter() {
        uint256 depositAmount = _amount;
        if(depositFee > 0) {
            uint256 fee = depositAmount * depositFee / 10000;
            depositAmount = depositAmount - fee;
            totalDepositFee = totalDepositFee + fee;
        }
        secretUST = secretUST + depositAmount;
        totalUSTDeposited = totalUSTDeposited + _amount;
        emit Invest(_user, _amount);
    }

    function secretWithdraw(address _user, uint256 _amount) external override onlyRouter() {
        // expect that _amount is UST amunt, equal to lpAmout, but buffer for making it more chance to success
        uint256 _requestAmount = _amount;
        if (secretUST > _amount) {
            IERC20(ust).safeTransfer(_user, _amount);
            secretUST = secretUST - _amount;
            return;
        }
        if (reversedUST > 0) { 
            if (reversedUST >= _amount) {
                IERC20(ust).safeTransfer(_user, _amount);
                reversedUST = reversedUST - _amount;
                return;
            }
            _amount = _amount - reversedUST;
            reversedUST = 0;
        }
        uint256 lpAmount = calculateLpAmount(curveExchangeBUSD ,_amount) * 101 / 100; // extra 1%
        _withdraw(convexWithDrawAndClaim, lpAmount);
        uint256 balanceUSDC = IERC20(usdc).balanceOf(address(this));
        ICurvePool2(curveBUSDPool).remove_liquidity_one_coin(lpAmount, 1, 0);
        uint256 swapBalance = IERC20(usdc).balanceOf(address(this)) - balanceUSDC;
        uint256 balanceUST = exchangeUnderlying(curveUSTPool, swapBalance, 2, 0);
        require(balanceUST >= _amount, "Invalid-amount");
        if(balanceUST > _amount) {
            reversedUST  = reversedUST + balanceUST - _amount;
        }
        IERC20(ust).safeTransfer(_user, _requestAmount);
        emit Withdraw(_user, _amount);
    }

    function adminClaimRewardForSCRT(address _secretBridge, address _secretSW, bytes memory _recipient) external override onlyOwner() { 
        uint256 wETHBalanceBefore = IERC20(wETH).balanceOf(address(this));
        uint256 balanceCRV = IERC20(crv).balanceOf(address(this));
        uint256 balanceCVX = IERC20(cvx).balanceOf(address(this));
        IConvexWithdraw(convexWithDrawAndClaim).getReward();
        uint256 amountCRV = IERC20(crv).balanceOf(address(this)) - balanceCRV;
        uint256 amountCVX = IERC20(cvx).balanceOf(address(this)) - balanceCVX;
        if(amountCRV > 0) {
            _uniswapSwapToken(uniRouter, crv, wETH, amountCRV);
        }
        if(amountCVX > 0) {
            _uniswapSwapToken(sushiRouter, cvx, wETH, amountCVX);
        }
        uint256 wETHBalanceAfter = IERC20(wETH).balanceOf(address(this));
        uint256 balanceDiff = wETHBalanceAfter - wETHBalanceBefore;
        if(rewardFee > 0) {
            uint256 fee = balanceDiff * rewardFee / 10000;
            balanceDiff = balanceDiff - fee;
            totalRewardFee = totalRewardFee + fee;
        }
        IWETH(wETH).withdraw(balanceDiff);
        ISecretBridge(_secretBridge).swap{value: balanceDiff}(_recipient);
    }

    function adminInvest() external onlyOwner() {
        uint256 amountUSDC = exchangeUnderlying(curveUSTPool, secretUST + reversedUST, 0, 2);
        uint256 balanceLP = IERC20(curveLpToken).balanceOf(address(this));
        ICurvePool2(curveBUSDPool).add_liquidity([0, amountUSDC, 0, 0], 0); 
        uint256 balanceDiff = IERC20(curveLpToken).balanceOf(address(this)) - balanceLP;
        require(balanceDiff > 0, "Invalid-balance");
        _stake(convexDeposit, pidBUSD, balanceDiff);
        secretUST = 0;
        reversedUST = 0;
    }

    function _stake(address _pool, uint256 _pid, uint256 _stakeAmount) private {
        IConvexDeposit(_pool).depositAll(_pid, true);
        stakedBalance = stakedBalance + _stakeAmount;
    }

    function _withdraw(address _pool, uint256 _amount) private {
        IConvexWithdraw(_pool).withdrawAndUnwrap(_amount, false);
        stakedBalance = stakedBalance - _amount;
    }

    receive() external payable {
        
    }
}