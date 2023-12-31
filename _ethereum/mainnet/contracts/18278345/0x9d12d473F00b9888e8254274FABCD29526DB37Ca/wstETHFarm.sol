// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.21;

/**
 * @author Christoph Krpoun
 * @author René Hochmuth
 * @author Vitally Marinchenko
 */

import "./wstETHFarmLeverageLogic.sol";

/**
 * @dev The wstETH power farm is an automated leverage contract working as a
 * second layer for Wise lending. It needs to be registed inside the latter one
 * to have access to the pools. It uses BALANCER FLASHLOANS as well as CURVE POOLS and
 * the LIDO contracts for staked ETH and wrapped staked ETH.
 * The corresponding contract addresses can be found in {wstETHFarmDeclarations.sol}.
 *
 * It allows to open leverage positions with wrapped ETH in form of aave wrapped ETH.
 * For opening a position the user needs to have {_initalAmount} of ETH or WETH in the wallet.
 * A maximum of 15x leverage is possible. Once the user registers with its position NFT that
 * NFT is locked for ALL other interactions with wise lending as long as the positon is open!
 *
 * For more infos see {https://wisesoft.gitbook.io/wise/}
 */

contract wstETHFarm is wstETHFarmLeverageLogic {

    constructor(
        address _wiseLendingAddress,
        uint256 _collateralFactor
    )
        wstETHFarmDeclarations(
            _wiseLendingAddress,
            _collateralFactor
        )
    {}

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
        uint256 totalCollateral = getTotalWeightedCollateralUSD(
            _nftId
        );

        if (totalCollateral == 0) {
            return 0;
        }

        return getPositionBorrowUSD(_nftId)
            * PRECISION_FACTOR_E18
            / totalCollateral;
    }

    /**
     * @dev Liquidation function for open power farm
     * postions which have a debtratio greater 100 %.
     *
     * NOTE: The borrow token is defined by the power farm
     * and is always aave wrapped ETH.
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
            AAVE_WETH_ADDRESS,
            _paybackShares
        );

        _safeTransferFrom(
            AAVE_WETH_ADDRESS,
            msg.sender,
            address(this),
            paybackAmount
        );

        WISE_LENDING.paybackExactShares(
            _nftId,
            AAVE_WETH_ADDRESS,
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
            WST_ETH_ADDRESS,
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
                _ethBack: false
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
                _ethBack: _ethBack
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

