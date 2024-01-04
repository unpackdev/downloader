// SPDX-License-Identifier: MIT
/*

██████╗ ███████╗██████╗  █████╗ ███████╗███████╗
██╔══██╗██╔════╝██╔══██╗██╔══██╗██╔════╝██╔════╝
██║  ██║█████╗  ██████╔╝███████║███████╗█████╗  
██║  ██║██╔══╝  ██╔══██╗██╔══██║╚════██║██╔══╝  
██████╔╝███████╗██████╔╝██║  ██║███████║███████╗
╚═════╝ ╚══════╝╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝
                                               

* Debase: Curve.sol
* Description:
* Log normal curve to generate curve values in relation to curve input
* Coded by: punkUnknown
*/
pragma solidity >=0.6.6;

import "./ABDKMathQuad.sol";

contract Curve {
    bytes16 private MINUS_ONE = 0xbfff0000000000000000000000000000;
    bytes16 private TENE18 = 0x403abc16d674ec800000000000000000;
    bytes16 private ONE = 0x3fff0000000000000000000000000000;

    /**
     * @notice Function to calculate log normal values using the formula
     * (1/offset * deviation * sqrt(2 * pi))* exp( -((ln offset - deviation)^2)/(2 * deviation^2) )
     * @param priceDelta_ Used as offset for log normal curve
     * @param mean_ Mean for log normal curve
     * @param oneDivDeviationSqrtTwoPi_ Calculation of 1/(deviation * sqrt(2*pi))
     * @param twoDeviationSquare_ Calculation of 2 * deviation^2
     */
    function getCurveValue(
        uint256 priceDelta_,
        bytes16 mean_,
        bytes16 oneDivDeviationSqrtTwoPi_,
        bytes16 twoDeviationSquare_
    ) public view returns (bytes16) {
        bytes16 priceDelta =
            ABDKMathQuad.div(ABDKMathQuad.fromUInt(priceDelta_), TENE18);

        bytes16 res1 = ABDKMathQuad.sub(ABDKMathQuad.ln(priceDelta), mean_);

        bytes16 res2 =
            ABDKMathQuad.mul(
                MINUS_ONE,
                ABDKMathQuad.div(
                    ABDKMathQuad.mul(res1, res1),
                    twoDeviationSquare_
                )
            );

        return
            ABDKMathQuad.mul(
                ABDKMathQuad.mul(
                    ABDKMathQuad.div(ONE, priceDelta),
                    oneDivDeviationSqrtTwoPi_
                ),
                ABDKMathQuad.exp(res2)
            );
    }

    function uint256ToBytes16(uint256 number_, uint256 scale_)
        public
        pure
        returns (bytes16)
    {
        bytes16 number = ABDKMathQuad.fromUInt(number_);
        bytes16 scale = ABDKMathQuad.fromUInt(scale_);

        return ABDKMathQuad.div(number, scale);
    }

    function bytes16ToUnit256(bytes16 number_, uint256 scale_)
        public
        pure
        returns (uint256)
    {
        bytes16 scale = ABDKMathQuad.fromUInt(scale_);

        return ABDKMathQuad.toUInt(ABDKMathQuad.mul(number_, scale));
    }
}
