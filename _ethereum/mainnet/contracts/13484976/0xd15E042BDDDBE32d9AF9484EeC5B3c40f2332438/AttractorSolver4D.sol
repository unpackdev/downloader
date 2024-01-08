// SPDX-License-Identifier: UNLICENSED
// Copyright 2021 David Huber (@cxkoda)
// All Rights Reserved

pragma solidity >=0.8.0 <0.9.0;

import "./AttractorSolver.sol";
import "./MathHelpers.sol";

/**
 * @notice Base class for four-dimensional attractor simulators.
 * @dev Partial specialisation of `AttractorSolver` for four-dimensional
 * systems.
 * @author David Huber (@cxkoda)
 */
abstract contract AttractorSolver4D is AttractorSolver {
    uint8 internal constant DIM = 4;

    /**
     * @notice Four-dimensional starting point (see `StartingPoint`).
     * @dev This type will be used internally for the 3D solvers.
     */
    struct StartingPoint4D {
        int256[DIM] startingPoint;
    }

    /**
     * @notice Four-dimensional projection parameters point (see
     * `ProjectionParameters`).
     * @dev This type will be used internally for the 3D solvers.
     */
    struct ProjectionParameters4D {
        int256[DIM] axis1;
        int256[DIM] axis2;
        int256[DIM] offset;
    }

    /**
     * @notice See `IAttractorSolver.getDimensionality`.
     */
    function getDimensionality() public pure virtual override returns (uint8) {
        return DIM;
    }

    /**
     * @notice Converts dynamic to static arrays.
     * @dev Converts only arrays with length `DIM`
     */
    function _convertDynamicToStaticArray(int256[] memory input)
        internal
        pure
        returns (int256[DIM] memory output)
    {
        require(input.length == DIM);
        for (uint256 dim = 0; dim < DIM; ++dim) {
            output[dim] = input[dim];
        }
    }

    /**
     * @notice Converts dynamic to static arrays.
     * @dev Only applicable to arrays with length `DIM`
     */
    function _parseStartingPoint(StartingPoint memory startingPoint_)
        internal
        pure
        returns (StartingPoint4D memory startingPoint)
    {
        startingPoint.startingPoint = _convertDynamicToStaticArray(
            startingPoint_.startingPoint
        );
    }

    /**
     * @dev Converts dynamical length projections parameters to static ones
     * for internal use.
     */
    function _parseProjectionParameters(
        ProjectionParameters memory projectionParameters_
    )
        internal
        pure
        returns (ProjectionParameters4D memory projectionParameters)
    {
        require(isValidProjectionParameters(projectionParameters_));
        projectionParameters.axis1 = _convertDynamicToStaticArray(
            projectionParameters_.axis1
        );
        projectionParameters.axis2 = _convertDynamicToStaticArray(
            projectionParameters_.axis2
        );
        projectionParameters.offset = _convertDynamicToStaticArray(
            projectionParameters_.offset
        );
    }

    /**
     * @notice See `IAttractorSolver.getDefaultProjectionParameters`.
     * @dev The implementation relies on spherical Fibonacci lattices from
     * `MathHelpers` to compute the direction of the axes. Their normalisation
     * and offset is delegated to specialisations of `_getDefaultProjectionScale`
     * and `_getDefaultProjectionOffset` depending on the system.
     */
    function getDefaultProjectionParameters(uint256 editionId)
        external
        view
        virtual
        override
        returns (ProjectionParameters memory projectionParameters)
    {
        projectionParameters.offset = _getDefaultProjectionOffset();

        projectionParameters.axis1 = new int256[](DIM);
        projectionParameters.axis2 = new int256[](DIM);

        // Make some chaos
        uint256 fiboIdx = ((editionId / 4) * 7 + 13) % 32;

        (int256[3] memory axis1, int256[3] memory axis2) = MathHelpers
            .getFibonacciSphericalAxes(fiboIdx, 32);

        int256 scale = _getDefaultProjectionScale();
        // Apply length and store back
        for (uint8 dim; dim < 3; dim++) {
            uint256 coord = dim + editionId;
            projectionParameters.axis1[coord % DIM] = (scale * axis1[dim])/ONE;
            projectionParameters.axis2[coord % DIM] = (scale * axis2[dim])/ONE;
        }
    }

    /**
     * @notice See `IAttractorSolver.computeSolution`.
     */
    function computeSolution(
        SolverParameters calldata solverParameters,
        StartingPoint calldata startingPoint,
        ProjectionParameters calldata projectionParameters
    )
        external
        pure
        override
        onlyValidProjectionParameters(projectionParameters)
        returns (AttractorSolution memory solution)
    {
        // Delegate and repack the solution
        (solution.points, solution.tangents) = _solve(
            solverParameters,
            _parseStartingPoint(startingPoint),
            _parseProjectionParameters(projectionParameters)
        );
        // Compute the timestep between points in the output considering that
        // not all simulated points will be stored.
        solution.dt = solverParameters.dt * solverParameters.skip;
    }

    /**
     * @dev The simulaton routine to be implemented for the individual systems.
     * This intermediate interface was introduced to make variables more
     * easility accessibly in assembly code.
     */
    function _solve(
        SolverParameters memory solverParameters,
        StartingPoint4D memory startingPoint,
        ProjectionParameters4D memory projectionParameters
    )
        internal
        pure
        virtual
        returns (bytes memory points, bytes memory tangents);

    /**
     * @dev Retuns the default length of the projection axes for the
     * respective system.
     * Attention: Here we use integers instead of fixed-point numbers for
     * simplicity.
     */
    function _getDefaultProjectionScale()
        internal
        pure
        virtual
        returns (int256);

    /**
     * @dev Returns the default offset of the projection for the respective
     * system.
     */
    function _getDefaultProjectionOffset()
        internal
        pure
        virtual
        returns (int256[] memory);
}
