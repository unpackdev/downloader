// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.21;

import "./WeightedMathLib.sol";
import "./ERC20.sol";

struct Pool {
    address asset;
    address share;
    uint256 assets;
    uint256 shares;
    uint256 virtualAssets;
    uint256 virtualShares;
    uint256 weightStart;
    uint256 weightEnd;
    uint256 saleStart;
    uint256 saleEnd;
    uint256 totalPurchased;
    uint256 maxSharePrice;
}

library LiquidityBootstrapLib {
    /// -----------------------------------------------------------------------
    /// Dependencies
    /// -----------------------------------------------------------------------

    using WeightedMathLib for *;

    using FixedPointMathLib for *;

    /// -----------------------------------------------------------------------
    /// Swap Helpers
    /// -----------------------------------------------------------------------

    function computeReservesAndWeights(Pool memory args)
        internal
        view
        returns (
            uint256 assetReserve,
            uint256 shareReserve,
            uint256 assetWeight,
            uint256 shareWeight
        )
    {
        assetReserve = args.assets + args.virtualAssets;

        shareReserve = args.shares + args.virtualShares - args.totalPurchased;

        uint256 totalSeconds = args.saleEnd - args.saleStart;

        uint256 secondsElapsed = 0;
        if (block.timestamp > args.saleStart) {
            secondsElapsed = block.timestamp - args.saleStart;
        }

        assetWeight = WeightedMathLib.linearInterpolation({
            x: args.weightStart,
            y: args.weightEnd,
            i: secondsElapsed,
            n: totalSeconds
        });

        shareWeight = uint256(1e18).rawSub(assetWeight);
    }

    function previewAssetsIn(
        Pool memory args,
        uint256 sharesOut
    )
        internal
        view
        returns (uint256 assetsIn)
    {
        (uint256 assetReserve, uint256 shareReserve, uint256 assetWeight, uint256 shareWeight) =
            computeReservesAndWeights(args);

        (uint256 assetReserveScaled, uint256 shareReserveScaled) =
            scaledReserves(args, assetReserve, shareReserve);
        uint256 sharesOutScaled = scaleTokenBefore(args.share, sharesOut);

        assetsIn = sharesOutScaled.getAmountIn(
            assetReserveScaled, shareReserveScaled, assetWeight, shareWeight
        );

        if (assetsIn.divWad(sharesOutScaled) > args.maxSharePrice) {
            assetsIn = sharesOutScaled.divWad(args.maxSharePrice);
        }

        assetsIn = scaleTokenAfter(args.asset, assetsIn);
    }

    function previewSharesOut(
        Pool memory args,
        uint256 assetsIn
    )
        internal
        view
        returns (uint256 sharesOut)
    {
        (uint256 assetReserve, uint256 shareReserve, uint256 assetWeight, uint256 shareWeight) =
            computeReservesAndWeights(args);

        (uint256 assetReserveScaled, uint256 shareReserveScaled) =
            scaledReserves(args, assetReserve, shareReserve);
        uint256 assetsInScaled = scaleTokenBefore(args.asset, assetsIn);

        sharesOut = assetsInScaled.getAmountOut(
            assetReserveScaled, shareReserveScaled, assetWeight, shareWeight
        );

        if (assetsInScaled.divWad(sharesOut) > args.maxSharePrice) {
            sharesOut = assetsInScaled.mulWad(args.maxSharePrice);
        }

        sharesOut = scaleTokenAfter(args.share, sharesOut);
    }

    function previewSharesIn(
        Pool memory args,
        uint256 assetsOut
    )
        internal
        view
        returns (uint256 sharesIn)
    {
        (uint256 assetReserve, uint256 shareReserve, uint256 assetWeight, uint256 shareWeight) =
            computeReservesAndWeights(args);

        (uint256 assetReserveScaled, uint256 shareReserveScaled) =
            scaledReserves(args, assetReserve, shareReserve);
        uint256 assetsOutScaled = scaleTokenBefore(args.asset, assetsOut);

        sharesIn = assetsOutScaled.getAmountIn(
            shareReserveScaled, assetReserveScaled, shareWeight, assetWeight
        );

        if (assetsOutScaled.divWad(sharesIn) > args.maxSharePrice) {
            sharesIn = assetsOutScaled.divWad(args.maxSharePrice);
        }

        sharesIn = scaleTokenAfter(args.share, sharesIn);
    }

    function previewAssetsOut(
        Pool memory args,
        uint256 sharesIn
    )
        internal
        view
        returns (uint256 assetsOut)
    {
        (uint256 assetReserve, uint256 shareReserve, uint256 assetWeight, uint256 shareWeight) =
            computeReservesAndWeights(args);

        (uint256 assetReserveScaled, uint256 shareReserveScaled) =
            scaledReserves(args, assetReserve, shareReserve);
        uint256 sharesInScaled = scaleTokenBefore(args.share, sharesIn);

        assetsOut = sharesInScaled.getAmountOut(
            shareReserveScaled, assetReserveScaled, shareWeight, assetWeight
        );

        if (assetsOut.divWad(sharesInScaled) > args.maxSharePrice) {
            assetsOut = sharesInScaled.mulWad(args.maxSharePrice);
        }

        assetsOut = scaleTokenAfter(args.asset, assetsOut);
    }

    function scaledReserves(
        Pool memory args,
        uint256 assetReserve,
        uint256 shareReserve
    )
        internal
        view
        returns (uint256, uint256)
    {
        return
            (scaleTokenBefore(args.asset, assetReserve), scaleTokenBefore(args.share, shareReserve));
    }

    function scaleTokenBefore(
        address token,
        uint256 amount
    )
        internal
        view
        returns (uint256 scaledAmount)
    {
        uint8 decimals = ERC20(token).decimals();
        scaledAmount = amount;

        if (decimals < 18) {
            uint256 decDiff = uint256(18).rawSub(uint256(decimals));
            scaledAmount = amount * (10 ** decDiff);
        } else if (decimals > 18) {
            uint256 decDiff = uint256(decimals).rawSub(uint256(18));
            scaledAmount = amount / (10 ** decDiff);
        }
    }

    function scaleTokenAfter(
        address token,
        uint256 amount
    )
        internal
        view
        returns (uint256 scaledAmount)
    {
        uint8 decimals = ERC20(token).decimals();
        scaledAmount = amount;

        if (decimals < 18) {
            uint256 decDiff = uint256(18).rawSub(uint256(decimals));
            scaledAmount = amount / (10 ** decDiff);
        } else if (decimals > 18) {
            uint256 decDiff = uint256(decimals).rawSub(uint256(18));
            scaledAmount = amount * (10 ** decDiff);
        }
    }
}
