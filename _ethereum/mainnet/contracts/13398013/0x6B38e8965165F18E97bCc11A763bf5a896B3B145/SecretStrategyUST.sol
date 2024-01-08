// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./IConvexDeposit.sol";
import "./IConvexWithdraw.sol";
import "./ICurvePool.sol";
import "./IUniswapV2Router02.sol";
import "./ITangoFactory.sol";
import "./IWETH.sol";
import "./ISecretBridge.sol";

contract Constant { 
    address public constant uniRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant sushiRouter = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    address public constant wETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 public constant deadline =
        0xf000000000000000000000000000000000000000000000000000000000000000;
    address public constant ust = 0xa47c8bf37f92aBed4A126BDA807A7b7498661acD;
    address public constant usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant tango = 0x182F4c4C97cd1c24E1Df8FC4c053E5C47bf53Bef;
    address public constant crv = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address public constant cvx = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    address public constant sefi = 0x773258b03c730F84aF10dFcB1BfAa7487558B8Ac;
    address public constant curvePool = 0xB0a0716841F2Fc03fbA72A891B8Bb13584F52F2d;
    address public constant curveLpToken = 0x94e131324b6054c0D789b190b2dAC504e4361b53;
    address public constant convexDeposit = 0xF403C135812408BFbE8713b5A23a04b3D48AAE31;
    address public constant convexWithDrawAndClaim = 0xd4Be1911F8a0df178d6e7fF5cE39919c273E2B7B;
    uint256 public constant pidUST = 21;
}

