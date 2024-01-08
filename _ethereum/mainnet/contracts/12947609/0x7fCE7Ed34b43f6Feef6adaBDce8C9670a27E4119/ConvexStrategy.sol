// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./IConvex.sol";
import "./Crv3PoolStrategyBase.sol";

/// @title This strategy will deposit collateral token in Curve 3Pool and stake lp token to convex.
abstract contract ConvexStrategy is Crv3PoolStrategyBase {
    using SafeERC20 for IERC20;

    address public constant CVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    address public constant BOOSTER = 0xF403C135812408BFbE8713b5A23a04b3D48AAE31;
    address public immutable cvxCrvRewards;
    uint256 public immutable convexPoolId;
    bool public isClaimRewards;
    bool public isClaimExtras;

    constructor(
        address _pool,
        address _threePool,
        address _threeCrv,
        address _gauge,
        address _swapManager,
        uint256 _collateralIdx,
        uint256 _convexPoolId
    ) Crv3PoolStrategyBase(_pool, _threePool, _threeCrv, _gauge, _swapManager, _collateralIdx) {
        (address _lp, , , address _reward, , ) = IConvex(BOOSTER).poolInfo(_convexPoolId);
        require(_lp == address(_threeCrv), "incorrect-lp-token");
        cvxCrvRewards = _reward;
        convexPoolId = _convexPoolId;
        reservedToken[CVX] = true;
        oracleRouterIdx = 1; // Default dex is sushswap
    }

    function updateClaimRewards(bool _isClaimRewards) external onlyGovernor {
        isClaimRewards = _isClaimRewards;
    }

    function updateClaimExtras(bool _isClaimExtras) external onlyGovernor {
        isClaimExtras = _isClaimExtras;
    }

    function _approveToken(uint256 _amount) internal virtual override {
        IERC20(crvLp).safeApprove(BOOSTER, _amount);
        for (uint256 i = 0; i < swapManager.N_DEX(); i++) {
            IERC20(CVX).safeApprove(address(swapManager.ROUTERS(i)), _amount);
        }
        super._approveToken(_amount);
    }

    function _setupOracles() internal override {
        swapManager.createOrUpdateOracle(CVX, WETH, oraclePeriod, oracleRouterIdx);
        super._setupOracles();
    }

    function _stakeAllLp() internal override {
        uint256 balance = IERC20(crvLp).balanceOf(address(this));
        if (balance != 0) {
            IConvex(BOOSTER).deposit(convexPoolId, balance, true);
        }
    }

    function _unstakeAllLp() internal override {
        Rewards(cvxCrvRewards).withdrawAllAndUnwrap(isClaimRewards);
    }

    function _unstakeLp(uint256 _amount) internal override {
        if (_amount != 0) {
            Rewards(cvxCrvRewards).withdrawAndUnwrap(_amount, false);
        }
    }

    function _claimRewardsAndConvertTo(address _toToken) internal virtual override {
        Rewards(cvxCrvRewards).getReward(address(this), isClaimExtras);
        uint256 amt = IERC20(CRV).balanceOf(address(this));
        if (amt != 0) {
            uint256 minAmtOut;
            if (swapSlippage < 10000) {
                (uint256 minWethOut, bool isValid) = _consultOracle(CRV, WETH, amt);
                (uint256 _minAmtOut, bool isValidTwo) = _consultOracle(WETH, _toToken, minWethOut);
                require(isValid, "stale-crv-oracle");
                require(isValidTwo, "stale-collateral-oracle");
                minAmtOut = _calcAmtOutAfterSlippage(_minAmtOut, swapSlippage);
            }
            _safeSwap(CRV, _toToken, amt, minAmtOut);
        }

        amt = IERC20(CVX).balanceOf(address(this));
        if (amt != 0) {
            uint256 minAmtOut;
            if (swapSlippage < 10000) {
                (uint256 minWethOut, bool isValid) = _consultOracle(CVX, WETH, amt);
                (uint256 _minAmtOut, bool isValidTwo) = _consultOracle(WETH, _toToken, minWethOut);
                require(isValid, "stale-crv-oracle");
                require(isValidTwo, "stale-collateral-oracle");
                minAmtOut = _calcAmtOutAfterSlippage(_minAmtOut, swapSlippage);
            }
            _safeSwap(CVX, _toToken, amt, minAmtOut);
        }
    }

    function totalStaked() public view override returns (uint256 total) {
        total = Rewards(cvxCrvRewards).balanceOf(address(this));
    }

    function totalLp() public view override returns (uint256 total) {
        total = IERC20(crvLp).balanceOf(address(this)) + Rewards(cvxCrvRewards).balanceOf(address(this));
    }
}
