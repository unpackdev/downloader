// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./variables.sol";
import "./IProxy.sol";

contract PrimaryHelpers is Variables {
    /***********************************|
    |              ERRORS               |
    |__________________________________*/
    error Helpers__UnsupportedProtocolId();
    error Helpers__NotRebalancer();
    error Helpers__Reentrant();
    error Helpers__EulerDisabled();


    /***********************************|
    |              MODIFIERS            |
    |__________________________________*/
    modifier onlyRebalancer() {
        if (
            !(isRebalancer[msg.sender] ||
                IProxy(address(this)).getAdmin() == msg.sender)
        ) {
            revert Helpers__NotRebalancer();
        }
        _;
    }

    /**
     * @dev reentrancy gaurd.
     */
    modifier nonReentrant() {
        if (_status == 2) revert Helpers__Reentrant();
        _status = 2;
        _;
        _status = 1;
    }
}

contract Helpers is PrimaryHelpers {
    struct ProtocolAssetsInStETH {
        uint256 stETH; // supply
        uint256 wETH; // borrow
    }

    struct ProtocolAssetsInWstETH {
        uint256 wstETH; // supply
        uint256 wETH; // borrow
    }

    struct IdealBalances {
        uint256 stETH;
        uint256 wstETH;
        uint256 wETH;
    }

    struct NetAssetsHelper {
        ProtocolAssetsInStETH aaveV2;
        ProtocolAssetsInWstETH aaveV3;
        ProtocolAssetsInWstETH compoundV3;
        ProtocolAssetsInWstETH euler;
        ProtocolAssetsInStETH morphoAaveV2;
        ProtocolAssetsInWstETH morphoAaveV3;
        ProtocolAssetsInWstETH spark;
        IdealBalances vaultBalances;
        IdealBalances dsaBalances;
    }


    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = ((x * y) + RAY / 2) / RAY;
    }

    /// @dev Executes the ray-based multiplication of 2 numbers, rounded down.
    /// @param x Ray.
    /// @param y Ray.
    /// @return z The result of x * y, in ray.
    function rayMulDown(uint256 x, uint256 y) internal pure returns (uint256 z) {
        // Load the state variable into a local variable so it can be accessed to inline assembly
        uint256 maxUint = MAX_UINT256;
        // Overflow if
        //     x * y > type(uint256).max
        // <=> y > 0 and x > type(uint256).max / y
        assembly {
            if mul(y, gt(x, div(maxUint, y))) { revert(0, 0) }

            z := div(mul(x, y), RAY)
        }
    }

    /// @dev Executes the ray-based multiplication of 2 numbers, rounded up.
    /// @param x Ray.
    /// @param y Wad.
    /// @return z The result of x * y, in ray.
    function rayMulUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        uint256 maxUintMinusRayMinusOne = MAX_UINT256_MINUS_RAY_MINUS_ONE;
        uint256 rayMinusOne = RAY_MINUS_ONE;
        // Overflow if
        //     x * y + RAY_MINUS_ONE > type(uint256).max
        // <=> x * y > type(uint256).max - RAY_MINUS_ONE
        // <=> y > 0 and x > (type(uint256).max - RAY_MINUS_ONE) / y
        assembly {
            if mul(y, gt(x, div(maxUintMinusRayMinusOne, y))) { revert(0, 0) }

            z := div(add(mul(x, y), rayMinusOne), RAY)
        }
    }

    /// Returns ratio of Aave V2 in terms of `WETH` and `STETH`.
    function getRatioAaveV2()
        public
        view
        returns (uint256 stEthAmount_, uint256 ethAmount_, uint256 ratio_)
    {
        stEthAmount_ = IERC20(A_STETH_ADDRESS).balanceOf(address(vaultDSA));
        ethAmount_ = IERC20(D_WETH_ADDRESS).balanceOf(address(vaultDSA));
        ratio_ = stEthAmount_ == 0 ? 0 : (ethAmount_ * 1e6) / stEthAmount_;
    }

    /// @param stEthPerWsteth_ Amount of stETH for one wstETH.
    /// `stEthPerWsteth_` can be sent as 0 and it will internally calculate the conversion rate.
    /// This is done to save on gas by removing conversion rate calculation for each protocol.
    /// Returns ratio of Aave V3 in terms of `WETH` and `STETH`.
    function getRatioAaveV3(
        uint256 stEthPerWsteth_
    )
        public
        view
        returns (
            uint256 wstEthAmount_,
            uint256 stEthAmount_,
            uint256 ethAmount_,
            uint256 ratio_
        )
    {
        wstEthAmount_ = IERC20(A_WSTETH_ADDRESS_AAVEV3).balanceOf(
            address(vaultDSA)
        );

        if (stEthPerWsteth_ > 0) {
            // Convert wstETH collateral balance to stETH.
            stEthAmount_ = (wstEthAmount_ * stEthPerWsteth_) / 1e18;
        } else {
            stEthAmount_ = WSTETH_CONTRACT.getStETHByWstETH(wstEthAmount_);
        }
        ethAmount_ = IERC20(D_WETH_ADDRESS_AAVEV3).balanceOf(address(vaultDSA));

        ratio_ = stEthAmount_ == 0 ? 0 : (ethAmount_ * 1e6) / stEthAmount_;
    }

    /// @param stEthPerWsteth_ Amount of stETH for one wstETH.
    /// `stEthPerWsteth_` can be sent as 0 and it will internally calculate the conversion rate.
    /// This is done to save on gas by removing conversion rate calculation for each protocol.
    /// Returns ratio of Compound V3 in terms of `ETH` and `STETH`.
    function getRatioCompoundV3(
        uint256 stEthPerWsteth_
    )
        public
        view
        returns (
            uint256 wstEthAmount_,
            uint256 stEthAmount_,
            uint256 ethAmount_,
            uint256 ratio_
        )
    {
        ethAmount_ = COMP_ETH_MARKET_CONTRACT.borrowBalanceOf(
            address(vaultDSA)
        );

        ICompoundMarket.UserCollateral
            memory collateralData_ = COMP_ETH_MARKET_CONTRACT.userCollateral(
                address(vaultDSA),
                WSTETH_ADDRESS
            );

        wstEthAmount_ = uint256(collateralData_.balance);

        if (stEthPerWsteth_ > 0) {
            // Convert wstETH collateral balance to stETH.
            stEthAmount_ = (wstEthAmount_ * stEthPerWsteth_) / 1e18;
        } else {
            stEthAmount_ = WSTETH_CONTRACT.getStETHByWstETH(wstEthAmount_);
        }
        ratio_ = stEthAmount_ == 0 ? 0 : (ethAmount_ * 1e6) / stEthAmount_;
    }

    /// @param stEthPerWsteth_ Amount of stETH for one wstETH.
    /// `stEthPerWsteth_` can be sent as 0 and it will internally calculate the conversion rate.
    /// This is done to save on gas by removing conversion rate calculation for each protocol.
    /// Returns ratio of Euler in terms of `ETH` and `STETH`.
    function getRatioEuler(
        uint256 stEthPerWsteth_
    )
        public
        view
        returns (
            uint256 wstEthAmount_,
            uint256 stEthAmount_,
            uint256 ethAmount_,
            uint256 ratio_
        )
    {
        wstEthAmount_ = 0;
        stEthAmount_ = 0;
        ethAmount_ = 0;
        ratio_ = 0;

        // wstEthAmount_ = IEulerTokens(E_WSTETH_ADDRESS).balanceOfUnderlying(
        //     address(vaultDSA)
        // );

        // if (stEthPerWsteth_ > 0) {
        //     // Convert wstETH collateral balance to stETH.
        //     stEthAmount_ = (wstEthAmount_ * stEthPerWsteth_) / 1e18;
        // } else {
        //     stEthAmount_ = WSTETH_CONTRACT.getStETHByWstETH(wstEthAmount_);
        // }
        // ethAmount_ = IEulerTokens(D_WETH_ADDRESS_EULER).balanceOf(
        //     address(vaultDSA)
        // );

        // ratio_ = stEthAmount_ == 0 ? 0 : (ethAmount_ * 1e6) / stEthAmount_;
    }

    /// Returns ratio of Morpho Aave in terms of `ETH` and `STETH`.
    function getRatioMorphoAaveV2()
        public
        view
        returns (
            uint256 stEthAmount_, // Aggreagted value of stETH in Pool and P2P
            uint256 stEthAmountPool_,
            uint256 stEthAmountP2P_,
            uint256 ethAmount_, // Aggreagted value of eth in Pool and P2P
            uint256 ethAmountPool_,
            uint256 ethAmountP2P_,
            uint256 ratio_
        )
    {
        // `supplyBalanceInOf` => The supply balance of a user. aToken -> user -> balances.
        IMorphoAaveV2.SupplyBalance memory supplyBalanceSteth_ = MORPHO_CONTRACT
            .supplyBalanceInOf(A_STETH_ADDRESS, address(vaultDSA));

        // For a given market, the borrow balance of a user. aToken -> user -> balances.
        IMorphoAaveV2.BorrowBalance memory borrowBalanceWeth_ = MORPHO_CONTRACT
            .borrowBalanceInOf(
                A_WETH_ADDRESS, // aToken is used in mapping
                address(vaultDSA)
            );

        stEthAmountPool_ = rmul(
            supplyBalanceSteth_.onPool,
            (MORPHO_CONTRACT.poolIndexes(A_STETH_ADDRESS).poolSupplyIndex)
        );

        stEthAmountP2P_ = rmul(
            supplyBalanceSteth_.inP2P,
            MORPHO_CONTRACT.p2pSupplyIndex(A_STETH_ADDRESS)
        );

        // Supply balance = (pool supply * pool supply index) + (p2p supply * p2p supply index)
        stEthAmount_ = stEthAmountPool_ + stEthAmountP2P_;

        ethAmountPool_ = rmul(
            borrowBalanceWeth_.onPool,
            (MORPHO_CONTRACT.poolIndexes(A_WETH_ADDRESS).poolBorrowIndex)
        );

        ethAmountP2P_ = rmul(
            borrowBalanceWeth_.inP2P,
            (MORPHO_CONTRACT.p2pBorrowIndex(A_WETH_ADDRESS))
        );

        // Borrow balance = (pool borrow * pool borrow index) + (p2p borrow * p2p borrow index)
        ethAmount_ = ethAmountPool_ + ethAmountP2P_;

        ratio_ = stEthAmount_ == 0 ? 0 : (ethAmount_ * 1e6) / stEthAmount_;
    }

    /// @notice Returns the borrow balance in underlying in a given market.
    /// @param underlying_ The address of the underlying asset.
    /// @return totalBalance_ The total balance of the user (in underlying). Includes pool and P2P amounts.
    function borrowBalanceMorphoAaveV3(address underlying_)
        public
        view
        returns (uint256 totalBalance_)
    {
        IMorphoAaveV3.Indexes256 memory indexes_ = MORPHO_AAVE_V3.updatedIndexes(underlying_);

        uint256 borrowedBalanceP2P_ = rayMulUp(
            MORPHO_AAVE_V3.scaledP2PBorrowBalance(underlying_, address(vaultDSA)),
            indexes_.borrow.p2pIndex
        );

        uint256 borrowedBalancePool_ = rayMulUp(
            MORPHO_AAVE_V3.scaledPoolBorrowBalance(underlying_, address(vaultDSA)),
            indexes_.borrow.poolIndex
        );

        // Includes Pool and P2P amounts.
        totalBalance_ = borrowedBalanceP2P_ + borrowedBalancePool_;
    }

    /// @notice Returns the supply collateral balance on the `underlying` market (in underlying).
    /// @param underlying_ The address of the underlying asset.
    function collateralBalanceMorphoAaveV3(address underlying_)
        public
        view
        returns (uint256 collateralBalance_)
    {
        IMorphoAaveV3.Indexes256 memory indexes_ = MORPHO_AAVE_V3.updatedIndexes(underlying_);

        collateralBalance_ = rayMulDown(
            MORPHO_AAVE_V3.scaledCollateralBalance(underlying_, address(vaultDSA)),
            indexes_.supply.poolIndex
        );
    }

    /// @param stEthPerWsteth_ Amount of stETH for one wstETH.
    /// `stEthPerWsteth_` can be sent as 0 and it will internally calculate the conversion rate.
    /// This is done to save on gas by removing conversion rate calculation for each protocol.
    /// Returns ratio of Morpho Aave V3 in terms of `WETH` and `STETH`.
    function getRatioMorphoAaveV3(
        uint256 stEthPerWsteth_
    )
        public
        view
        returns (
            uint256 wstEthAmount_,
            uint256 stEthAmount_,
            uint256 ethAmount_,
            uint256 ratio_
        )
    {
        wstEthAmount_ = collateralBalanceMorphoAaveV3(WSTETH_ADDRESS);

        if (stEthPerWsteth_ > 0) {
            // Convert wstETH collateral balance to stETH.
            stEthAmount_ = (wstEthAmount_ * stEthPerWsteth_) / 1e18;
        } else {
            stEthAmount_ = WSTETH_CONTRACT.getStETHByWstETH(wstEthAmount_);
        }
        ethAmount_ = borrowBalanceMorphoAaveV3(WETH_ADDRESS);

        ratio_ = stEthAmount_ == 0 ? 0 : (ethAmount_ * 1e6) / stEthAmount_;
    }

    /// @param stEthPerWsteth_ Amount of stETH for one wstETH.
    /// `stEthPerWsteth_` can be sent as 0 and it will internally calculate the conversion rate.
    /// This is done to save on gas by removing conversion rate calculation for each protocol.
    /// Returns ratio of Spark in terms of `WETH` and `STETH`.
    function getRatioSpark(
        uint256 stEthPerWsteth_
    )
        public
        view
        returns (
            uint256 wstEthAmount_,
            uint256 stEthAmount_,
            uint256 ethAmount_,
            uint256 ratio_
        )
    {
        wstEthAmount_ = IERC20(SP_WSTETH_ADDRESS_SPARK).balanceOf(
            address(vaultDSA)
        );

        if (stEthPerWsteth_ > 0) {
            // Convert wstETH collateral balance to stETH.
            stEthAmount_ = (wstEthAmount_ * stEthPerWsteth_) / 1e18;
        } else {
            stEthAmount_ = WSTETH_CONTRACT.getStETHByWstETH(wstEthAmount_);
        }
        ethAmount_ = IERC20(D_WETH_ADDRESS_SPARK).balanceOf(address(vaultDSA));

        ratio_ = stEthAmount_ == 0 ? 0 : (ethAmount_ * 1e6) / stEthAmount_;
    }

    function getProtocolRatio(
        uint8 protocolId_
    ) public view returns (uint256 ratio_) {
        if (protocolId_ == 1) {
            // stETH based protocol
            (, , ratio_) = getRatioAaveV2();
        } else if (protocolId_ == 2) {
            // wstETH based protocol
            uint256 stEthPerWsteth_ = WSTETH_CONTRACT.stEthPerToken();
            (, , , ratio_) = getRatioAaveV3(stEthPerWsteth_);
        } else if (protocolId_ == 3) {
            // wstETH based protocol
            uint256 stEthPerWsteth_ = WSTETH_CONTRACT.stEthPerToken();
            (, , , ratio_) = getRatioCompoundV3(stEthPerWsteth_);
        } else if (protocolId_ == 4) {
            // wstETH based protocol
            uint256 stEthPerWsteth_ = WSTETH_CONTRACT.stEthPerToken();
            (, , , ratio_) = getRatioEuler(stEthPerWsteth_);
        } else if (protocolId_ == 5) {
            // stETH based protocol
            (, , , , , , ratio_) = getRatioMorphoAaveV2();
        } else if (protocolId_ == 6) {
            // wstETH based protocol
            uint256 stEthPerWsteth_ = WSTETH_CONTRACT.stEthPerToken();
            (, , , ratio_) = getRatioMorphoAaveV3(stEthPerWsteth_);
        } else if (protocolId_ == 7) {
            // wstETH based protocol
            uint256 stEthPerWsteth_ = WSTETH_CONTRACT.stEthPerToken();
            (, , , ratio_) = getRatioSpark(stEthPerWsteth_);
        } else {
            revert Helpers__UnsupportedProtocolId();
        }
    }

    function getNetAssets()
        public
        view
        returns (
            uint256 totalAssets_, // Total assets(collaterals + ideal balances) inlcuding reveune
            uint256 totalDebt_, // Total debt
            uint256 netAssets_, // Total assets - Total debt - Reveune
            uint256 aggregatedRatio_, // Aggregated ratio of vault (Total debt/ (Total assets - revenue))
            NetAssetsHelper memory assets_
        )
    {
        uint256 stETHPerWstETH_ = WSTETH_CONTRACT.stEthPerToken();

        // Calculate collateral and debt values for all the protocols

        // stETH based protocols
        (assets_.aaveV2.stETH, assets_.aaveV2.wETH, ) = getRatioAaveV2();

        (
            assets_.morphoAaveV2.stETH,
            ,
            ,
            assets_.morphoAaveV2.wETH,
            ,
            ,

        ) = getRatioMorphoAaveV2();

        // wstETH based protocols
        (assets_.aaveV3.wstETH, , assets_.aaveV3.wETH, ) = getRatioAaveV3(
            stETHPerWstETH_
        );

        (
            assets_.compoundV3.wstETH,
            ,
            assets_.compoundV3.wETH,

        ) = getRatioCompoundV3(stETHPerWstETH_);

        (assets_.euler.wstETH, , assets_.euler.wETH, ) = getRatioEuler(
            stETHPerWstETH_
        );

        // wstETH based protocols
        (assets_.morphoAaveV3.wstETH, , assets_.morphoAaveV3.wETH, ) = getRatioMorphoAaveV3(
            stETHPerWstETH_
        );

        // wstETH based protocols
        (assets_.spark.wstETH, , assets_.spark.wETH, ) = getRatioSpark(
            stETHPerWstETH_
        );

        // Ideal wstETH balances in vault and DSA
        assets_.vaultBalances.wstETH = IERC20(WSTETH_ADDRESS).balanceOf(
            address(this)
        );
        assets_.dsaBalances.wstETH = IERC20(WSTETH_ADDRESS).balanceOf(
            address(vaultDSA)
        );

        // Ideal stETH balances in vault and DSA
        assets_.vaultBalances.stETH = IERC20(STETH_ADDRESS).balanceOf(
            address(this)
        );
        assets_.dsaBalances.stETH = IERC20(STETH_ADDRESS).balanceOf(
            address(vaultDSA)
        );

        // Ideal wETH balances in vault and DSA
        assets_.vaultBalances.wETH = IERC20(WETH_ADDRESS).balanceOf(
            address(this)
        );
        assets_.dsaBalances.wETH = IERC20(WETH_ADDRESS).balanceOf(
            address(vaultDSA)
        );

        // Aggregating total wstETH
        uint256 totalWstETH_ = // Protocols
            assets_.aaveV3.wstETH +
            assets_.compoundV3.wstETH +
            assets_.euler.wstETH +
            assets_.morphoAaveV3.wstETH +
            assets_.spark.wstETH +
            // Ideal balances
            assets_.vaultBalances.wstETH +
            assets_.dsaBalances.wstETH;

        // Net assets are always calculated as STETH supplied - ETH borrowed.

        // Convert all wstETH to stETH to get the same base token.
        uint256 convertedStETH = IWstETH(WSTETH_ADDRESS).getStETHByWstETH(
            totalWstETH_
        );

        // Aggregating total stETH + wETH including revenue
        totalAssets_ =
            // Protocol stETH collateral
            assets_.vaultBalances.stETH +
            assets_.dsaBalances.stETH +
            assets_.aaveV2.stETH +
            assets_.morphoAaveV2.stETH +
            convertedStETH +
            // Ideal wETH balance and assuming wETH 1:1 stETH
            assets_.vaultBalances.wETH +
            assets_.dsaBalances.wETH +
            // Lido queued withdraw assets
            queuedWithdrawStEth;

        // Aggregating total wETH debt from protocols
        totalDebt_ =
            assets_.aaveV2.wETH +
            assets_.aaveV3.wETH +
            assets_.compoundV3.wETH +
            assets_.morphoAaveV2.wETH +
            assets_.euler.wETH +
            assets_.morphoAaveV3.wETH +
            assets_.spark.wETH;

        netAssets_ = totalAssets_ - totalDebt_ - revenue; // Assuming wETH 1:1 stETH
        aggregatedRatio_ = totalAssets_ == 0
            ? 0
            : ((totalDebt_ * 1e6) / (totalAssets_ - revenue));
    }

    /// @notice calculates the withdraw fee: max(percentage amount, absolute amount)
    /// @param stETHAmount_ the amount of assets being withdrawn
    /// @return the withdraw fee amount in assets
    function getWithdrawFee(
        uint256 stETHAmount_
    ) public view returns (uint256) {
        // percentage is in 1e4(1% is 10_000) here we want to have 100% as denominator
        uint256 withdrawFee = (stETHAmount_ * withdrawalFeePercentage) / 1e6;

        if (withdrawFeeAbsoluteMin > withdrawFee) {
            return withdrawFeeAbsoluteMin;
        }
        return withdrawFee;
    }
}
