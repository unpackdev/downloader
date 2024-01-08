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

    function _setupOracles() internal virtual override {
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
    function totalValue() public view virtual override returns (uint256 _totalValue) {
        uint256 _alphaAmount = IERC20(ALPHA).balanceOf(address(this));
        if (_alphaAmount != 0) {
            (, _totalValue, ) = swapManager.bestOutputFixedInput(ALPHA, address(collateralToken), _alphaAmount);
        }
        _totalValue += _convertToCollateral(safeBox.balanceOf(address(this)));
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
    function _claimRewardsAndConvertTo(address _toToken) internal virtual override {
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

    /// @notice Deposit collateral in Alpha
    function _reinvest() internal virtual override {
        uint256 _collateralBalance = collateralToken.balanceOf(address(this));
        if (_collateralBalance != 0) {
            safeBox.deposit(_collateralBalance);
        }
    }

    /// @dev Withdraw collateral and transfer it to pool
    function _withdraw(uint256 _collateralAmount) internal override {
        _withdrawHere(_collateralAmount);
        collateralToken.safeTransfer(pool, collateralToken.balanceOf(address(this)));
    }

    function _convertToCollateral(uint256 _ibAmount) internal view returns (uint256) {
        return ((_ibAmount * safeBox.cToken().exchangeRateStored()) / 1e18);
    }

    function _convertToIb(uint256 _collateralAmount) internal view virtual returns (uint256) {
        return (_collateralAmount * 1e18) / safeBox.cToken().exchangeRateStored();
    }

    function _withdrawHere(uint256 _collateralAmount) internal returns (uint256) {
        uint256 _collateralBalanceBefore = collateralToken.balanceOf(address(this));
        uint256 _sbBalance = safeBox.balanceOf(address(this));
        uint256 _toWithdraw = _convertToIb(_collateralAmount);
        // Make sure to withdraw requested amount
        if (_collateralAmount > _convertToCollateral(_toWithdraw)) {
            _toWithdraw += 1;
        }
        if (_toWithdraw > _sbBalance) {
            _toWithdraw = _sbBalance;
        }
        safeBox.withdraw(_toWithdraw);
        _afterDownstreamWithdrawal();
        return collateralToken.balanceOf(address(this)) - _collateralBalanceBefore;
    }

    function _liquidate(uint256 _excessDebt) internal override returns (uint256 _payback) {
        if (_excessDebt != 0) {
            _payback = _withdrawHere(_excessDebt);
        }
    }

    function _realizeProfit(uint256 _totalDebt) internal virtual override returns (uint256) {
        _claimRewardsAndConvertTo(address(collateralToken));
        uint256 _collateralBalance = _convertToCollateral(safeBox.balanceOf(address(this)));
        if (_collateralBalance > _totalDebt) {
            _withdrawHere(_collateralBalance - _totalDebt);
        }
        return collateralToken.balanceOf(address(this));
    }

    function _realizeLoss(uint256 _totalDebt) internal view override returns (uint256 _loss) {
        uint256 _collateralBalance = _convertToCollateral(safeBox.balanceOf(address(this)));
        if (_collateralBalance < _totalDebt) {
            _loss = _totalDebt - _collateralBalance;
        }
    }

    /* solhint-disable no-empty-blocks */
    function _afterDownstreamWithdrawal() internal virtual {}

    function _beforeMigration(address _newStrategy) internal virtual override {}
}
