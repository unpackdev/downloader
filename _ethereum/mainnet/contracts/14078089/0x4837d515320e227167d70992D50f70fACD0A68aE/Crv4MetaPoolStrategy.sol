// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IVesperPool.sol";
import "./Strategy.sol";
import "./CrvPoolStrategyBase.sol";

/// @title This strategy will deposit collateral token in Curve a 4Pool Metapool and earn interest.
abstract contract Crv4MetaPoolStrategy is CrvPoolStrategyBase {
    using SafeERC20 for IERC20;

    // No. of pooled tokens in the metapool
    uint256 private constant N = 4;
    // Curve Metapool Factory
    address private constant FACTORY = 0xB9fC157394Af804a3578134A6585C0dc9cc990d4;
    // Curve BASE-3CRV DepositZap Contract
    address internal DEPOSIT_ZAP = 0xA79828DF1850E8a3A3064576f380D90aECDD3359;

    constructor(
        address _pool,
        address _swapManager,
        address _metapool,
        address _gauge,
        uint256 _collateralIdx,
        string memory _name
    ) CrvPoolStrategyBase(_pool, _metapool, _metapool, _gauge, _swapManager, _collateralIdx, N, _name) {
        require(ILiquidityGaugeV2(_gauge).lp_token() == _metapool, "invalid-gauge");
    }

    function _init(
        address _crvPool,
        uint256 /* _n */
    ) internal virtual override {
        coins = IMetapoolFactory(FACTORY).get_underlying_coins(_crvPool);
        coinDecimals = IMetapoolFactory(FACTORY).get_underlying_decimals(_crvPool);
    }

    function _approveToken(uint256 _amount) internal virtual override {
        super._approveToken(_amount);
        collateralToken.safeApprove(DEPOSIT_ZAP, _amount);
        IERC20(crvLp).safeApprove(DEPOSIT_ZAP, _amount);
    }

    function _depositToCurve(uint256 _amt) internal virtual override returns (bool) {
        if (_amt != 0) {
            uint256[4] memory _depositAmounts;
            _depositAmounts[collIdx] = _amt;
            uint256 expectedOut =
                _calcAmtOutAfterSlippage(
                    IDepositZap4x(DEPOSIT_ZAP).calc_token_amount(crvLp, _depositAmounts, true),
                    crvSlippage
                );
            uint256 _minLpAmount =
                ((_amt * _getSafeUsdRate()) / crvPool.get_virtual_price()) * 10**(18 - coinDecimals[collIdx]);

            if (expectedOut > _minLpAmount) _minLpAmount = expectedOut;

            // solhint-disable-next-line no-empty-blocks
            try IDepositZap4x(DEPOSIT_ZAP).add_liquidity(crvLp, _depositAmounts, _minLpAmount) {} catch Error(
                string memory _reason
            ) {
                emit DepositFailed(_reason);
                return false;
            }
        }
        return true;
    }

    function _withdrawAsFromCrvPool(
        uint256 _lpAmount,
        uint256 _minAmt,
        uint256 _i
    ) internal virtual override {
        IDepositZap4x(DEPOSIT_ZAP).remove_liquidity_one_coin(crvLp, _lpAmount, SafeCast.toInt128(int256(_i)), _minAmt);
    }

    function getLpValueAs(uint256 _lpAmount, uint256 _i) public view virtual override returns (uint256) {
        return
            (_lpAmount != 0)
                ? IDepositZap4x(DEPOSIT_ZAP).calc_withdraw_one_coin(crvLp, _lpAmount, SafeCast.toInt128(int256(_i)))
                : 0;
    }

    function _claimRewards() internal virtual override {
        ITokenMinter(CRV_MINTER).mint(crvGauge);
        ILiquidityGaugeV2(crvGauge).claim_rewards(address(this));
    }
}
