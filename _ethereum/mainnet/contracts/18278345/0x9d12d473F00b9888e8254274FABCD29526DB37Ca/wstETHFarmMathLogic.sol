// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.21;

import "./wstETHFarmDeclarations.sol";

abstract contract wstETHFarmMathLogic is wstETHFarmDeclarations {

    /**
     * @dev Wrapper for wrapping
     * ETH call.
     */
    function _wrapETH(
        uint256 _value
    )
        internal
    {
        WETH.deposit{
            value: _value
        }();
    }

    /**
     * @dev Wrapper for unwrapping
     * ETH call.
     */
    function _unwrapETH(
        uint256 _value
    )
        internal
    {
        WETH.withdraw(
            _value
        );
    }

    modifier updatePools() {
        _updatePools();
        _;
    }

    /**
     * @dev Update logic for pools via wise lending
     * interfaces
     */
    function _updatePools()
        private
    {
        WISE_LENDING.preparePool(
            WST_ETH_ADDRESS
        );

        WISE_LENDING.preparePool(
            AAVE_WETH_ADDRESS
        );
    }

    /**
     * @dev Internal function getting the
     * borrow shares from position {_nftId}
     * with token {_borrowToken}
     */
    function _getPositionBorrowShares(
        uint256 _nftId
    )
        internal
        view
        returns (uint256)
    {
        return WISE_LENDING.getPositionBorrowShares(
            _nftId,
            AAVE_WETH_ADDRESS
        );
    }

    /**
     * @dev Internal function converting
     * borrow shares into tokens.
     */
    function _getPositionBorrowToken(
        uint256 _nftId
    )
        internal
        view
        returns(uint256)
    {
        return WISE_LENDING.paybackAmount(
            AAVE_WETH_ADDRESS,
            _getPositionBorrowShares(
                _nftId
            )
        );
    }

    /**
     * @dev Internal function getting the
     * lending shares from position {_nftId}
     * with token {_borrowToken}
     */
    function _getPositionLendingShares(
        uint256 _nftId
    )
        internal
        view
        returns (uint256)
    {
        return WISE_LENDING.getPositionLendingShares(
            _nftId,
            WST_ETH_ADDRESS
        );
    }

    /**
     * @dev Internal function converting
     * lending shares into tokens.
     */
    function _getPostionCollateralToken(
        uint256 _nftId
    )
        internal
        view
        returns(uint256)
    {
        return WISE_LENDING.cashoutAmount(
            WST_ETH_ADDRESS,
            _getPositionLendingShares(
                _nftId
            )
        );
    }

    /**
     * @dev Read function returning the total
     * borrow amount in USD from postion {_nftId}
     */
    function getPositionBorrowUSD(
        uint256 _nftId
    )
        public
        view
        returns (uint256)
    {
        return ORACLE_HUB.getTokensInUSD(
            AAVE_WETH_ADDRESS,
            _getPositionBorrowToken(
                _nftId
            )
        );
    }

    /**
     * @dev Read function returning the total
     * lending amount in USD from postion {_nftId}
     */
    function getTotalWeightedCollateralUSD(
        uint256 _nftId
    )
        public
        view
        returns (uint256)
    {
        return  ORACLE_HUB.getTokensInUSD(
            WST_ETH_ADDRESS,
            _getPostionCollateralToken(_nftId)
        )
            * collateralFactor
            / PRECISION_FACTOR_E18;
    }

    /**
     * @dev Internal function checking if a position
     * with {_nftId} is still used to lock it for
     * unregister function.
     */
    function getLeverageAmount(
        uint256 _initialAmount,
        uint256 _leverage
    )
        public
        pure
        returns (uint256)
    {
        return _initialAmount
            * _leverage
            / PRECISION_FACTOR_E18;
    }

    /**
     * @dev Internal function with math logic for approximating
     * the net APY for the postion aftrer creation.
     */
    function _getApproxNetAPY(
        uint256 _initialAmount,
        uint256 _leverage,
        uint256 _wstETHAPY
    )
        internal
        view
        returns (
            uint256,
            bool
        )
    {
        if (_leverage < PRECISION_FACTOR_E18) {
            return (0, false);
        }

        uint256 leveragedAmount = getLeverageAmount(
            _initialAmount,
            _leverage
        );

        uint256 flashloanAmount = leveragedAmount
            - _initialAmount;

        uint256 newBorrowRate = _getNewBorrowRate(
            flashloanAmount
        );

        uint256 leveragedPositivAPY = _wstETHAPY
            * _leverage
            / PRECISION_FACTOR_E18;

        uint256 leveragedNegativeAPY = newBorrowRate
            * (_leverage - PRECISION_FACTOR_E18)
            / PRECISION_FACTOR_E18;

        bool isPositive = leveragedPositivAPY >= leveragedNegativeAPY;

        uint256 netAPY = isPositive == true
            ? leveragedPositivAPY - leveragedNegativeAPY
            : leveragedNegativeAPY - leveragedPositivAPY;

        return (
            netAPY,
            isPositive
        );
    }

    /**
     * @dev Internal function with math logic for approximating
     * the new borrow APY.
     */
    function _getNewBorrowRate(
        uint256 _borrowAmount
    )
        internal
        view
        returns (uint256)
    {
        uint256 totalPool = WISE_LENDING.getTotalPool(
            AAVE_WETH_ADDRESS
        );

        uint256 pseudoPool = WISE_LENDING.getPseudoTotalPool(
            AAVE_WETH_ADDRESS
        );

        if (totalPool > pseudoPool) {
            return 0;
        }

        uint256 newUtilization = PRECISION_FACTOR_E18 - (PRECISION_FACTOR_E18
            * (totalPool - _borrowAmount)
            / pseudoPool
        );

        uint256 pole = WISE_LENDING.borrowRatesData(
            AAVE_WETH_ADDRESS
        ).pole;

        uint256 mulFactor = WISE_LENDING.borrowRatesData(
            AAVE_WETH_ADDRESS
        ).multiplicativeFactor;

        uint256 baseDivider = pole
            * (pole - newUtilization);

        return mulFactor
            * PRECISION_FACTOR_E18
            * newUtilization
            / baseDivider;
    }

    /**
     * @dev Internal function checking if a position
     * with {_nftId} has a debt ratio under 100%.
     */
    function _checkDebtRatio(
        uint256 _nftId
    )
        internal
        view
        returns (bool res)
    {
        res = getTotalWeightedCollateralUSD(_nftId)
            > getPositionBorrowUSD(_nftId);
    }

    /**
     * @dev Internal function checking if the debt
     * ratio threshold fof 100 % is reached when a
     * manually withdraw is performed.
     */
    function _checkBorrowLimit(
        uint256 _nftId,
        uint256 _amount
    )
        internal
        view
        returns (bool)
    {
        uint256 borrowAmount = getPositionBorrowUSD(
            _nftId
        );

        if (borrowAmount == 0) {
            return true;
        }

        uint256 withdrawValue = ORACLE_HUB.getTokensInUSD(
            WST_ETH_ADDRESS,
            _amount
        )
            * collateralFactor
            / PRECISION_FACTOR_E18;

        return getTotalWeightedCollateralUSD(_nftId) - withdrawValue
            > borrowAmount;
    }

    /**
     * @dev Internal function checking if the leveraged
     * amount is above 5000 USD in value.
     */
    function _aboveMinDepositAmount(
        uint256 _amount
    )
        internal
        view
        returns (bool)
    {
        uint256 equivUSD = ORACLE_HUB.getTokensInUSD(
            WETH_ADDRESS,
            _amount
        );

        return equivUSD >= minDepositUsdAmount;
    }
}
