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

    function overallNetAPY(
        uint256 _nftId
    )
        external
        view
        returns (uint256, bool)
    {
        uint8 i;
        address token;
        uint256 usdValue;
        uint256 usdValueDebt;
        uint256 usdValueGain;
        uint256 totalUsdSupply;

        uint256 netAPY;

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

            usdValue = WISE_SECURITY.getUSDBorrow(
                _nftId,
                token
            );

            usdValueDebt += WISE_SECURITY.getBorrowRate(
                token
            ) * usdValue;
        }

        for (i = 0; i < lenDeposit; ++i) {

            token = WISE_LENDING.getPositionLendingTokenByIndex(
                _nftId,
                i
            );

            usdValue = WISE_SECURITY.getUSDCollateral(
                _nftId,
                token
            );

            address aaveToken = FEE_MANAGER.underlyingToken(
                token
            );

            uint256 lendingRate = AAVE_HUB.getLendingRate(
                aaveToken
            );

            if (FEE_MANAGER.isAaveToken(token) == false) {
                lendingRate = WISE_SECURITY.getLendingRate(
                    token
                );
            }

            totalUsdSupply += usdValue;
            usdValueGain += usdValue
                * lendingRate;
        }

        if (usdValueDebt > usdValueGain) {

            netAPY = (usdValueDebt - usdValueGain)
                / totalUsdSupply;

            return (netAPY, true);
        }

        netAPY = (usdValueGain - usdValueDebt)
            / totalUsdSupply;

        return (netAPY, false);
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