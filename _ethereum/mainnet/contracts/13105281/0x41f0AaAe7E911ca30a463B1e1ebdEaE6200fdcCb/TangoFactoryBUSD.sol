// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./ICurvePool.sol";
import "./ICurvePool2.sol";
import "./TangoSmartWallet.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./ITangoSmartWallet.sol";
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
    address public constant busd = 0x4Fabb145d64652a948d72533023f6E7A623C7C53;
    address public constant ust = 0xa47c8bf37f92aBed4A126BDA807A7b7498661acD;
    address public constant usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant tango = 0x182F4c4C97cd1c24E1Df8FC4c053E5C47bf53Bef;
    address public constant crv = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address public constant convex = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    address public constant curvePool = 0xb6c057591E073249F2D9D88Ba59a46CFC9B59EdB;
    address public constant curveUSTPool = 0x890f4e345B1dAED0367A877a1612f86A1f86985f;
    address public constant curveLpToken = 0x3B3Ac5386837Dc563660FB6a0937DFAa5924333B;
    address public constant curveExchangeBUSD = 0x79a8C46DeA5aDa233ABaFFD40F3A0A2B1e5A4F27;
    address public constant convexDeposit = 0xF403C135812408BFbE8713b5A23a04b3D48AAE31;
    address public constant convexWithDrawAndClaim = 0x602c4cD53a715D8a7cf648540FAb0d3a2d546560;
    uint256 public constant pidBUSD = 3;
}

