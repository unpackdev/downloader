// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

import "./wstETHFarmLeverageLogic.sol";

abstract contract wstETHFarm is wstETHFarmLeverageLogic {

    /**
     * @dev External view function approximating the
     * new resulting net APY for a position setup.
     *
     * Note: Not 100% accurate because no syncPool is performed.
     */
    function getApproxNetAPY(
        uint256 _initialAmount,
        uint256 _leverage,
        uint256 _wstETHAPY
    )
        external
        view
        returns (
            uint256,
            bool
        )
    {
        return _getApproxNetAPY(
            _initialAmount,
            _leverage,
            _wstETHAPY
        );
    }

    /**
     * @dev External view function approximating the
     * new borrow amount for the pool when {_borrowAmount}
     * is borrowed.
     *
     * Note: Not 100% accurate because no syncPool is performed.
     */
    function getNewBorrowRate(
        uint256 _borrowAmount
    )
        external
        view
        returns (uint256)
    {
        return _getNewBorrowRate(
            _borrowAmount
        );
    }

    /**
     * @dev View functions returning the current
     * debt ratio of the postion with {_nftId}
     */
    function getLiveDebtRatio(
        uint256 _nftId
    )
        external
        view
        returns (uint256)
    {
        uint256 totalCollateral = getTotalWeightedCollateralETH(
            _nftId
        );

        if (totalCollateral == 0) {
            return 0;
        }

        return getPositionBorrowETH(_nftId)
            * PRECISION_FACTOR_E18
            / totalCollateral;
    }

    /**
     * @dev Liquidation function for open power farm
     * postions which have a debtratio greater 100 %.
     *
     * NOTE: The borrow token is defined by the power farm
     * and is wrapped ETH.
     * The receiving token is always wrapped staked ETH.
     */
    function liquidatePartiallyFromToken(
        uint256 _nftId,
        uint256 _nftIdLiquidator,
        uint256 _shareAmountToPay
    )
        external
        updatePools
        returns (
            uint256 paybackAmount,
            uint256 receivingAmount
        )
    {
        return _coreLiquidation(
            _nftId,
            _nftIdLiquidator,
            _shareAmountToPay
        );
    }

    /**
     * @dev Manually payback function for users. Takes
     * {_paybackShares} which can be converted
     * into token with {paybackAmount()} or vice verse
     * with {calculateBorrowShares()} from wise lending
     * contract.
     */
    function _manuallyPaybackShares(
        uint256 _nftId,
        uint256 _paybackShares
    )
        internal
    {
        uint256 paybackAmount = WISE_LENDING.paybackAmount(
            WETH_ADDRESS,
            _paybackShares
        );

        _safeTransferFrom(
            WETH_ADDRESS,
            msg.sender,
            address(this),
            paybackAmount
        );

        WISE_LENDING.paybackExactShares(
            _nftId,
            WETH_ADDRESS,
            _paybackShares
        );
    }

    /**
     * @dev Manually withdraw function for users. Takes
     * {_withdrawShares} which can be converted
     * into token with {cashoutAmount()} or vice verse
     * with {calculateLendingShares()} from wise lending
     * contract.
     */
    function _manuallyWithdrawShares(
        uint256 _nftId,
        uint256 _withdrawShares
    )
        internal
    {
        uint256 withdrawAmount = WISE_LENDING.cashoutAmount(
            WETH_ADDRESS,
            _withdrawShares
        );

        if (_checkBorrowLimit(_nftId, withdrawAmount) == false) {
            revert ResultsInBadDebt();
        }

        withdrawAmount = WISE_LENDING.withdrawExactShares(
            _nftId,
            WST_ETH_ADDRESS,
            _withdrawShares
        );

        _safeTransfer(
            WST_ETH_ADDRESS,
            msg.sender,
            withdrawAmount
        );
    }

    /**
     * @dev Internal function combining the core
     * logic for {openPosition()}.
     */
    function _openPosition(
        bool _isAave,
        uint256 _nftId,
        uint256 _initialAmount,
        uint256 _leverage
    )
        internal
    {
        if (_leverage > MAX_LEVERAGE) {
            revert LeverageTooHigh();
        }

        uint256 leveragedAmount = getLeverageAmount(
            _initialAmount,
            _leverage
        );

        uint256 flashloanAmount = leveragedAmount
            - _initialAmount;

        if (_aboveMinDepositAmount(leveragedAmount) == false) {
            revert AmountTooSmall();
        }

        _executeBalancerFlashLoan(
            {
                _nftId: _nftId,
                _amount: flashloanAmount,
                _initialAmount: _initialAmount,
                _lendingShares: 0,
                _borrowShares: 0,
                _minAmountOut: 0,
                _ethBack: false,
                _isAave: _isAave
            }
        );
    }

    /**
     * @dev Internal function combining the core
     * logic for {closingPosition()}.
     *
     * Note: {_minOutAmount} passed through UI by querring
     * {get_dy()} from curve pool contract.
     */
    function _closingPosition(
        bool _isAave,
        uint256 _nftId,
        uint256 _minOutAmount,
        bool _ethBack
    )
        internal
    {
        uint256 borrowShares = _getPositionBorrowShares(
            _nftId
        );

        uint256 lendingShares = _getPositionLendingShares(
            _nftId
        );

        uint256 borrowAmount = _getPositionBorrowToken(
            _nftId
        );

        _executeBalancerFlashLoan(
            {
                _nftId: _nftId,
                _amount: borrowAmount,
                _initialAmount: 0,
                _lendingShares: lendingShares,
                _borrowShares: borrowShares,
                _minAmountOut: _minOutAmount,
                _ethBack: _ethBack,
                _isAave: _isAave
            }
        );
    }

    /**
     * @dev Makes a call to WISE_LENDING to
     * register {_nftId} for specific farm use.
     */
    function _registrationFarm(
        uint256 _nftId
    )
        internal
    {
        WISE_LENDING.setRegistrationIsolationPool(
            _nftId,
            true
        );

        emit RegistrationFarm(
            _nftId,
            block.timestamp
        );
    }
}

