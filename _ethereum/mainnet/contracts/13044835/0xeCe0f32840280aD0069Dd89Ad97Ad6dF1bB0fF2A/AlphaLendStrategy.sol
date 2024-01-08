// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./Strategy.sol";
import "./ISafeBox.sol";

/// @title This strategy will deposit collateral token in Alpha SafeBox (ibXYZv2) and earn interest.
abstract contract AlphaLendStrategy is Strategy {
    using SafeERC20 for IERC20;

    address internal constant ALPHA = 0xa1faa113cbE53436Df28FF0aEe54275c13B40975;
    ISafeBox internal safeBox;
    uint256 internal immutable ibDecimals;

    constructor(
        address _pool,
        address _swapManager,
        address _safeBox
    ) Strategy(_pool, _swapManager, _safeBox) {
        safeBox = ISafeBox(_safeBox);
        ibDecimals = safeBox.decimals();
        _setupCheck(_pool);
    }

    function _setupCheck(address _pool) internal view virtual {
        require(address(IVesperPool(_pool).token()) == address(safeBox.uToken()), "u-token-mismatch");
    }

    function _setupOracles() internal override {
        swapManager.createOrUpdateOracle(ALPHA, WETH, oraclePeriod, oracleRouterIdx);
        if (address(collateralToken) != WETH) {
            swapManager.createOrUpdateOracle(WETH, address(collateralToken), oraclePeriod, oracleRouterIdx);
        }
    }

    function claimUTokenReward(uint256 amount, bytes32[] memory proof) external virtual onlyKeeper {
        safeBox.claim(amount, proof);
        IVesperPool(pool).reportEarning(collateralToken.balanceOf(address(this)), 0, 0);
    }

    function updateTokenRate() external returns (uint256) {
        return safeBox.cToken().exchangeRateCurrent();
    }

    /**
     * @notice Calculate total value using ALPHA accrued and cToken
     * @dev Report total value in collateral token
     */
    function totalValue() external view virtual override returns (uint256 _totalValue) {
        _totalValue = _convertToCollateral(safeBox.balanceOf(address(this)));
    }

    function isReservedToken(address _token) public view virtual override returns (bool) {
        return _token == receiptToken || _token == ALPHA;
    }

    /// @notice Approve all required tokens
    function _approveToken(uint256 _amount) internal virtual override {
        collateralToken.safeApprove(pool, _amount);
        collateralToken.safeApprove(address(safeBox), _amount);
        for (uint256 i = 0; i < swapManager.N_DEX(); i++) {
            IERC20(ALPHA).safeApprove(address(swapManager.ROUTERS(i)), _amount);
        }
    }

    /// @notice Claim ALPHA and convert ALPHA into collateral token.
    function _claimRewardsAndConvertTo(address _toToken) internal override {
        uint256 _alphaAmount = IERC20(ALPHA).balanceOf(address(this));
        if (_alphaAmount != 0) {
            uint256 minAmtOut =
                (swapSlippage != 10000)
                    ? _calcAmtOutAfterSlippage(
                        _getOracleRate(_simpleOraclePath(ALPHA, _toToken), _alphaAmount),
                        swapSlippage
                    )
                    : 1;
            _safeSwap(ALPHA, _toToken, _alphaAmount, minAmtOut);
        }
    }

    function _generateReport()
        internal
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _payback
        )
    {
        uint256 _excessDebt = IVesperPool(pool).excessDebt(address(this));
        uint256 _totalDebt = IVesperPool(pool).totalDebtOf(address(this));
        _claimRewardsAndConvertTo(address(collateralToken));
        safeBox.withdraw(safeBox.balanceOf(address(this)));
        _afterDownstreamWithdrawal();
        uint256 _collateralBalance = collateralToken.balanceOf(address(this));
        if (_collateralBalance > _totalDebt) {
            _profit = _collateralBalance - _totalDebt;
        } else {
            _loss = _totalDebt - _collateralBalance;
        }
        _payback = (_excessDebt > _collateralBalance) ? _collateralBalance : _excessDebt;
    }

    /// @notice Deposit collateral in Alpha
    function _reinvest() internal virtual override {
        uint256 _collateralBalance = collateralToken.balanceOf(address(this));
        if (_collateralBalance != 0) {
            safeBox.deposit(_collateralBalance);
        }
    }

    /// @dev Withdraw collateral and transfer it to pool
    function _withdraw(uint256 _collateralAmount) internal override {
        uint256 _sbBalance = safeBox.balanceOf(address(this));
        uint256 toWithdraw =
            _collateralAmount < _convertToCollateral(_sbBalance) ? convertToIb(_collateralAmount) : _sbBalance;
        safeBox.withdraw(toWithdraw);
        _afterDownstreamWithdrawal();
        collateralToken.safeTransfer(pool, collateralToken.balanceOf(address(this)));
    }

    function _convertToCollateral(uint256 _ibAmount) internal view returns (uint256) {
        return ((_ibAmount * safeBox.cToken().exchangeRateStored()) / 1e18);
    }

    function convertToIb(uint256 _collateralAmount) internal view virtual returns (uint256) {
        return (_collateralAmount * 1e18) / safeBox.cToken().exchangeRateStored();
    }

    /* solhint-disable no-empty-blocks */
    function _afterDownstreamWithdrawal() internal virtual {}

    function _beforeMigration(address _newStrategy) internal virtual override {}

    function _liquidate(uint256 _excessDebt) internal override returns (uint256 _payback) {}

    function _realizeProfit(uint256 _totalDebt) internal override returns (uint256) {}

    function _realizeLoss(uint256 _totalDebt) internal override returns (uint256 _loss) {}
}
