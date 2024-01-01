// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "SafeCast.sol";

import "FixedPoint.sol";
import "SignedFixedPoint.sol";

import "IECLP.sol";

library BalancerLPSharePricing {
    using FixedPoint for uint256;
    using SignedFixedPoint for int256;
    using SafeCast for uint256;
    using SafeCast for int256;

    uint256 internal constant ONEHALF = 0.5e18;

    uint256 internal constant MIN_PRICE_CPMM = 2.0002e11; // 2.0002e-7 scaled
    uint256 internal constant MIN_PRICE_2CLP = 2.0002e11; // 2.0002e-7 scaled
    uint256 internal constant MIN_PRICE_ASSET2_3CLP = 4e13; // 4e-5 scaled
    uint256 internal constant MIN_REL_PRICE_3CLP = 1e14; // 1e-4 scaled
    uint256 internal constant MAX_REL_PRICE_3CLP = 1e22; // 1e4 scaled
    uint256 internal constant MIN_PRICE_ECLP = 1e11; // 1e-7 scaled

    /** @dev Calculates the value of Balancer pool tokens (BPT) that use constant product invariant.
     *  @param weights = weights of underlying assets
     *  @param underlyingPrices = prices of underlying assets, in same order as weights
     *  @param invariantDivSupply = value of the pool invariant / supply of BPT
     *  This calculation is robust to price manipulation within the Balancer pool.
     *  Bounds on underlying prices are enforced to make this safe for invariantDivSupply >= 1e-6.
     *  Then max error 3e-12 (rel) + 1e-18 (abs).
     */
    function priceBptCPMM(
        uint256[] memory weights,
        uint256 invariantDivSupply,
        uint256[] memory underlyingPrices
    ) internal pure returns (uint256 bptPrice) {
        /**********************************************************************************************
        //                        L   n               w_i                               //
        //            bptPrice = ---  Π   (p_i / w_i)^                                  //
        //                        S   i=1                                               //
        **********************************************************************************************/
        uint256 prod = FixedPoint.ONE;
        for (uint256 i = 0; i < weights.length; i++) {
            require(underlyingPrices[i] >= MIN_PRICE_CPMM, Errors.TOKEN_PRICES_TOO_SMALL);

            prod = prod.mulDown(
                FixedPoint.powDown(underlyingPrices[i].divDown(weights[i]), weights[i])
            );
            bptPrice = invariantDivSupply.mulDown(prod);
        }
    }

    /** @dev Efficiently calculates the value of Balancer pool tokens (BPT) for two asset pools with
     * constant product invariant.
     *  @param weights = weights of underlying assets
     *  @param underlyingPrices = prices of underlying assets, in same order as weights
     *  @param invariantDivSupply = value of the pool invariant / supply of BPT
     *  This calculation is robust to price manipulation within the Balancer pool.
     *  Bounds on underlying prices are enforced to make this safe for invariantDivSupply >= 1e-6.
     *  Then max error 3e-12 (rel) + 1e-18 (abs).
     */
    function priceBptTwoAssetCPMM(
        uint256[] memory weights,
        uint256 invariantDivSupply,
        uint256[] memory underlyingPrices
    ) internal pure returns (uint256 bptPrice) {
        /**********************************************************************************************
        //                        L                        w_0                                       //
        //            bptPrice = --- (  w_1 p_0 / w_0 p_1 )^   (p_1 / w_1)                           //
        //                        S                                                                  //
        **********************************************************************************************/
        // firstTerm is invariantDivSupply

        require(weights.length == 2, Errors.INVALID_NUMBER_WEIGHTS);
        require(underlyingPrices[0] >= MIN_PRICE_CPMM, Errors.TOKEN_PRICES_TOO_SMALL);
        require(underlyingPrices[1] >= MIN_PRICE_CPMM, Errors.TOKEN_PRICES_TOO_SMALL);

        (uint256 i, uint256 j) = weights[1].mulDown(underlyingPrices[0]) >
            weights[0].mulDown(underlyingPrices[1])
            ? (1, 0)
            : (0, 1);

        uint256 secondTerm = FixedPoint.powDown(
            underlyingPrices[i].mulDown(weights[j]).divDown(
                weights[i].mulDown(underlyingPrices[j])
            ),
            weights[i]
        );

        uint256 thirdTerm = underlyingPrices[j].divDown(weights[j]);

        bptPrice = invariantDivSupply.mulDown(secondTerm).mulDown(thirdTerm);
    }

    /** @dev Calculates value of BPT for constant product invariant with equal weights.
     *  Compared to general CPMM, everything can be grouped into one fractional power to save gas.
     *  This calculation is robust to price manipulation within the Balancer pool.
     *  Bounds on underlying prices are enforced to make this safe for invariantDivSupply >= 1e-6.
     *  Then max error 3e-12 (rel) + 1e-18 (abs).
     */
    function priceBptCPMMEqualWeights(
        uint256 weight,
        uint256 invariantDivSupply,
        uint256[] memory underlyingPrices
    ) internal pure returns (uint256 bptPrice) {
        /**********************************************************************************************
        //                        L     n             w                                 //
        //            bptPrice = ---  ( Π   p_i / w )^                                  //
        //                        S     i=1                                             //
        **********************************************************************************************/
        uint256 prod = FixedPoint.ONE;
        for (uint256 i = 0; i < underlyingPrices.length; i++) {
            require(underlyingPrices[i] >= MIN_PRICE_CPMM, Errors.TOKEN_PRICES_TOO_SMALL);
            prod = prod.mulDown(underlyingPrices[i].divDown(weight));
        }
        prod = FixedPoint.powDown(prod, weight);
        bptPrice = invariantDivSupply.mulDown(prod);
    }

    /** @dev Calculates the value of BPT for 2CLP pools.
     *  These are constant product invariant 2-pools with 1/2 weights and virtual reserves.
     *  @param sqrtAlpha = sqrt of lower price bound
     *  @param sqrtBeta = sqrt of upper price bound
     *  @param invariantDivSupply = value of the pool invariant / supply of BPT
     *  This calculation is robust to price manipulation within the Balancer pool.
     *  Bounds on underlying prices are enforced to make this safe for alpha, beta in [0.1, 10.0]
     *  with relative price range width (beta/alpha-1) >= 1bp. This yields relative error at most
     *  0.1bp. This assumes invariantDivSupply >= 2 or the total redemption amount being at least 1
     *  USD.
     */
    function priceBpt2CLP(
        uint256 sqrtAlpha,
        uint256 sqrtBeta,
        uint256 invariantDivSupply,
        uint256[] memory underlyingPrices
    ) internal pure returns (uint256 bptPrice) {
        /**********************************************************************************************
        // When alpha < p_x/p_y < beta:                                                 //
        //                 L                 1/2               1/2              1/2     //
        //     bptPrice = ---  ( 2 (p_x p_y)^     - p_x / beta^     - p_y alpha^    )   //
        //                 S                                                            //
        // When p_x/p_y < alpha: bptPrice = L/S * p_x (1/sqrt(alpha) - 1/sqrt(beta))    //
        // When p_x/p_y > beta: bptPrice = L/S * p_y (sqrt(beta) - sqrt(alpha))         //
        **********************************************************************************************/
        (uint256 px, uint256 py) = (underlyingPrices[0], underlyingPrices[1]);
        require(px >= MIN_PRICE_2CLP, Errors.TOKEN_PRICES_TOO_SMALL);
        require(py >= MIN_PRICE_2CLP, Errors.TOKEN_PRICES_TOO_SMALL);

        uint256 one = FixedPoint.ONE;
        if (px.divDown(py) <= sqrtAlpha.mulUp(sqrtAlpha)) {
            bptPrice = invariantDivSupply.mulDown(px).mulDown(
                one.divDown(sqrtAlpha) - one.divUp(sqrtBeta)
            );
        } else if (px.divUp(py) >= sqrtBeta.mulDown(sqrtBeta)) {
            bptPrice = invariantDivSupply.mulDown(py).mulDown(sqrtBeta - sqrtAlpha);
        } else {
            uint256 sqrPxPy = 2 * FixedPoint.powDown(px.mulDown(py), ONEHALF);
            bptPrice = sqrPxPy - px.divUp(sqrtBeta) - py.mulUp(sqrtAlpha);
            bptPrice = invariantDivSupply.mulDown(bptPrice);
        }
    }

    /** @dev Calculates the value of BPT for 3CLP pools
     *  these are constant product invariant 3-pools with 1/3 weights and virtual reserves
     *  virtual reserves are chosen such that alpha = lower price bound and 1/alpha = upper price bound
     *  @param cbrtAlpha = cube root of alpha (lower price bound)
     *  @param invariantDivSupply = value of the pool invariant / supply of BPT
     *  @param underlyingPrices = array of three prices for the
     *  This calculation is robust to price manipulation within the Balancer pool. The calculation
     *  includes a kind of no-arbitrage equilibrium computation, see the Gyroscope Oracles document,
     *  p. 7.
     *  Bounds on underlying prices are enforced to make this safe for alpha <= 0.9995, i.e.,
     *  relative price range width >= about 10bp and relative prices all within [1e-4, 1e4]. This
     *  yields relative error at most 0.1bp. This assumes invariantDivSupply >= 2 or the total
     *  redemption amount being at least 1 USD.
     */
    function priceBpt3CLP(
        uint256 cbrtAlpha,
        uint256 invariantDivSupply,
        uint256[] memory underlyingPrices
    ) internal pure returns (uint256 bptPrice) {
        require(underlyingPrices.length == 3, Errors.INVALID_ARGUMENT);
        require(underlyingPrices[2] >= MIN_PRICE_ASSET2_3CLP, Errors.TOKEN_PRICES_TOO_SMALL);

        uint256 pXZPool;
        uint256 pYZPool;
        {
            uint256 alpha = cbrtAlpha.mulDown(cbrtAlpha).mulDown(cbrtAlpha);
            uint256 pXZ = underlyingPrices[0].divDown(underlyingPrices[2]);
            uint256 pYZ = underlyingPrices[1].divDown(underlyingPrices[2]);

            // Checks on relative prices to protect against excessive rounding error.
            uint256 pXY = underlyingPrices[0].divDown(underlyingPrices[1]);
            require(pXZ >= MIN_REL_PRICE_3CLP, Errors.TOKEN_PRICES_TOO_SMALL);
            require(pXZ <= MAX_REL_PRICE_3CLP, Errors.TOKEN_PRICES_TOO_SMALL);
            require(pYZ >= MIN_REL_PRICE_3CLP, Errors.TOKEN_PRICES_TOO_SMALL);
            require(pYZ <= MAX_REL_PRICE_3CLP, Errors.TOKEN_PRICES_TOO_SMALL);
            require(pXY >= MIN_REL_PRICE_3CLP, Errors.TOKEN_PRICES_TOO_SMALL);
            require(pXY <= MAX_REL_PRICE_3CLP, Errors.TOKEN_PRICES_TOO_SMALL);

            (pXZPool, pYZPool) = relativeEquilibriumPrices3CLP(alpha, pXZ, pYZ);
        }

        uint256 cbrtPxzPyzPool = pXZPool.mulDown(pYZPool);
        cbrtPxzPyzPool = FixedPoint.powDown(cbrtPxzPyzPool, FixedPoint.ONE / 3);

        // term = helper variable that will be re-used below to avoid stack-too-deep.
        uint256 term = underlyingPrices[0].divDown(pXZPool);
        term += underlyingPrices[1].divDown(pYZPool);
        term += underlyingPrices[2];

        bptPrice = cbrtPxzPyzPool.mulDown(term);

        term = (underlyingPrices[0] + underlyingPrices[1] + underlyingPrices[2]).mulUp(cbrtAlpha);
        bptPrice = bptPrice - term;
        bptPrice = bptPrice.mulDown(invariantDivSupply);
    }

    /** @dev Compute the unique price vector of a 3CLP pool that is in equilibrium with an external market with the given relative prices.
        See Gyroscope Oracles document, Section 4.3.
        @param alpha = lower price bound
        @param pXZ = relative price of asset x denoted in units of z of the external market
        @param pYZ = relative price of asset y denoted in units of z of the external market
        @return relative prices of x and y, respectively, denoted in units of z, of a pool in equilibrium with (pXZ, pYZ).
     */
    function relativeEquilibriumPrices3CLP(
        uint256 alpha,
        uint256 pXZ,
        uint256 pYZ
    ) internal pure returns (uint256, uint256) {
        // NOTE: Rounding directions are less critical here b/c all functions are continuous and we don't take any roots where the radicand can become negative.
        // SOMEDAY this should be reviewed so that we round in a way most favorable to us I guess?
        uint256 alphaInv = FixedPoint.ONE.divDown(alpha);
        if (pYZ < alpha.mulDown(pXZ).mulDown(pXZ)) {
            if (pYZ < alpha) return (FixedPoint.ONE, alpha);
            else if (pYZ > alphaInv) return (alphaInv, alphaInv);
            else {
                uint256 pXPool = alphaInv.mulDown(pYZ).powDown(ONEHALF);
                return (pXPool, pYZ);
            }
        } else if (pXZ < alpha.mulDown(pYZ).mulDown(pYZ)) {
            if (pXZ < alpha) return (alpha, FixedPoint.ONE);
            else if (pXZ > alphaInv) return (alphaInv, alphaInv);
            else {
                uint256 pYPool = alphaInv.mulDown(pXZ).powDown(ONEHALF);
                return (pXZ, pYPool);
            }
        } else if (pXZ.mulDown(pYZ) < alpha) {
            if (pXZ < alpha.mulDown(pYZ)) return (alpha, FixedPoint.ONE);
            else if (pXZ > alphaInv.mulDown(pYZ)) return (FixedPoint.ONE, alpha);
            else {
                // SOMEDAY Gas optimization: sqrtAlpha could be made immutable in the pool and passed as a parameter.
                uint256 sqrtAlpha = alpha.powDown(ONEHALF);
                uint256 sqrtPXY = pXZ.divDown(pYZ).powDown(ONEHALF);
                return (sqrtAlpha.mulDown(sqrtPXY), sqrtAlpha.divDown(sqrtPXY));
            }
        } else {
            return (pXZ, pYZ);
        }
    }

    /** @dev Calculates the value of BPT for constant ellipse (ECLP) pools of two assets
     *  @param params = ECLP pool parameters
     *  @param derivedParams = (tau(alpha), tau(beta)) in 18 decimals. The other elements are not used.
     *  @param invariantDivSupply = value of the pool invariant / supply of BPT
     *  This calculation is robust to price manipulation within the Balancer pool.
     *  Bounds on underlying prices are enforced to make this safe across a range of typical pool
     *  parameter combinations, see `ECLP_precision_analysis_iteration.sage`. These include typical
     *  stable pair configs and the following parameter combinations: alpha in [0.05, 0.999], beta
     *  in [1.001, 1.1], relative price range width (beta/alpha-1) >= 10bp, min-curvature price q =
     *  1.0, lambda in [1, 1e8]. This yields relative error at most 0.1bp, assuming
     *  invariantDivSupply >= 2 or total redemption amount at least 1 USD.
     */
    function priceBptECLP(
        IECLP.Params memory params,
        IECLP.DerivedParams memory derivedParams,
        uint256 invariantDivSupply,
        uint256[] memory underlyingPrices
    ) internal pure returns (uint256 bptPrice) {
        /**********************************************************************************************
        // When alpha < p_x/p_y < beta:                                                              //
        //                L   / / e_x A^{-1} tau(beta) \     -1     / p_x \  \   / p_x \             //
        //   bptPrice =  --- | |                        | - A^  tau|  ---- |  | |       |            //
        //                S   \ \ e_y A^{-1} tau(alpha) /           \ p_y  /  /  \ p_y  /            //
        // When p_x/p_y < alpha:                                                                     //
        //      bptPrice = L/S * p_x ( e_x A^{-1} tau(beta) - e_x A^{-1} tau(alpha) )                //
        // When p_x/p_y > beta:                                                                      //
        //      bptPrice = L/S * p_y (e_y A^{-1} tau(alpha) - e_y A^{-1} tau(beta) )                 //
        **********************************************************************************************/
        require(underlyingPrices[0] >= MIN_PRICE_ECLP, Errors.TOKEN_PRICES_TOO_SMALL);
        require(underlyingPrices[1] >= MIN_PRICE_ECLP, Errors.TOKEN_PRICES_TOO_SMALL);
        (int256 px, int256 py) = (underlyingPrices[0].toInt256(), underlyingPrices[1].toInt256());

        int256 pxIny = px.divDownMag(py);
        if (pxIny < params.alpha) {
            int256 bP = (mulAinv(params, derivedParams.tauBeta).x -
                mulAinv(params, derivedParams.tauAlpha).x);
            bptPrice = (bP.mulDownMag(px)).toUint256().mulDown(invariantDivSupply);
        } else if (pxIny > params.beta) {
            int256 bP = (mulAinv(params, derivedParams.tauAlpha).y -
                mulAinv(params, derivedParams.tauBeta).y);
            bptPrice = (bP.mulDownMag(py)).toUint256().mulDown(invariantDivSupply);
        } else {
            IECLP.Vector2 memory vec = mulAinv(params, tau(params, pxIny));
            vec.x = mulAinv(params, derivedParams.tauBeta).x - vec.x;
            vec.y = mulAinv(params, derivedParams.tauAlpha).y - vec.y;
            bptPrice = scalarProdDown(IECLP.Vector2(px, py), vec).toUint256().mulDown(
                invariantDivSupply
            );
        }
    }

    ///////////////////////////////////////////////////////////////////////////////////////
    // The following functions and structs copied over from ECLP math library
    // Can't easily inherit because of different Solidity versions

    // Scalar product of IECLP.Vector2 objects
    function scalarProdDown(IECLP.Vector2 memory t1, IECLP.Vector2 memory t2)
        internal
        pure
        returns (int256 ret)
    {
        ret = t1.x.mulDownMag(t2.x) + t1.y.mulDownMag(t2.y);
    }

    /** @dev Calculate A^{-1}t where A^{-1} is given in Section 2.2
     *  This is rotating and scaling the circle into the ellipse */

    function mulAinv(IECLP.Params memory params, IECLP.Vector2 memory t)
        internal
        pure
        returns (IECLP.Vector2 memory tp)
    {
        tp.x = t.x.mulDownMag(params.lambda).mulDownMag(params.c) + t.y.mulDownMag(params.s);
        tp.y = -t.x.mulDownMag(params.lambda).mulDownMag(params.s) + t.y.mulDownMag(params.c);
    }

    /** @dev Calculate A t where A is given in Section 2.2
     *  This is reversing rotation and scaling of the ellipse (mapping back to circle) */

    function mulA(IECLP.Params memory params, IECLP.Vector2 memory tp)
        internal
        pure
        returns (IECLP.Vector2 memory t)
    {
        t.x =
            params.c.mulDownMag(tp.x).divDownMag(params.lambda) -
            params.s.mulDownMag(tp.y).divDownMag(params.lambda);
        t.y = params.s.mulDownMag(tp.x) + params.c.mulDownMag(tp.y);
    }

    /** @dev Given price px on the transformed ellipse, get the untransformed price pxc on the circle
     *  px = price of asset x in terms of asset y */
    function zeta(IECLP.Params memory params, int256 px) internal pure returns (int256 pxc) {
        IECLP.Vector2 memory nd = mulA(params, IECLP.Vector2(-SignedFixedPoint.ONE, px));
        return -nd.y.divDownMag(nd.x);
    }

    /** @dev Given price px on the transformed ellipse, maps to the corresponding point on the untransformed normalized circle
     *  px = price of asset x in terms of asset y */
    function tau(IECLP.Params memory params, int256 px)
        internal
        pure
        returns (IECLP.Vector2 memory tpp)
    {
        return eta(zeta(params, px));
    }

    /** @dev Given price on a circle, gives the normalized corresponding point on the circle centered at the origin
     *  pxc = price of asset x in terms of asset y (measured on the circle)
     *  Notice that the eta function does not depend on Params */
    function eta(int256 pxc) internal pure returns (IECLP.Vector2 memory tpp) {
        int256 z = FixedPoint
            .powDown(FixedPoint.ONE + (pxc.mulDownMag(pxc).toUint256()), ONEHALF)
            .toInt256();
        tpp = eta(pxc, z);
    }

    /** @dev Calculates eta in more efficient way if the square root is known and input as second arg */
    function eta(int256 pxc, int256 z) internal pure returns (IECLP.Vector2 memory tpp) {
        tpp.x = pxc.divDownMag(z);
        tpp.y = SignedFixedPoint.ONE.divDownMag(z);
    }
}
