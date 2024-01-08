// SPDX-License-Identifier: UNLICENSED
// Copyright 2021 David Huber (@cxkoda)
// All Rights Reserved

pragma solidity >=0.8.0 <0.9.0;

import "./AttractorSolver3D.sol";

/**
 * @notice Pure-Solidity, numerical solution of the chaotic, three-dimensional
 * Halvorsen system of differential equations.
 * @dev This implements all the necessary algorithms needed for the numerical
 * treatment of the equations and the 2D projection of the data. See also
 * `IAttractorSolver` and `AttractorSolver` for more context.
 * @author David Huber (@cxkoda)
 */
contract Halvorsen is AttractorSolver3D {
    /**
     * @notice The parameters of the dynamical system and some handy constants.
     * @dev Unfortunately, we have to write them out to be usable in inline
     * assembly. The occasionally added, negligible term is to make the number
     * dividable without rest - otherwise there will be conversion issues.
     */
    int256 private constant ALPHA = (14 * 2**96 - 4) / 10;
    int256 private constant FOUR = 4 * 2**96;

    // -------------------------
    //
    //  Base Interface
    //
    // -------------------------

    /**
     * @notice See `IAttractorSolver.getSystemType`.
     */
    function getSystemType() public pure override returns (string memory) {
        return "Halvorsen";
    }

    /**
     * @notice See `IAttractorSolver.getSystemType`.
     * @dev The random range was manually tuned such that the system consistenly
     * reaches the attractor.
     */
    function getRandomStartingPoint(uint256 randomSeed)
        external
        view
        virtual
        override
        returns (StartingPoint memory startingPoint)
    {
        startingPoint.startingPoint = new int256[](DIM);
        int256 randNumber;
        int256 range = ONE;

        (randomSeed, randNumber) = _random(randomSeed, range);
        startingPoint.startingPoint[0] = -5 * ONE + randNumber;

        (randomSeed, randNumber) = _random(randomSeed, range);
        startingPoint.startingPoint[1] = ONE + randNumber;

        (randomSeed, randNumber) = _random(randomSeed, range);
        startingPoint.startingPoint[2] = ONE + randNumber;
    }

    /**
     * @notice See `AttractorSolver3D._getDefaultProjectionScale`.
     */
    function _getDefaultProjectionScale()
        internal
        pure
        override
        returns (int256)
    {
        return 4*ONE;
    }

    /**
     * @notice See `AttractorSolver3D._getDefaultProjectionOffset`.
     */
    function _getDefaultProjectionOffset()
        internal
        pure
        override
        returns (int256[] memory offset)
    {
        offset = new int256[](DIM);
        offset[0] = -5 * ONE;
        offset[1] = -5 * ONE;
        offset[2] = -5 * ONE;
    }

    // -------------------------
    //
    //  Number Crunching
    //
    // -------------------------

    /**
     * @dev The following the heart-piece of every attractor solver.
     * Here the system of ODEs (in the form `u' = f(u)`) will be solved
     * numerically using the explicit, classical Runge-Kutta 4 method (aka RK4).
     * Such a high order scheme is needed to maintain numerical stability while
     * reducing the amount of timesteps needed to obtain a solution for the
     * considered systems. Before storing the results, points and tangents are
     * projected to 2D.
     * Warning: The returns are given as fixed-point numbers with reduced
     * precision (6) and width (16 bit). See `AttractorSolution` and
     * `AttractorSolver`.
     * @return points contains every `skip` point of the numerical solution. It
     * includes the starting point at the first position.
     * @return tangents contains the tangents (i.e. the ODEs RHS) at the
     * position of `points`.
     */
    function _solve(
        SolverParameters memory solverParameters,
        StartingPoint3D memory startingPoint,
        ProjectionParameters3D memory projectionParameters
    )
        internal
        pure
        override
        returns (bytes memory points, bytes memory tangents)
    {
        // Some handy aliases
        uint256 numberOfIterations = solverParameters.numberOfIterations;
        uint256 dt = solverParameters.dt;
        uint8 skip = solverParameters.skip;

        assembly {
            // Allocate space for the results
            // 2 bytes (16-bit) * 2 coordinates * amount of pairs in storage
            let length := mul(4, add(1, div(numberOfIterations, skip)))

            function allocate(size_) -> ptr {
                // Get free memory pointer
                ptr := mload(0x40)
                // Set allocation length
                mstore(ptr, size_)

                // Actually allocate 2 * 32B more:
                // Dynamic array length info (32B) and some free buffer space at
                // the end (such that we can safely write over array boundaries)
                mstore(0x40, add(ptr, add(size_, 0x40)))
            }
            points := allocate(length)
            tangents := allocate(length)
        }

        // Temporary space to store the current point and tangent
        int256[DIM] memory point = startingPoint.startingPoint;
        int256[DIM] memory tangent;

        // Temporary space for the weighted sum of intermediate RHS evaluations
        // needed for Runge-Kutta schemes.
        int256[DIM] memory rhsSum;

        // Parental Advisory: Explicit Yul Content
        // You and people around you may be exposed to content that you find
        // objectionable and/or offensive.
        // All stunts were performed by trained professionals, don't try this
        // at home. The producer of this code is not responsible for any
        // personal injury or damage.
        assembly {
            /**
             * @notice Reduce accuracy and range of number and stores it in a
             * buffer.
             * @dev Used to store simulation results in `points` and `tangents`
             *  as pairs of 16-bit numbers in row-major order. See also
             * `AttractorSolution`.
             */
            function storeData(bufferPos_, x_, y_) -> newBufferPos {
                // First we reduce the accuracy of the x coordinate for storing.
                // This not necessary for y because we will overwrite the extra
                // bits later anyways.
                x_ := sar(PRECISION_REDUCTION_SAR, x_)

                // Stack both numbers together, shift them all the way
                // to the left and write them to the buffer directly as 32B
                // chunks to save gas.
                // Because this operation could easily write over buffer
                // bounds, we added some extra space at the end earlier.
                mstore(
                    bufferPos_,
                    or(shl(240, x_), shr(16, shl(RANGE_REDUCTION_SHL, y_)))
                )

                newBufferPos := add(bufferPos_, 4)
            }

            /**
             * @notice Compute the projected x-coordinate of a 3D point.
             * @dev It implements the linear algebra calculation
             * `parameters_.axis1 * (point_ - parameters_.offset)`,
             * with `*` being the scalar product.
             */
            function projectPointX(point_, parameters_) -> x {
                let axis1 := mload(parameters_)
                let offset_ := mload(add(parameters_, 0x40))
                {
                    let component := sub(mload(point_), mload(offset_))
                    x := mul(component, mload(axis1))
                }
                {
                    let component := sub(
                        mload(add(point_, 0x20)),
                        mload(add(offset_, 0x20))
                    )
                    x := add(x, mul(component, mload(add(axis1, 0x20))))
                }
                {
                    let component := sub(
                        mload(add(point_, 0x40)),
                        mload(add(offset_, 0x40))
                    )
                    x := add(x, mul(component, mload(add(axis1, 0x40))))
                }
                x := sar(PRECISION, x)
            }

            /**
             * @notice Compute the projected y-coordinate of a 3D point.
             * @dev It implements the linear algebra calculation
             * `parameters_.axis2 * (point_ - parameters_.offset)`,
             * with `*` being the scalar product.
             */
            function projectPointY(point_, parameters_) -> y {
                let axis2 := mload(add(parameters_, 0x20))
                let offset_ := mload(add(parameters_, 0x40))
                {
                    let component := sub(mload(point_), mload(offset_))
                    y := mul(component, mload(axis2))
                }
                {
                    let component := sub(
                        mload(add(point_, 0x20)),
                        mload(add(offset_, 0x20))
                    )
                    y := add(y, mul(component, mload(add(axis2, 0x20))))
                }
                {
                    let component := sub(
                        mload(add(point_, 0x40)),
                        mload(add(offset_, 0x40))
                    )
                    y := add(y, mul(component, mload(add(axis2, 0x40))))
                }
                y := sar(PRECISION, y)
            }

            /**
             * @notice Compute the projected x-coordinate of a 3D tangent.
             * @dev It implements the linear algebra calculation
             * `parameters_.axis1 * point_`, with `*` being the scalar product.
             * The offset must not to be considered for directions.
             */
            function projectDirectionX(direction, parameters_) -> x {
                let axis1 := mload(parameters_)
                let offset_ := mload(add(parameters_, 0x40))
                x := mul(mload(direction), mload(axis1))
                x := add(
                    x,
                    mul(mload(add(direction, 0x20)), mload(add(axis1, 0x20)))
                )
                x := add(
                    x,
                    mul(mload(add(direction, 0x40)), mload(add(axis1, 0x40)))
                )
                x := sar(PRECISION, x)
            }

            /**
             * @notice Compute the projected y-coordinate of a 3D tangent.
             * @dev It implements the linear algebra calculation
             * `parameters_.axis2 * point_`, with `*` being the scalar product.
             * The offset must not to be considered for directions.
             */
            function projectDirectionY(direction, parameters_) -> y {
                let axis2 := mload(add(parameters_, 0x20))
                let offset_ := mload(add(parameters_, 0x40))
                y := mul(mload(direction), mload(axis2))
                y := add(
                    y,
                    mul(mload(add(direction, 0x20)), mload(add(axis2, 0x20)))
                )
                y := add(
                    y,
                    mul(mload(add(direction, 0x40)), mload(add(axis2, 0x40)))
                )
                y := sar(PRECISION, y)
            }

            // -------------------------
            //
            //  The actual work
            //
            // -------------------------

            // Store the starting point
            {
                let x := projectPointX(point, projectionParameters)
                let y := projectPointY(point, projectionParameters)
                let tmp := storeData(add(points, 0x20), x, y)
            }

            // A frequently used value in the RK4 scheme
            let dtSixth := div(dt, 6)

            // Rolling pointers to the current location in the output buffers
            let posPoints := add(points, 0x24)
            let posTangents := add(tangents, 0x20)

            // Loop over the amount of timesteps that need to be done
            for {
                let iter := 0
            } lt(iter, numberOfIterations) {
                iter := add(iter, 1)
            } {
                // The following updates the system's state by performing
                // as single time step according to the RK4 scheme. It is
                // generally used to solve systems of ODEs in the form of
                // `u' = f(u)`, where `f` is aka right-hand-side (rhs).
                //
                // The scheme can be summarized as follows:
                // rhs0 = f(uOld)
                // rhs1 = f(uOld + dt/2 * rhs0)
                // rhs2 = f(uOld + dt/2 * rhs1)
                // rhs3 = f(uOld + dt * rhs2)
                // rhsSum = rhs0 + 2 * rhs1 + 2 * rhs2 + rhs3
                // uNew = uOld + dt/6 * rhsSum
                //
                // A lot of code is repeatedly inlined for better efficiency.
                {
                    // Compute intermediate steps and weighted rhs sum
                    {
                        let dxdt
                        let dydt
                        let dzdt

                        // RK4 intermediate step 0
                        {
                            // Load the current point aka `uOld`.
                            let x := mload(point)
                            let y := mload(add(point, 0x20))
                            let z := mload(add(point, 0x40))

                            // Compute the rhs for the current intermediate step
                            // x' = a x - 4 y - 4 z - y**2
                            dxdt := sar(
                                PRECISION,
                                sub(
                                    0,
                                    add(
                                        add(
                                            mul(ALPHA, x),
                                            mul(add(FOUR, y), y)
                                        ),
                                        mul(FOUR, z)
                                    )
                                )
                            )

                            // y' = a y - 4 z - 4 x - y**2
                            dydt := sar(
                                PRECISION,
                                sub(
                                    0,
                                    add(
                                        add(
                                            mul(ALPHA, y),
                                            mul(add(FOUR, z), z)
                                        ),
                                        mul(FOUR, x)
                                    )
                                )
                            )

                            // z' = a z - 4 x - 4 y - x**2
                            dzdt := sar(
                                PRECISION,
                                sub(
                                    0,
                                    add(
                                        add(
                                            mul(ALPHA, z),
                                            mul(add(FOUR, x), x)
                                        ),
                                        mul(FOUR, y)
                                    )
                                )
                            )

                            // Initialise the `rhsSum` with the current `rhs0`
                            mstore(rhsSum, dxdt)
                            mstore(add(rhsSum, 0x20), dydt)
                            mstore(add(rhsSum, 0x40), dzdt)

                            // Since the rhs f(uOld) will be used to compute a
                            // tangent later, we'll store it here to prevent
                            // an unnecessay recompuation.
                            mstore(tangent, dxdt)
                            mstore(add(tangent, 0x20), dydt)
                            mstore(add(tangent, 0x40), dzdt)
                        }

                        // RK4 intermediate step 1
                        {
                            // Load the current point aka `uOld`.
                            let x := mload(point)
                            let y := mload(add(point, 0x20))
                            let z := mload(add(point, 0x40))

                            // Compute the current intermediate state.
                            // Precision + 1 for dt / 2
                            x := add(x, sar(PRECISION_PLUS_1, mul(dxdt, dt)))
                            y := add(y, sar(PRECISION_PLUS_1, mul(dydt, dt)))
                            z := add(z, sar(PRECISION_PLUS_1, mul(dzdt, dt)))

                            // Compute the rhs for the current intermediate step
                            // x' = a x - 4 y - 4 z - y**2
                            dxdt := sar(
                                PRECISION,
                                sub(
                                    0,
                                    add(
                                        add(
                                            mul(ALPHA, x),
                                            mul(add(FOUR, y), y)
                                        ),
                                        mul(FOUR, z)
                                    )
                                )
                            )

                            // y' = a y - 4 z - 4 x - y**2
                            dydt := sar(
                                PRECISION,
                                sub(
                                    0,
                                    add(
                                        add(
                                            mul(ALPHA, y),
                                            mul(add(FOUR, z), z)
                                        ),
                                        mul(FOUR, x)
                                    )
                                )
                            )

                            // z' = a z - 4 x - 4 y - x**2
                            dzdt := sar(
                                PRECISION,
                                sub(
                                    0,
                                    add(
                                        add(
                                            mul(ALPHA, z),
                                            mul(add(FOUR, x), x)
                                        ),
                                        mul(FOUR, y)
                                    )
                                )
                            )

                            // Add `rhs1` to the `rhsSum`.
                            // shl for adding it twice.
                            mstore(rhsSum, add(mload(rhsSum), shl(1, dxdt)))
                            mstore(
                                add(rhsSum, 0x20),
                                add(mload(add(rhsSum, 0x20)), shl(1, dydt))
                            )
                            mstore(
                                add(rhsSum, 0x40),
                                add(mload(add(rhsSum, 0x40)), shl(1, dzdt))
                            )
                        }

                        // RK4 intermediate step 2
                        {
                            // Load the current point aka `uOld`.
                            let x := mload(point)
                            let y := mload(add(point, 0x20))
                            let z := mload(add(point, 0x40))

                            // Compute the current intermediate state.
                            // Precision + 1 for dt / 2
                            x := add(x, sar(PRECISION_PLUS_1, mul(dxdt, dt)))
                            y := add(y, sar(PRECISION_PLUS_1, mul(dydt, dt)))
                            z := add(z, sar(PRECISION_PLUS_1, mul(dzdt, dt)))

                            // Compute the rhs for the current intermediate step
                            // x' = a x - 4 y - 4 z - y**2
                            dxdt := sar(
                                PRECISION,
                                sub(
                                    0,
                                    add(
                                        add(
                                            mul(ALPHA, x),
                                            mul(add(FOUR, y), y)
                                        ),
                                        mul(FOUR, z)
                                    )
                                )
                            )

                            // y' = a y - 4 z - 4 x - y**2
                            dydt := sar(
                                PRECISION,
                                sub(
                                    0,
                                    add(
                                        add(
                                            mul(ALPHA, y),
                                            mul(add(FOUR, z), z)
                                        ),
                                        mul(FOUR, x)
                                    )
                                )
                            )

                            // z' = a z - 4 x - 4 y - x**2
                            dzdt := sar(
                                PRECISION,
                                sub(
                                    0,
                                    add(
                                        add(
                                            mul(ALPHA, z),
                                            mul(add(FOUR, x), x)
                                        ),
                                        mul(FOUR, y)
                                    )
                                )
                            )

                            // Add `rhs2` to the `rhsSum`.
                            // shl for adding it twice.
                            mstore(rhsSum, add(mload(rhsSum), shl(1, dxdt)))
                            mstore(
                                add(rhsSum, 0x20),
                                add(mload(add(rhsSum, 0x20)), shl(1, dydt))
                            )
                            mstore(
                                add(rhsSum, 0x40),
                                add(mload(add(rhsSum, 0x40)), shl(1, dzdt))
                            )
                        }

                        // RK4 intermediate step 3
                        {
                            // Load the current point aka `uOld`.
                            let x := mload(point)
                            let y := mload(add(point, 0x20))
                            let z := mload(add(point, 0x40))

                            // Compute the current intermediate state.
                            x := add(x, sar(PRECISION, mul(dxdt, dt)))
                            y := add(y, sar(PRECISION, mul(dydt, dt)))
                            z := add(z, sar(PRECISION, mul(dzdt, dt)))

                            // Compute the rhs for the current intermediate step
                            // x' = a x - 4 y - 4 z - y**2
                            dxdt := sar(
                                PRECISION,
                                sub(
                                    0,
                                    add(
                                        add(
                                            mul(ALPHA, x),
                                            mul(add(FOUR, y), y)
                                        ),
                                        mul(FOUR, z)
                                    )
                                )
                            )

                            // y' = a y - 4 z - 4 x - y**2
                            dydt := sar(
                                PRECISION,
                                sub(
                                    0,
                                    add(
                                        add(
                                            mul(ALPHA, y),
                                            mul(add(FOUR, z), z)
                                        ),
                                        mul(FOUR, x)
                                    )
                                )
                            )

                            // z' = a z - 4 x - 4 y - x**2
                            dzdt := sar(
                                PRECISION,
                                sub(
                                    0,
                                    add(
                                        add(
                                            mul(ALPHA, z),
                                            mul(add(FOUR, x), x)
                                        ),
                                        mul(FOUR, y)
                                    )
                                )
                            )

                            // Add `rhs3` to the `rhsSum`.
                            mstore(rhsSum, add(mload(rhsSum), dxdt))
                            mstore(
                                add(rhsSum, 0x20),
                                add(mload(add(rhsSum, 0x20)), dydt)
                            )
                            mstore(
                                add(rhsSum, 0x40),
                                add(mload(add(rhsSum, 0x40)), dzdt)
                            )
                        }
                    }

                    // Compute the new point aka `uNew`.
                    {
                        // Load the current point aka `uOld`.
                        let x := mload(point)
                        let y := mload(add(point, 0x20))
                        let z := mload(add(point, 0x40))

                        // Compute `uNew = dt/6 * rhsSum`
                        x := add(x, sar(PRECISION, mul(mload(rhsSum), dtSixth)))
                        y := add(
                            y,
                            sar(
                                PRECISION,
                                mul(mload(add(rhsSum, 0x20)), dtSixth)
                            )
                        )
                        z := add(
                            z,
                            sar(
                                PRECISION,
                                mul(mload(add(rhsSum, 0x40)), dtSixth)
                            )
                        )

                        // Update the point / state of the system.
                        mstore(point, x)
                        mstore(add(point, 0x20), y)
                        mstore(add(point, 0x40), z)
                    }
                }

                // Check if we are at a step where we have to store the point
                // to the results.
                if eq(addmod(iter, 1, skip), 0) {
                    // If so, project and store the 2D data
                    let x := projectPointX(point, projectionParameters)
                    let y := projectPointY(point, projectionParameters)
                    posPoints := storeData(posPoints, x, y)
                }

                // Check if we are at a step where we have to store the tangent
                // to the results. This is not the same as for points since
                // tangents corresponds to `f(uOld)`. The two are seperated by
                // one iteration.
                if eq(mod(iter, skip), 0) {
                    // Tangent will be used by renders to generate cubic Bezier
                    // curves. Following the rhs by `dtTangent = skip * dt / 3`
                    // yields optimal results for this.
                    let dtTangent := shl(1, mul(dtSixth, skip))

                    let x := sar(
                        PRECISION,
                        mul(
                            dtTangent,
                            projectDirectionX(tangent, projectionParameters)
                        )
                    )
                    let y := sar(
                        PRECISION,
                        mul(
                            dtTangent,
                            projectDirectionY(tangent, projectionParameters)
                        )
                    )
                    posTangents := storeData(posTangents, x, y)
                }
            }

            // Using a `skip` that divides `numberOfIterations` without rest
            // results in tangents being one entry short at the end.
            // Let's compute and add this one manually.
            if eq(mod(numberOfIterations, skip), 0) {
                {
                    let dxdt
                    let dydt
                    let dzdt

                    // Compute the tangent aka in analogy to the in the 0th
                    // intermediate step of the RK4 scheme
                    // I am sure you know the drill by now.
                    {
                        let x := mload(point)
                        let y := mload(add(point, 0x20))
                        let z := mload(add(point, 0x40))

                        // x' = a x - 4 y - 4 z - y**2
                        dxdt := sar(
                            PRECISION,
                            sub(
                                0,
                                add(
                                    add(mul(ALPHA, x), mul(add(FOUR, y), y)),
                                    mul(FOUR, z)
                                )
                            )
                        )

                        // y' = a y - 4 z - 4 x - y**2
                        dydt := sar(
                            PRECISION,
                            sub(
                                0,
                                add(
                                    add(mul(ALPHA, y), mul(add(FOUR, z), z)),
                                    mul(FOUR, x)
                                )
                            )
                        )

                        // z' = a z - 4 x - 4 y - x**2
                        dzdt := sar(
                            PRECISION,
                            sub(
                                0,
                                add(
                                    add(mul(ALPHA, z), mul(add(FOUR, x), x)),
                                    mul(FOUR, y)
                                )
                            )
                        )

                        mstore(tangent, dxdt)
                        mstore(add(tangent, 0x20), dydt)
                        mstore(add(tangent, 0x40), dzdt)
                    }

                    // Project and store the tangent. Same as at the end of the
                    // main loop, see above.
                    {
                        let dtTangent := shl(1, mul(dtSixth, skip))

                        let x := sar(
                            PRECISION,
                            mul(
                                dtTangent,
                                projectDirectionX(tangent, projectionParameters)
                            )
                        )
                        let y := sar(
                            PRECISION,
                            mul(
                                dtTangent,
                                projectDirectionY(tangent, projectionParameters)
                            )
                        )
                        posTangents := storeData(posTangents, x, y)
                    }
                }
            }
        }
    }
}