contract TangoFactoryBUSD is ITangoFactory, Constant, Ownable { 
    using SafeERC20 for IERC20;
    struct UserInfo { 
        uint256 totalCurveLpStaked;
        mapping(address => uint256) totalTokenInvest;
    }

    uint256 public feeOut;
    uint256 public feeIn;
    address public feeCollector;
    address public router;
    mapping (address => address) public userSW;
    mapping (address => bool) public isSw;
    mapping (address => UserInfo) public usersInfo;
    address[] public allSWs;

    modifier onlyRouter() {
        require(msg.sender == router,"Only-router");
        _;
    }
    constructor(address _router) {
        router = _router;
        IERC20(curveLpToken).safeApprove(curvePool, type(uint256).max);
        IERC20(usdc).safeApprove(curveUSTPool, type(uint256).max);
        IERC20(dai).safeApprove(curveUSTPool, type(uint256).max);
        IERC20(usdt).safeApprove(curveUSTPool, type(uint256).max);
        IERC20(ust).safeApprove(curveUSTPool, type(uint256).max);

        IERC20(usdc).safeApprove(curvePool, type(uint256).max);
        IERC20(dai).safeApprove(curvePool, type(uint256).max);
        IERC20(usdt).safeApprove(curvePool, type(uint256).max);
        IERC20(busd).safeApprove(curvePool, type(uint256).max);
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
        address sw = userSW[_user];
        if(sw == address(0)) {
            bytes memory bytecode = type(TangoSmartWallet).creationCode;
            bytes32 salt = keccak256(abi.encodePacked(address(this), _user));
            assembly {
                sw := create2(0, add(bytecode, 32), mload(bytecode), salt)
            }
            TangoSmartWallet(sw).initialize(_user, curveLpToken, convexDeposit);
            userSW[_user] = sw;
            isSw[sw] = true;
            allSWs.push(sw);
        }
        if(feeIn > 0) {
            uint feeAmount = _amount * feeIn / 10000;
            IERC20(_token).safeTransfer(feeCollector, feeAmount);
            _amount = _amount - feeAmount;
        }
        uint256 amountUSDC = exchangeUnderlying(curveUSTPool, _amount, 0, 2);
        uint256 balanceLP = IERC20(curveLpToken).balanceOf(address(this));
        ICurvePool2(curvePool).add_liquidity([0, amountUSDC, 0, 0], 0); 
        uint256 balanceDiff = IERC20(curveLpToken).balanceOf(address(this)) - balanceLP;
        IERC20(curveLpToken).safeTransfer(sw, balanceDiff);
        ITangoSmartWallet(sw).stake(convexDeposit, pidBUSD);
        UserInfo storage userInfo = usersInfo[_user];
        userInfo.totalCurveLpStaked =  userInfo.totalCurveLpStaked + balanceDiff;
        userInfo.totalTokenInvest[_token] = userInfo.totalTokenInvest[_token] + _amount;
    }

     /**
     * @dev invest function, create tango smart wallet for user at 1st time invest
     * store the TSW in userSw and isSW set as true
     * swap DAI, USDT, USDC to UST, then charge fee if feeIn greater than 0
     * add amount UST to Curve pool (UST) then call TSW for staking to Convex
     * @param _param is [busd, dai, usdc, usdt]
     */
    function invest4(uint256[4] memory _param) external override { 
        address sw = userSW[msg.sender];
        if(sw == address(0)) {
            bytes memory bytecode = type(TangoSmartWallet).creationCode;
            bytes32 salt = keccak256(abi.encodePacked(address(this), msg.sender));
            assembly {
                sw := create2(0, add(bytecode, 32), mload(bytecode), salt)
            }
            TangoSmartWallet(sw).initialize(msg.sender, curveLpToken, convexDeposit);
            userSW[msg.sender] = sw;
            isSw[sw] = true;
            allSWs.push(sw);
        }
        uint256 balanceDAI = IERC20(dai).balanceOf(address(this));
        for(uint i = 0; i < _param.length; i++) {
            if(_param[i] > 0) {
                if(i == 3) {
                    IERC20(busd).safeTransferFrom(msg.sender, address(this), _param[i]);
                    exchangeUnderlying(curvePool, _param[i], 3, 0);
                }
                if(i == 2) {
                     IERC20(usdt).safeTransferFrom(msg.sender, address(this), _param[i]);
                    exchangeUnderlying(curvePool, _param[i], 2, 0);
                }
                if( i == 1) {
                    IERC20(usdc).safeTransferFrom(msg.sender, address(this), _param[i]);
                    exchangeUnderlying(curvePool, _param[i], 1, 0);
                }
            }
        }
        IERC20(dai).safeTransferFrom(msg.sender, address(this), _param[0]); // take DAI from user wallet
        balanceDAI = IERC20(dai).balanceOf(address(this)) - balanceDAI; // total deposit to Curve balance
        if(feeIn > 0) {
            uint feeAmount = balanceDAI * feeIn / 10000;
            IERC20(ust).safeTransfer(feeCollector, feeAmount);
            balanceDAI = balanceDAI - feeAmount;
        }
        uint256 balanceLP = IERC20(curveLpToken).balanceOf(address(this));
        ICurvePool2(curvePool).add_liquidity([balanceDAI, 0, 0, 0], 0); 
        uint256 balanceDiff = IERC20(curveLpToken).balanceOf(address(this)) - balanceLP;
        IERC20(curveLpToken).safeTransfer(sw, balanceDiff);
        ITangoSmartWallet(sw).stake(convexDeposit, pidBUSD);
        UserInfo storage userInfo = usersInfo[msg.sender];
        userInfo.totalCurveLpStaked =  userInfo.totalCurveLpStaked + balanceDiff;
        userInfo.totalTokenInvest[dai] = userInfo.totalTokenInvest[dai] + balanceDAI;
    }

    function withdraw(uint256 _amount, bool isClaimReward) external override {
        address sw = userSW[msg.sender];
        require(sw != address(0), "User-dont-have-wallet");
        require(msg.sender == ITangoSmartWallet(sw).owner(), "Only-sw-owner");
        uint256 lpAmount = calculateLpAmount(curveExchangeBUSD ,_amount) * 102 / 100; // extra 2%
        ITangoSmartWallet(sw).withdraw(convexWithDrawAndClaim, lpAmount);
        uint256 balanceUSDC = IERC20(usdc).balanceOf(address(this));
        ICurvePool2(curvePool).remove_liquidity_one_coin(lpAmount, 1, 0);
        uint256 withdrawBalance = IERC20(usdc).balanceOf(address(this)) - balanceUSDC;
        IERC20(usdc).safeTransfer(msg.sender, withdrawBalance);
        if(isClaimReward) {
            userClaimReward();
        }
    }

    function secretWithdraw(address _user, uint256 _amount) external override onlyRouter() {
        address sw = userSW[_user];
        // expect that _amount is UST amunt, equal to 
        uint256 lpAmount = calculateLpAmount(curveExchangeBUSD ,_amount) * 102 / 100; // extra 2%
        ITangoSmartWallet(sw).withdraw(convexWithDrawAndClaim, lpAmount);
        uint256 balanceUSDC = IERC20(usdc).balanceOf(address(this));
        ICurvePool2(curvePool).remove_liquidity_one_coin(lpAmount, 1, 0);
        uint256 swapBalance = IERC20(usdc).balanceOf(address(this)) - balanceUSDC;
        uint256 balanceUST = exchangeUnderlying(curveUSTPool, swapBalance, 2, 0);
        IERC20(ust).safeTransfer(_user, balanceUST);
    }


     /**
     * @dev swap reward received from convex staking program to SEFI or TANGO
     * @param _amountCrv is amount Curve token received from Convex Pool
     * @param _amountCVX is amount Convex token received from Convex Pool
     * @param _owner is address of smart wallet owner that receive reward
     */
    function swapReward(uint256 _amountCrv, uint256 _amountCVX, address _owner) private { 
        uint256 wETHBalanceBefore = IERC20(wETH).balanceOf(address(this));
        _uniswapSwapToken(uniRouter, crv, wETH, _amountCrv);
        _uniswapSwapToken(sushiRouter, convex, wETH, _amountCVX);
        uint256 tangoBalanceBefore = IERC20(tango).balanceOf(address(this));
        uint256 wETHBalanceAfter = IERC20(wETH).balanceOf(address(this));
        _uniswapSwapToken(uniRouter, wETH, tango, wETHBalanceAfter - wETHBalanceBefore);
        uint256 tangoBalanceAfter = IERC20(tango).balanceOf(address(this));
        uint256 rewardAmount = tangoBalanceAfter - tangoBalanceBefore;
        if(feeOut > 0) {
            uint feeAmout = rewardAmount * feeOut / 10000;
            IERC20(tango).safeTransfer(feeCollector, feeAmout);
            rewardAmount = rewardAmount - feeAmout;
        }
        IERC20(tango).safeTransfer(_owner, rewardAmount);
    }


    function adminClaimRewardForSCRT(address _secretBridge, address _secretSW, bytes memory _recipient) external override onlyOwner() { 
        uint256 wETHBalanceBefore = IERC20(wETH).balanceOf(address(this));
        (uint256 amountCRV, uint256 amountCVX) = ITangoSmartWallet(_secretSW).claimReward(convexWithDrawAndClaim);
        _uniswapSwapToken(uniRouter, crv, wETH, amountCRV);
        _uniswapSwapToken(sushiRouter, convex, wETH, amountCVX);
        uint256 wETHBalanceAfter = IERC20(wETH).balanceOf(address(this));
        uint256 balanceDiff = wETHBalanceAfter - wETHBalanceBefore;
        IWETH(wETH).withdraw(balanceDiff);
        ISecretBridge(_secretBridge).swap{value: balanceDiff}(_recipient);
    }


    function userClaimReward() public override { 
        address sw = userSW[msg.sender];
        require(sw != address(0) && ITangoSmartWallet(sw).owner() == msg.sender, "Forbiden");
        (uint256 amountCRV, uint256 amountCVX) = ITangoSmartWallet(sw).claimReward(convexWithDrawAndClaim);
        swapReward(amountCRV, amountCVX, msg.sender);
    }

    receive() external payable {
        
    }

    function getStakedAmount(address _user) external returns (uint256, uint256) { 
         address sw = userSW[_user];
         require(sw != address(0), "Invalid-user"); 
         uint256 stakedBalance = ITangoSmartWallet(sw).stakedBalance();
         uint256 ustAmount = calculateLpAmount(curvePool ,stakedBalance);
         return (stakedBalance, ustAmount);
    }
}