contract SecretStrategyUST is ITangoFactory, Constant, Ownable { 
    using SafeERC20 for IERC20;

    uint256 public secretUST;
    uint256 public reserveUST;
    uint256 public minReserve;
    uint256 public stakedBalance;
    uint256 public depositFee;
    uint256 public rewardFee;
    uint256 public totalDepositFee;
    uint256 public totalRewardFee;
    uint256 public totalUSTDeposited;
    address public router;
    bytes   public receiver;

    mapping(address => bool) isOperator;
    modifier onlyRouter() {
        require(msg.sender == router,"Only-router");
        _;
    }

    modifier onlyOperator() { 
        require(isOperator[msg.sender], "Only-operator");
        _;
    }
    event Invest(address _user, uint256 _amount);
    event Withdraw(address _user, uint256 _amount);
    event Balance(uint256 _secretUST, uint256 _reserveUST);
    constructor(address _router, uint256 _minReserve) Ownable() {
        router = _router;
        minReserve = _minReserve;
        IERC20(curveLpToken).safeApprove(curvePool, type(uint256).max);
        IERC20(curveLpToken).safeApprove(convexDeposit, type(uint256).max);
        IERC20(usdc).safeApprove(curvePool, type(uint256).max);
        IERC20(dai).safeApprove(curvePool, type(uint256).max);
        IERC20(ust).safeApprove(curvePool, type(uint256).max);
        isOperator[0xfc0962770A2A1d142f7b48cb40d04001c73Af840] = true;
        transferOwnership(0xfc0962770A2A1d142f7b48cb40d04001c73Af840);
    }

    function adminSetFee(uint256 _depositFee, uint256 _rewardFee) external onlyOwner() {
        depositFee = _depositFee;
        rewardFee = _rewardFee;
    }

    function adminSetMinReversed(uint256 _minReserve) external onlyOwner() {
        minReserve = _minReserve;
    }

    function adminSetRewardRecipient(bytes memory _receiver) external onlyOwner() {
        receiver = _receiver;
    }

    function adminWhiteListOperator(address _operator, bool _whitelist) external onlyOwner() {
        isOperator[_operator] = _whitelist;
    }

    function adminCollectFee(address _to) external onlyOwner() {
        IERC20(ust).safeTransfer(_to, totalDepositFee);
        IERC20(wETH).safeTransfer(_to, totalRewardFee);
        totalDepositFee = 0;
        totalRewardFee = 0;
    }

    function adminFillReserve(uint256 _amount) external onlyOwner() {
        IERC20(ust).safeTransferFrom(msg.sender, address(this), _amount);
        reserveUST = _amount;
    }

    function adminWithdrawToken(address _token, address _to, uint256 _amount) external onlyOwner() {
        if(_token == address(0)) {
            (bool success, ) = _to.call{value: address(this).balance}("");
            require(success);
            return;
        }
        IERC20(_token).safeTransfer(_to, _amount);
    }


    function adminUnstakeAndWithdraw(address _to, uint256 _amount) external onlyOwner() { 
        uint256 withdrawBalance = withrawFromPool(_amount);
        IERC20(ust).safeTransfer(_to, withdrawBalance);
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
     * @return amount of lp token
     */
    function _curveRemoveLiquidity(address _curvePool, uint256 _curveLpBalance) private returns(uint256) { 
        return ICurvePool(_curvePool).remove_liquidity_one_coin(_curveLpBalance, 0, 0);
    }

    function calculateLpAmount(address _curvePool, uint256 _ustAmount) private returns (uint256){
        return ICurvePool(_curvePool).calc_token_amount([_ustAmount, 0, 0, 0], false);
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


    function withrawFromPool(uint256 _amount) private returns(uint256) { 
        uint256 lpAmount = calculateLpAmount(curvePool ,_amount) * 101 / 100; // extra 1%
        _withdraw(convexWithDrawAndClaim, lpAmount);
        uint256 balanceUST = _curveRemoveLiquidity(curvePool, lpAmount);
        return balanceUST;
    }

    function operatorClaimRewards() external onlyOperator() {
        IConvexWithdraw(convexWithDrawAndClaim).getReward();
    }

    function operatorRebalanceReserve() external onlyOperator() { 
        require(reserveUST < minReserve, "No-need-rebalance-now");
        uint256 _amount = minReserve - reserveUST;
        reserveUST = reserveUST + withrawFromPool(_amount);
        require(IERC20(ust).balanceOf(address(this)) >= reserveUST, "Something-went-wrong");
    }

    function secretWithdraw(address _user, uint256 _amount) external override onlyRouter() {
        emit Withdraw(_user, _amount);
        if (secretUST >= _amount) {
            IERC20(ust).safeTransfer(_user, _amount);
            secretUST = secretUST - _amount;
            emit Balance(secretUST, reserveUST);
            return;
        }
        else if(secretUST + reserveUST >= _amount) { 
            reserveUST = reserveUST + secretUST - _amount;
            secretUST = 0;
            IERC20(ust).safeTransfer(_user, _amount);
            emit Balance(secretUST, reserveUST);
            return;
        }
        else {
            uint256 buffer = (minReserve > reserveUST) ? minReserve - reserveUST : 0;
            uint256 balanceUST = withrawFromPool(_amount + buffer); // withdraw extra and fill reserver
            IERC20(ust).safeTransfer(_user, _amount);
            reserveUST = reserveUST + balanceUST - _amount;
        }
    }

    function operatorClaimRewardsToSCRT(address _secretBridge) external override onlyOperator() { 
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
        ISecretBridge(_secretBridge).swap{value: balanceDiff}(receiver);
    }

    function operatorInvest() external onlyOperator() {
        uint256 curveLpAmount = _curveAddLiquidity(curvePool, [secretUST, 0, 0, 0]);
        _stake(convexDeposit, pidUST, curveLpAmount);
        secretUST = 0;
    }

    function _stake(address _pool, uint256 _pid, uint256 _stakeAmount) private {
        IConvexDeposit(_pool).depositAll(_pid, true);
        stakedBalance = stakedBalance + _stakeAmount;
    }

    function _withdraw(address _pool, uint256 _amount) private {
        IConvexWithdraw(_pool).withdrawAndUnwrap(_amount, false);
        stakedBalance = stakedBalance - _amount;
    }

    function getStakingInfor() public view returns(uint256, uint256) { 
        uint256 currentStakedBalance = IConvexWithdraw(convexWithDrawAndClaim).balanceOf(address(this));
        uint256 rewardBalance = IConvexWithdraw(convexWithDrawAndClaim).earned(address(this));
        return (currentStakedBalance, rewardBalance);
    }

    receive() external payable {
        
    }
}