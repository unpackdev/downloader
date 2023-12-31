// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.21;

interface IAaveHub {

    function getLendingRate(
        address _underlyingAsset
    )
        external
        view
        returns (uint256);
}

interface IWiseSecurity {

    function getUSDBorrow(
        uint256 _nftId,
        address _poolToken
    )
        external
        view
        returns (uint256);

    function getBorrowRate(
        address _poolToken
    )
        external
        view
        returns (uint256);

    function getUSDCollateral(
        uint256 _nftId,
        address _poolToken
    )
        external
        view
        returns (uint256);

    function getLendingRate(
        address _poolToken
    )
        external
        view
        returns (uint256);
}

interface IWiseLending {

    function getPositionBorrowTokenLength(
        uint256 _nftId
    )
        external
        view
        returns (uint256);

    function getPositionBorrowTokenByIndex(
        uint256 _nftId,
        uint256 _index
    )
        external
        view
        returns (address);

    function getPositionLendingTokenByIndex(
        uint256 _nftId,
        uint256 _index
    )
        external
        view
        returns (address);

    function getPositionLendingTokenLength(
        uint256 _nftId
    )
        external
        view
        returns (uint256);
}

interface IFeeManager {

    function isAaveToken(
        address _poolToken
    )
        external
        view
        returns (bool);

    function underlyingToken(
        address _poolToken
    )
        external
        view
        returns (address);
}

contract APYViewer {

    IAaveHub public AAVE_HUB;
    IWiseSecurity public WISE_SECURITY;
    IFeeManager public FEE_MANAGER;
    IWiseLending public WISE_LENDING;

    uint256 constant PRECISION_FACTOR_E18 = 1E18;

    address constant ZERO_ADDRESS = address(0x0);

    struct ApyData {
        uint256 netAPY;
        uint256 usdValue;
        uint256 usdValueDebt;
        uint256 usdValueGain;
        uint256 totalUsdSupply;
        uint256 totalUsdBorrow;
    }

    constructor(
        address _aaveHubAdd,
        address _feeManagerAdd,
        address _wiseLendingAdd,
        address _wiseSecurityAdd
    )
    {
        AAVE_HUB = IAaveHub(
            _aaveHubAdd
        );

        WISE_SECURITY = IWiseSecurity(
            _wiseSecurityAdd
        );

        WISE_LENDING = IWiseLending(
            _wiseLendingAdd
        );

        FEE_MANAGER = IFeeManager(
            _feeManagerAdd
        );
    }

    function overallNetAPYs(
        uint256 _nftId
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            bool
        )
    {
        uint8 i;
        address token;

        ApyData memory data;

        uint256 lenBorrow = WISE_LENDING.getPositionBorrowTokenLength(
            _nftId
        );

        uint256 lenDeposit = WISE_LENDING.getPositionLendingTokenLength(
            _nftId
        );

        for (i = 0; i < lenBorrow; ++i) {

            token = WISE_LENDING.getPositionBorrowTokenByIndex(
                _nftId,
                i
            );

            data.usdValue = WISE_SECURITY.getUSDBorrow(
                _nftId,
                token
            );

            data.totalUsdBorrow += data.usdValue;

            data.usdValueDebt += WISE_SECURITY.getBorrowRate(
                token
            ) * data.usdValue;
        }

        for (i = 0; i < lenDeposit; ++i) {

            token = WISE_LENDING.getPositionLendingTokenByIndex(
                _nftId,
                i
            );

            data.usdValue = WISE_SECURITY.getUSDCollateral(
                _nftId,
                token
            );

            address aaveToken = FEE_MANAGER.underlyingToken(
                token
            );

            uint256 lendingRate = aaveToken == ZERO_ADDRESS
                ? WISE_SECURITY.getLendingRate(token)
                : AAVE_HUB.getLendingRate(aaveToken);

            data.totalUsdSupply += data.usdValue;

            data.usdValueGain += data.usdValue
                * lendingRate;
        }

        uint256 netBorrowAPY = data.totalUsdBorrow != 0
            ? data.usdValueDebt / data.totalUsdBorrow
            : 0;

        uint256 netSupplyAPY = data.totalUsdSupply != 0
            ? data.usdValueGain / data.totalUsdSupply
            : 0;

        if (data.usdValueDebt > data.usdValueGain) {

            data.netAPY = (data.usdValueDebt - data.usdValueGain)
                / data.totalUsdSupply;

            return (
                netBorrowAPY,
                netSupplyAPY,
                data.netAPY,
                true
            );
        }

        data.netAPY = (data.usdValueGain - data.usdValueDebt)
            / data.totalUsdSupply;

        return (
            netBorrowAPY,
            netSupplyAPY,
            data.netAPY,
            false
        );
    }

    function getBorrowRate(
        address _poolToken
    )
        external
        view
        returns (uint256)
    {
        return WISE_SECURITY.getBorrowRate(
            _poolToken
        );
    }

    function getLendingRate(
        address _poolToken
    )
        external
        view
        returns (uint256)
    {
        return WISE_SECURITY.getLendingRate(
            _poolToken
        );
    }

    function getLendingRateAave(
        address _underlyingAsset
    )
        external
        view
        returns (uint256)
    {
        return AAVE_HUB.getLendingRate(
            _underlyingAsset
        );
    }
}