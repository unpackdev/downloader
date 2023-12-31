// SPDX-License-Identifier: MIT
/**
 _____
/  __ \
| /  \/ ___  _ ____   _____ _ __ __ _  ___ _ __   ___ ___
| |    / _ \| '_ \ \ / / _ \ '__/ _` |/ _ \ '_ \ / __/ _ \
| \__/\ (_) | | | \ V /  __/ | | (_| |  __/ | | | (_|  __/
 \____/\___/|_| |_|\_/ \___|_|  \__, |\___|_| |_|\___\___|
                                 __/ |
                                |___/
 */
pragma solidity ^0.8.0;
import "./ABDKMathQuad.sol";

contract BondCalculator {
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;

    uint256 public constant TEN_POWER_6 = 10 ** 6;

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                            TIME RATIO
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */
    /**
     * @notice Compute the time ratio representing the progression on a bonding round => t/T in bytes16
     * @param durationFromStart time in (s) since the creation of the bond
     * @param totalDuration     expiry duration of the bond
     * @return timeRatio t/T
     */
    function computeTimeRatio(uint256 durationFromStart, uint256 totalDuration) internal pure returns (bytes16) {
        return ABDKMathQuad.fromUInt(durationFromStart).div(ABDKMathQuad.fromUInt(totalDuration));
    }

    function computeTimeRatioUInt(uint256 durationFromStart, uint256 totalDuration) public pure returns (uint256) {
        return
            ABDKMathQuad.toUInt(
                computeTimeRatio(durationFromStart, totalDuration).mul(
                    ABDKMathQuad.fromUInt(TEN_POWER_6) //10**6 TO GET PRECISION: 0.26 => 260000
                )
            );
    }

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                            CVG EXPECTED
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */

    /**
     *  @notice Compute the expected CVG minted at this moment
     *  @param durationFromStart of the computation
     *  @param totalDuration     start time of the bonding contract
     *  @param composedFunction  bonding computation type => sqrt, ², ln
     *  @param totalOutToken     maxCvg that can be minted by the bonding contract
     *  @return cvgExpected is the number of CVG that are expected to be minted through the bond
     */
    function computeCvgExpected(
        uint256 durationFromStart,
        uint256 totalDuration,
        uint256 composedFunction,
        uint256 totalOutToken
    ) internal pure returns (bytes16 cvgExpected) {
        bytes16 timeRatio = computeTimeRatio(durationFromStart, totalDuration);

        if (composedFunction == 0) {
            cvgExpected = ABDKMathQuad.sqrt(timeRatio);
        } else if (composedFunction == 1) {
            cvgExpected = ABDKMathQuad
                .ln(timeRatio)
                .div(ABDKMathQuad.ln(ABDKMathQuad.fromUInt(totalOutToken).div(ABDKMathQuad.fromUInt(10 ** 18))))
                .add(ABDKMathQuad.fromUInt(1));
            cvgExpected = ABDKMathQuad.toInt(cvgExpected) < 0 ? ABDKMathQuad.fromUInt(0) : cvgExpected;
        } else if (composedFunction == 2) {
            cvgExpected = timeRatio.mul(timeRatio);
        } else {
            cvgExpected = timeRatio;
        }
        cvgExpected = cvgExpected.mul(ABDKMathQuad.fromUInt(totalOutToken));
        //10**6 TO GET PRECISION: 0.26 => 260000
    }

    /**
     *  @notice Compute the expected CVG minted at this moment
     *  @return ntrNtcRatio uint256
     */
    function computeCvgExpectedUInt(
        uint256 durationFromStart,
        uint256 totalDuration,
        uint256 composedFunction,
        uint256 maxCvgToMint
    ) public pure returns (uint256) {
        return
            ABDKMathQuad.toUInt(computeCvgExpected(durationFromStart, totalDuration, composedFunction, maxCvgToMint));
    }

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                        RATIO REAL EXPECTED
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */

    /**
     * @notice Compute the time ratio representing the progression on a bonding round => t/T in bytes16
     * @param durationFromStart time in (s) since the creation of the bond
     * @param totalDuration     total duration in (s) of the bond
     * @param composedFunction  bonding computation type => sqrt, ², ln
     * @param totalOutToken     maxCvg that will be minted by the bonding contract
     * @param soldTokenOut      cvg amount already sold since the beginning of the bond
     * @return ntrNtcRatio uint256
     */
    function computeNtrDivNtc(
        uint256 durationFromStart,
        uint256 totalDuration,
        uint256 composedFunction,
        uint256 totalOutToken,
        uint256 soldTokenOut
    ) external pure returns (uint256) {
        bytes16 cvgExpectedOnActualRound = computeCvgExpected(
            durationFromStart,
            totalDuration,
            composedFunction,
            totalOutToken
        );
        return
            ABDKMathQuad.toInt(cvgExpectedOnActualRound) == 0
                ? 0
                : ABDKMathQuad.toUInt(ABDKMathQuad.fromUInt(soldTokenOut * TEN_POWER_6).div(cvgExpectedOnActualRound));
    }

    /**
     *  @notice Compute Number of TokenReal/TokenExpected
     *  @return ntrNtcRatio uint256
     */
    function _computeNtrDivNtc(
        uint256 durationFromStart,
        uint256 totalDuration,
        uint256 composedFunction,
        uint256 totalOutToken,
        uint256 soldTokenOut
    ) internal pure returns (uint256) {
        bytes16 cvgExpectedOnActualRound = computeCvgExpected(
            durationFromStart,
            totalDuration,
            composedFunction,
            totalOutToken
        );
        return
            ABDKMathQuad.toInt(cvgExpectedOnActualRound) == 0
                ? 0
                : ABDKMathQuad.toUInt(ABDKMathQuad.fromUInt(soldTokenOut * TEN_POWER_6).div(cvgExpectedOnActualRound));
    }

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                        ROI COMPUTATION
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */

    /**
     * @notice Compute the time ratio representing the progression on a bonding round => t/T in bytes16
     * @param durationFromStart time in (s) since the creation of the bond
     * @param totalDuration     total duration in (s) of the bond
     * @param composedFunction  bonding computation type => sqrt, ², ln
     * @param totalOutToken     maxCvg that will be minted by the bonding contract
     * @param amountTokenSold   cvg amount already sold since the beginning of the bond
     * @param gamma             variable dividing the NTR/NTB.
     * @param scale             % that is removed on the ROI each time the intRange increases
     * @param minRoi            minimum ROI that the bond allows
     * @param maxRoi            maximum ROI that the bond allows
     * @return roi uint256
     */
    function computeRoi(
        uint256 durationFromStart,
        uint256 totalDuration,
        uint256 composedFunction,
        uint256 totalOutToken,
        uint256 amountTokenSold,
        uint256 gamma,
        uint256 scale,
        uint256 minRoi,
        uint256 maxRoi
    ) external pure returns (uint256) {
        uint256 percentageReduction = (_computeNtrDivNtc(
            durationFromStart,
            totalDuration,
            composedFunction,
            totalOutToken,
            amountTokenSold
        ) / gamma) * scale; // euclidean division here, we keep only the full number 4.8888 => 4

        if (percentageReduction >= (maxRoi - minRoi)) {
            return minRoi;
        } else {
            return maxRoi - percentageReduction;
        }
    }
}
