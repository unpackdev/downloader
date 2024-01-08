// SPDX-License-Identifier: UNLICENSED
// Copyright 2021 David Huber (@cxkoda)
// All Rights Reserved

pragma solidity >=0.8.0 <0.9.0;

import "./ISvgRenderer.sol";
import "./DynamicBufferAllocator.sol";
import "./Strings.sol";

/**
 * @notice Implementation of `ISvgRenderer` based on cubic bezier curves.
 * @dev The following unsafe characters will be % encoded in the resulting svg
 * because the target use-case will be data-uris.
 * <    %3C
 * >    %3E
 * #    %23
 * %	%25
 * See also https://codepen.io/tigt/post/optimizing-svgs-in-data-uris
 * @author David Huber (@cxkoda)
 */
contract LineRenderer is ISvgRenderer, DynamicBufferAllocator {
    uint256 private constant skipBytes = 0x04;

    /**
     * @dev Implementation of `ISvgRenderer.render` rendering cubic bezier lines.
     * Points will determing the l
     * The basic idea for assembling the svg is to group line segments with the
     * same color and add them to the same path svg element. In the end we will
     * therefore have 256 path elements.
     */
    function render(
        AttractorSolution calldata solution,
        bytes memory colormap,
        uint8 strokeWidth
    ) public pure override returns (string memory svg) {
        require(colormap.length == 768);

        // Allocate buffer which we will later use to build up the svg
        {
            // 188B svg init/close + 75B per path + ~24B per point
            uint256 bufferSize = 188 +
                256 *
                75 +
                (solution.points.length / 4 + 256) *
                24;
            (, bytes memory _svg) = _allocate(bufferSize);

            // Let's use a little trick here and use the allocated bytes buffer
            // for strings
            assembly {
                svg := _svg
            }
        }

        // Preparing some (repeatedly used) svg fragments.
        // They cannot be stored in individual variables -> stack too deep
        bytes[5] memory collection = [
            // 0x00
            bytes(
                "%3Csvg width='1024' height='1024' viewBox='-4096 -4096 8192 8192' xmlns='http://www.w3.org/2000/svg'%3E%3Crect x='-4096' y='-4096' width='100%25' height='100%25' fill='black'/%3E"
            ),
            // 0x20
            bytes("%3Cpath d='M "),
            // 0x40
            abi.encodePacked(
                "' stroke-width='",
                Strings.toString(strokeWidth),
                "' stroke='%23"
            ),
            // 0x60
            bytes("' fill='transparent'/%3E"),
            // 0x80
            bytes("%3C/svg%3E")
        ];

        // Some handy aliases
        bytes memory points = solution.points;
        bytes memory tangents = solution.tangents;

        assembly {
            /**
             * @notice Append data to a dynamic buffer.
             * See `DynamicBufferAllocator`.
             * @dev Adds `data_` at the end of the `buffer_` and increases
             * the length of the latter accordingly.
             * Warning! Container capacity checks were neglected for performance.
             */
            function appendBytes(buffer_, data_) {
                let length := mload(data_)
                for {
                    let data := add(data_, 32)
                    let dataEnd := add(data, length)
                    let buf := add(buffer_, add(mload(buffer_), 32))
                } lt(data, dataEnd) {
                    data := add(data, 32)
                    buf := add(buf, 32)
                } {
                    // Copy 32B chunks from data to buffer.
                    // This may read over data array boundaries and copy invalid
                    // bytes, which doesn't matter in the end since we will
                    // later set the correct buffer length.
                    mstore(buf, mload(data))
                }

                // Update buffer length
                mstore(buffer_, add(mload(buffer_), length))
            }

            /**
             * @notice Append a single byte to a dynamic buffer.
             * See `DynamicBufferAllocator`.
             * @dev Adds `data_` at the end of the `buffer_` and increases
             * the length of the latter by one.
             * Warning! Container capacity checks were neglected for performance.
             */
            function appendByte(buffer_, data) {
                let length := mload(buffer_)
                let buffer := add(buffer_, add(length, 32))
                mstore8(buffer, data)
                mstore(buffer_, add(length, 1))
            }

            /**
             * @notice Convert an `int16` to its ASCII `byte` representation
             * @dev `value_` is converted and append it to `buffer_`.
             * See `DynamicBufferAllocator`.
             * Warning! Container capacity checks were neglected for performance.
             */
            function appendConvertedInt256(buffer_, value_) {
                // Init a local 32B buffer for the ascii string.
                // This is more than enough for the numbers we are dealing with
                let ascii := 0

                // A counter for the amount of characters in ascii.
                let numCharacters := 0

                // Check if `value_` is negative.
                let negative := slt(value_, 0)

                // If so we need to add a minus sign later and continue with
                // the absolute value in the meantime.
                if negative {
                    // Compute and assign the abs value.
                    let tmp := sar(255, value_)
                    value_ := sub(xor(value_, tmp), tmp)
                }

                // We treat `ascii` as byte string, meaning that we will fill it
                // from left to right. To build up the ascii string we start go
                // from the lowest to the highest decimal place.
                for {
                    let temp := value_
                } gt(temp, 0) {
                    // Divide number by 10 until nothing more is left.
                    temp := div(temp, 10)
                } {
                    // Read the following from the inside out.

                    // Prepend the new digit to the string
                    ascii := or(
                        shr(8, ascii),
                        // Shift it all the way to the left 256-8
                        shl(
                            248,
                            // Digits start at ascii code 48
                            add(48, mod(temp, 10))
                        )
                    )

                    numCharacters := add(numCharacters, 1)
                }

                // If `value_` was zero, the previous code will do nothing.
                // Add zero manually in this case.
                if eq(numCharacters, 0) {
                    ascii := shl(248, 48)
                    numCharacters := 1
                }

                // If `value_` was negative we need to prepend a minus.
                if negative {
                    ascii := or(shr(8, ascii), shl(248, 45)) // minus = ascii 45
                    numCharacters := add(numCharacters, 1)
                }

                // Append the `ascii` string to the `buffer_`.
                let bufferSize := mload(buffer_)
                let bufferStart := add(add(buffer_, 0x20), bufferSize)

                mstore(bufferStart, ascii)

                // Update length of the `buffer_`.
                mstore(buffer_, add(bufferSize, numCharacters))
            }

            /**
             * @notice Converts an RGB color to its HEX string
             * @param colormap Array of 256 8-bit RGB colors
             * @param idx Position of the color in the array to be converted
             * Warning! Container capacity checks were neglected for performance.
             */
            function appendColor(buffer_, colormap_, idx_) {
                // Load the color from the colormap
                // and shift to get rid of excess bits
                let color := shr(
                    232,
                    mload(add(add(colormap_, 0x20), mul(3, idx_)))
                )

                // We will build up the hex string from right to left.
                // The final string will always have length 6, we therefore
                // already know at which `bufferPos` we have to start.
                for {
                    let iter := 0
                    let bufferPos := add(
                        add(buffer_, 0x20),
                        add(mload(buffer_), 5)
                    )
                } lt(iter, 6) {
                    iter := add(iter, 1)
                    bufferPos := sub(bufferPos, 1)
                    color := shr(4, color)
                } {
                    // In each iteration we convert the last 4 bits of the
                    // `color` to ascii hex. For the next iteration, we shift
                    // those 4 bits out and start again.

                    let lastDigit := and(color, 0xf)

                    // Check if the character will be a number (or letter)
                    let numeric := lt(lastDigit, 0xa)

                    // Set the according character
                    if not(numeric) {
                        mstore8(bufferPos, add(87, lastDigit))
                    }
                    if numeric {
                        mstore8(bufferPos, add(48, lastDigit))
                    }
                }

                // Update the buffer length.
                mstore(buffer_, add(mload(buffer_), 6))
            }

            /**
             * @notice Appends a point and its right tangent (parallel to the
             * direction of the curve) to the svg.
             * @dev This routine is used only right after opening a new svg
             * path element. It will append `<x> <y> C <x+dx> <y+dy>`.
             * Warning! Container capacity checks were neglected for performance.
             */
            function appendPointAndRightTangent(posPoint, posTangent, svg_) {
                // Load the point from memory.
                let x
                let y
                {
                    // For this we read 256bit and shift away the ones that
                    // we don't need.
                    let tmp := mload(posPoint)
                    x := sar(240, tmp)
                    // Invert sign on y, due to svg coordinate layout.
                    y := sub(0, sar(240, shl(16, tmp)))
                }

                appendConvertedInt256(svg_, x)
                appendByte(svg_, 32) // space
                appendConvertedInt256(svg_, y)

                // Load the slopes from memory (same as above).
                let dx
                let dy
                {
                    let tmp := mload(posTangent)
                    dx := sar(240, tmp)
                    dy := sub(0, sar(240, shl(16, tmp)))
                }

                // Add slopes to the point to get the right tangent
                dx := add(x, dx)
                dy := add(y, dy)

                appendByte(svg_, 67) // C (svg curveto)

                appendConvertedInt256(svg_, dx)
                appendByte(svg_, 32) // space
                appendConvertedInt256(svg_, dy)
            }

            /**
             * @notice Appends a point and its left tangent (anti-parallel to
             * the direction of the curve) to the svg.
             * @dev This routine is used to add all remaining points to an open
             * svg path element. It will append `<x-dx> <y-dy>, <x> <y>`.
             * Warning! Container capacity checks were neglected for performance.
             */
            function appendLeftTangentAndPoint(posPoint, posTangent, svg_) {
                // Load the point from memory.
                let x
                let y
                {
                    // For this we read 256bit and shift away the ones that
                    // we don't need.
                    let tmp := mload(posPoint)
                    x := sar(240, tmp)
                    // Invert sign on y, due to svg coordinate layout.
                    y := sub(0, sar(240, shl(16, tmp)))
                }

                {
                    // Load the slopes from memory (same as above).
                    let dx
                    let dy
                    {
                        let tmp := mload(posTangent)
                        dx := sar(240, tmp)
                        dy := sub(0, sar(240, shl(16, tmp)))
                    }

                    // Add slopes to the point to get the left tangent
                    dx := sub(x, dx)
                    dy := sub(y, dy)

                    appendConvertedInt256(svg_, dx)
                    appendByte(svg_, 32) // space
                    appendConvertedInt256(svg_, dy)
                    appendByte(svg_, 44) // comma
                }

                appendConvertedInt256(svg_, x)
                appendByte(svg_, 32) // space
                appendConvertedInt256(svg_, y)
            }

            // -------------------------
            //
            //  The actual work.
            //
            // -------------------------

            // Append svg init (<svg ..) to the buffer
            appendBytes(svg, mload(collection))

            // Compute the amount of points with the same color
            let nSameCol := div(mload(points), mul(skipBytes, 256))

            // The outer loop iterates over colors (0-255).
            for {
                let colorIdx := 0
                let posPoint := add(points, 0x20)
                let posTangent := add(tangents, 0x20)
            } lt(colorIdx, 256) {
                colorIdx := add(colorIdx, 1)
            } {
                let iter := 0

                appendBytes(svg, mload(add(collection, 0x20))) // Path init
                appendPointAndRightTangent(posPoint, posTangent, svg)

                iter := add(iter, 1)
                posPoint := add(posPoint, skipBytes)
                posTangent := add(posTangent, skipBytes)

                appendByte(svg, 44) // ,
                appendLeftTangentAndPoint(posPoint, posTangent, svg)

                // The inner loop iterates over points with the same color
                for {

                } lt(iter, nSameCol) {

                } {
                    iter := add(iter, 1)
                    posPoint := add(posPoint, skipBytes)
                    posTangent := add(posTangent, skipBytes)

                    appendByte(svg, 83) // S (svg smooth curveto)
                    appendLeftTangentAndPoint(posPoint, posTangent, svg)
                }

                appendBytes(svg, mload(add(collection, 0x40))) // Path midpart
                appendColor(svg, colormap, colorIdx)
                appendBytes(svg, mload(add(collection, 0x60))) // Path end
            }

            appendBytes(svg, mload(add(collection, 0x80))) // Svg end
        }
    }
}
