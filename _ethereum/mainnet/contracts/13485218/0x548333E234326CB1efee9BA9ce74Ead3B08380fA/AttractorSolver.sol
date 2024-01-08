// SPDX-License-Identifier: UNLICENSED
// Copyright 2021 David Huber (@cxkoda)
// All Rights Reserved

pragma solidity >=0.8.0 <0.9.0;

import "./IAttractorSolver.sol";

/**
 * @notice Base class for attractor simulators.
 * @dev The contract implements some convenient routines shared across
 * different AttractorSolvers.
 * @author David Huber (@cxkoda)
 */
abstract contract AttractorSolver is IAttractorSolver {
    /**
     * @notice The fixed-number precision used throughout this project.
     */
    uint8 public constant PRECISION = 96;
    uint8 internal constant PRECISION_PLUS_1 = 97;
    int256 internal constant ONE = 2**96;

    /**
     * @dev The simulation results (see `AttractorSolution`) will be stored as
     * 16-bit fixed-point values with precision 6. This implies a right shift
     * of internally used (higher-precision) values by 96-6=90.
     * Reducing the width to 16-bit at a precision of 6 futher means that the 
     * left 256-96-10=150 bits of the original (256 bit) number will be dropped.
     */
    uint256 internal constant PRECISION_REDUCTION_SAR = 90;
    uint256 internal constant RANGE_REDUCTION_SHL = 150;

    /**
     * @notice See `IAttractorSolver.getFixedPointPrecision`.
     */
    function getFixedPointPrecision() external pure override returns (uint8) {
        return PRECISION;
    }

    /**
     * @notice See `IAttractorSolver.isValidProjectionParameters`
     * @dev Performs a simple dimensionality check.
     */
    function isValidProjectionParameters(
        ProjectionParameters memory projectionParameters
    ) public pure override returns (bool) {
        return
            (projectionParameters.axis1.length == getDimensionality()) &&
            (projectionParameters.axis2.length == getDimensionality()) &&
            (projectionParameters.offset.length == getDimensionality());
    }

    /**
     * @dev Modifier checking for `isValidProjectionParameters`.
     */
    modifier onlyValidProjectionParameters(
        ProjectionParameters memory projectionParameters
    ) {
        require(
            isValidProjectionParameters(projectionParameters),
            "Invalid Projection Parameters"
        );
        _;
    }

    /**
     * @notice Compute a random number in a given `range` around zero.
     * @dev Computes deterministic PRNs based on a given input `seed`. The
     * values are distributed quasi-equally in the interval `[-range, range]`.
     * @return newSeed To be used in the next function call.
     */
    function _random(uint256 seed, int256 range)
        internal
        pure
        returns (uint256 newSeed, int256 randomNumber)
    {
        newSeed = uint256(keccak256(abi.encode(seed)));
        randomNumber = int256(newSeed);
        assembly {
            randomNumber := sub(mod(newSeed, shl(1, range)), range)
        }
    }

    /**
     * @notice See `IAttractorSolver.getDimensionality`.
     */
    function getDimensionality() public pure virtual override returns (uint8);
}
