// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./ICurvePool.sol";
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
    address public constant ust = 0xa47c8bf37f92aBed4A126BDA807A7b7498661acD;
    address public constant usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant tango = 0x182F4c4C97cd1c24E1Df8FC4c053E5C47bf53Bef;
    address public constant crv = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address public constant convex = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    address public constant sefi = 0x773258b03c730F84aF10dFcB1BfAa7487558B8Ac;
    address public constant curvePool = 0xB0a0716841F2Fc03fbA72A891B8Bb13584F52F2d;
    address public constant curveLpToken = 0x94e131324b6054c0D789b190b2dAC504e4361b53;
    address public constant convexDeposit = 0xF403C135812408BFbE8713b5A23a04b3D48AAE31;
    address public constant convexWithDrawAndClaim = 0xd4Be1911F8a0df178d6e7fF5cE39919c273E2B7B;
    uint256 public constant pidUST = 21;
}

contract TangoFactory is ITangoFactory, Constant, Ownable { 
    using SafeERC20 for IERC20;
    struct UserInfo { 
        uint256 totalCurveLpStaked;
        mapping(address => uint256) totalTokenInvest;
    }
    uint256 private feeOut;
    uint256 private feeIn;
    address private feeCollector;
    address private secretSw;
    mapping (address => address) public userSW;
    mapping (address => bool) public isSw;
    mapping (address => UserInfo) public usersInfo;
    address[] public allSWs;

    modifier onlySW() {
        require(isSw[msg.sender],"Only-tango-smart-wallet");
        _;
    }
    /**
     * @dev allow admin set Secret Bridge's smart wallet address
     * @param _secretSw is TangoSmartWallet address of Secret Bridge
     */
    function setSCRTBrdgeSW(address _secretSw) external onlyOwner() {
        secretSw = _secretSw;
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
    
    function invest(address _token, uint256 _amount) external override {
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
        IERC20(_token).safeTransferFrom(msg.sender, address(this),_amount); // take UST from user wallet
        if(feeIn > 0) {
            uint feeAmount = _amount * feeIn / 10000;
            IERC20(_token).safeTransfer(feeCollector, feeAmount);
            _amount = _amount -feeAmount;
        }
        IERC20(_token).approve(curvePool, _amount);
        uint256 curveLpAmount = _curveAddLiquidity(curvePool, [_amount, 0, 0, 0]);
        IERC20(curveLpToken).safeTransfer(sw, curveLpAmount);
        ITangoSmartWallet(sw).stake(convexDeposit, pidUST);
        UserInfo storage userInfo = usersInfo[msg.sender];
        userInfo.totalCurveLpStaked =  userInfo.totalCurveLpStaked + curveLpAmount;
        userInfo.totalTokenInvest[_token] = userInfo.totalTokenInvest[_token] + _amount;
    }
     /**
     * @dev invest function, create tango smart wallet for user at 1st time invest
     * store the TSW in userSw and isSW set as true
     * swap DAI, USDT, USDC to UST, then charge fee if feeIn greater than 0
     * add amount UST to Curve pool (UST) then call TSW for staking to Convex
     * @param _param is [ust, dai, usdc, usdt]
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
        uint256 balanceUST = IERC20(ust).balanceOf(address(this));
        for(uint i = 0; i < _param.length; i++) {
            if(_param[i] > 0) {
                if(i == 3) {
                    IERC20(usdt).safeTransferFrom(msg.sender, address(this), _param[i]);
                    _uniswapSwapToken(uniRouter, usdt, ust, _param[i]);
                }
                if(i == 2) {
                     IERC20(usdc).safeTransferFrom(msg.sender, address(this), _param[i]);
                    _uniswapSwapToken(uniRouter, usdc, ust, _param[i]);
                }
                if( i == 1) {
                    IERC20(dai).safeTransferFrom(msg.sender, address(this), _param[i]);
                    _uniswapSwapToken(uniRouter, dai, ust, _param[i]);
                }
            }
        }
        IERC20(ust).safeTransferFrom(msg.sender, address(this), _param[0]); // take UST from user wallet
        balanceUST = IERC20(ust).balanceOf(address(this)) - balanceUST; // total deposit to Curve balance
        if(feeIn > 0) {
            uint feeAmount = balanceUST * feeIn / 10000;
            IERC20(ust).safeTransfer(feeCollector, feeAmount);
            balanceUST = balanceUST - feeAmount;
        }
        IERC20(ust).approve(curvePool, balanceUST);
        uint256 curveLpAmount = _curveAddLiquidity(curvePool, [balanceUST, 0, 0, 0]);
        IERC20(curveLpToken).safeTransfer(sw, curveLpAmount);
        ITangoSmartWallet(sw).stake(convexDeposit, pidUST);
        UserInfo storage userInfo = usersInfo[msg.sender];
        userInfo.totalCurveLpStaked =  userInfo.totalCurveLpStaked + curveLpAmount;
        userInfo.totalTokenInvest[ust] = userInfo.totalTokenInvest[ust] + balanceUST;
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


    function adminClaimRewardForSCRT(address _secretBridge, bytes memory _recipient) external override onlyOwner() { 
        uint256 wETHBalanceBefore = IERC20(wETH).balanceOf(address(this));
        (uint256 amountCRV, uint256 amountCVX) = ITangoSmartWallet(secretSw).claimReward(convexWithDrawAndClaim);
        _uniswapSwapToken(uniRouter, crv, wETH, amountCRV);
        _uniswapSwapToken(sushiRouter, convex, wETH, amountCVX);
        uint256 wETHBalanceAfter = IERC20(wETH).balanceOf(address(this));
        uint256 balanceDiff = wETHBalanceAfter - wETHBalanceBefore;
        IWETH(wETH).withdraw(balanceDiff);
        ISecretBridge(_secretBridge).swap{value: balanceDiff}(_recipient);
    }

    function withdraw(uint256 _amount) external override {
        address sw = userSW[msg.sender];
        require(sw != address(0), "User-dont-have-wallet");
        require(msg.sender == ITangoSmartWallet(sw).owner(), "Only-sw-owner");
        uint256 lpAmount = calculateLpAmount(curvePool ,_amount) * 105 / 100; // extra 5%
        ITangoSmartWallet(sw).withdraw(convexWithDrawAndClaim, lpAmount);
        IERC20(curveLpToken).approve(curvePool, lpAmount);
        uint256 balanceUST = _curveRemoveLiquidity(curvePool, lpAmount);
        require(balanceUST >= _amount,"Invalid-output-amount");
        IERC20(ust).safeTransfer(msg.sender, balanceUST);
    }

    function userClaimReward() external override { 
        address sw = userSW[msg.sender];
        require(sw != address(0), "User-dont-have-wallet");
        (uint256 amountCRV, uint256 amountCVX) = ITangoSmartWallet(secretSw).claimReward(convexWithDrawAndClaim);
        swapReward(amountCRV, amountCVX, ITangoSmartWallet(secretSw).owner());
    }
}