// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

interface IInterestRateStrategy {
    /**
     * @dev parameters for BAR calculation - they differ depending on bucket's underlying asset
     */
    struct BarCalculationParams {
        uint256 urOptimal;
        uint256 k0;
        uint256 k1;
        uint256 b0;
        int256 b1;
    }

    event BarCalculationParamsChanged(
        address indexed bucket,
        uint256 urOptimal,
        uint256 k0,
        uint256 k1,
        uint256 b0,
        int256 b1
    );

    /**
     * @dev Updates bucket's BAR and LAR.
     * Calculates using utilization ratio (UR):
     * BAR = UR <= URoptimal ? (k0 * UR + b0) : (k1 * UR + b1), where 'b1' may be < 0,
     * LAR = BAR * UR,
     * if reserveRate != 0, then LAR = LAR * (1 - reserveRate)
     * @param ur Utilization ratio
     * @param reserveRate The reserve portion of the interest that goes to the Primex reserve
     * @return tuple containing BAR and LAR
     */

    function calculateInterestRates(uint256 ur, uint256 reserveRate) external returns (uint128, uint128);

    /**
     * @dev Set parameters for BAR calculation.
     * @param _params parameters are represented in byte string
     */

    function setBarCalculationParams(bytes memory _params) external;

    /**
     * @dev Retrieves the calculation parameters for the Bar calculation.
     * @param _address an address of the bucket
     * @return BarCalculationParams struct containing the parameters.
     */
    function getBarCalculationParams(address _address) external view returns (BarCalculationParams memory);
}
