// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IStrategy.sol";
import "./ICurveFi.sol";
import "./IConvexBaseReward.sol";
import "./IConvexBooster.sol";
import "./IUniswapV2Router01.sol";

contract SethStrategy is Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public crvLpToken;
    address public crvPool;
    address public convexBooster;
    address public nativeVault;
    address public convexReward;
    uint256 public poolId;
    address public sushiRouter;
    address public constant crv = address(0xD533a949740bb3306d119CC777fa900bA034cd52);
    address public constant cvx = address(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);

    // Slippage tolerance accepted (10 = 0.1%)
    uint8 public SLIPPAGE_TOLERANCE = 10;

    event Withdraw(uint256 amount);
    event Deposit(uint256 amount);
    event Harvest(uint256 crvAmount, uint256 cvxAmount, uint256 lpAmount);

    mapping(address => uint256) public balance;

    modifier onlyNativeVault {
        require(msg.sender == nativeVault, "You are not allowed");
        _;
    }

    constructor(address _crvLpToken, address _curvePool, address _convexBooster, uint256 _poolId, address _convexRewards, address _sushiRouter) {
        crvLpToken = _crvLpToken;
        crvPool = _curvePool;
        convexBooster = _convexBooster;
        poolId = _poolId;
        convexReward = _convexRewards;
        sushiRouter = _sushiRouter;
    }

    receive() external payable {}

    function deposit() external payable onlyNativeVault returns (uint256){
        require(msg.value > 0, "Deposit positive amount");
        uint256 amountToDeposit = msg.value;

        uint256 lpAmount = _deposit(amountToDeposit);
        return lpAmount;
    }

    function _withdraw(uint256 lpAmount) internal returns (uint256) {
        require(lpAmount > 0, "Withdraw positive amount please");

        //get crv lp back from Convex by withdrawAndUnwraping
        IConvexBaseReward(convexReward).withdrawAndUnwrap(lpAmount, false);
        uint256 amountEthOut = removeCurveLiquidity(lpAmount);

        (bool success,) = payable(msg.sender).call{value : amountEthOut}("");
        require(success, "Transfer failed.");

        emit Withdraw(amountEthOut);
        return amountEthOut;
    }

    // @dev slippage tolerance 1% :  slippageTolerancePerMille = 10
    function withdraw(uint256 lpAmount) external onlyNativeVault returns (uint256) {
        return _withdraw(lpAmount);
    }

    function withdrawAll() external onlyNativeVault returns (uint256) {
        uint256 lpAmount = IConvexBaseReward(convexReward).balanceOf(address(this));
        return _withdraw(lpAmount);
    }

    function harvest(bool _compoundRewards) external {
        require(IConvexBaseReward(convexReward).getReward(), "Convex claim failed");

        uint256 lpAmount = 0;
        uint256 crvBal = IERC20(crv).balanceOf(address(this));
        uint256 cvxBal = IERC20(cvx).balanceOf(address(this));

        if (crvBal > 0) {
            swapRewardForEth(crv, crvBal);
        }

        if (cvxBal > 0) {
            swapRewardForEth(cvx, cvxBal);
        }

        if (address(this).balance > 0) {
            if (_compoundRewards) {
                lpAmount = _deposit(address(this).balance);
            }
            else {
                (bool success,) = payable(nativeVault).call{value : address(this).balance}("");
                require(success, "Transfer failed.");
            }
        }

        emit Harvest(crvBal, cvxBal, lpAmount);
    }

    function _deposit(uint256 _amountToDeposit) internal returns (uint256) {
        uint256 lpAmount = getCurveLp(_amountToDeposit);

        depositInConvex(lpAmount);

        emit Deposit(msg.value);
        return lpAmount;
    }

    function removeCurveLiquidity(uint256 _amount) internal returns (uint256) {
        //eth is index 0
        uint256 minEthAmount = ICurveFi(crvPool).calc_withdraw_one_coin(_amount, 0);

        //slippage tolerance on our side
        uint256 minEthAmountWithSlippage = minEthAmount.mul(1000 - SLIPPAGE_TOLERANCE).div(1000);
        return ICurveFi(crvPool).remove_liquidity_one_coin(_amount, 0, minEthAmountWithSlippage);
    }

    function swapRewardForEth(address _tokenReward, uint256 _amount) internal {
        require(IERC20(_tokenReward).approve(sushiRouter, _amount), "approved failed");

        address[] memory path = new address[](2);
        path[0] = _tokenReward;
        path[1] = IUniswapV2Router01(sushiRouter).WETH();

        IUniswapV2Router01(sushiRouter).swapExactTokensForETH(_amount, 0, path, address(this), block.timestamp + 10);
    }

    function getCurveLp(uint256 _amountToDeposit) internal returns (uint256){
        //Slippage taken into account in calc_token_amount but not fees. Cannot do better
        uint256 minLpMint = ICurveFi(crvPool).calc_token_amount([_amountToDeposit, 0], true);

        //slippage tolerance on our side
        uint256 mintLpWithSlippage = minLpMint.mul(1000 - SLIPPAGE_TOLERANCE).div(1000);
        return ICurveFi(crvPool).add_liquidity{value : _amountToDeposit}([_amountToDeposit, 0], mintLpWithSlippage);
    }

    function depositInConvex(uint256 _lpAmount) internal {
        IERC20(crvLpToken).approve(convexBooster, _lpAmount);
        require(IConvexBooster(convexBooster).depositAll(poolId, true), 'Convex deposit failed');
    }

    function setPoolId(uint256 _poolId) external {
        poolId = _poolId;
    }

    function setNativeVault(address _nativeVault) external onlyOwner {
        nativeVault = _nativeVault;
    }

    function setSlippageTolerance(uint8 _newSlippageTolerance) external onlyOwner {
        SLIPPAGE_TOLERANCE = _newSlippageTolerance;
    }

    function getVirtualBalance() external returns (uint256) {
        uint256 cvxLpBal = IConvexBaseReward(convexReward).balanceOf(address(this));
        uint256 lpVirtualPrice = ICurveFi(crvPool).get_virtual_price();

        uint256 virtualBal = cvxLpBal * lpVirtualPrice / 1e18;
        return virtualBal;
    }

    // @dev https://news.curve.fi/chainlink-oracles-and-curve-pools/
    function getConvexLpBalance() external view returns (uint256) {
        return IConvexBaseReward(convexReward).balanceOf(address(this));
    }
}
