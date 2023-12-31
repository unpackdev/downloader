// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// helper methods for interacting with plots on beanstalk
library PodTransferHelper {
    /// @dev get start position and pods amount for sub plot by FMV
    function getPlotSplittedByFMV(
        uint256 originalPods,
        uint256 plotFMV,
        uint256 offsetFMV,
        uint256 requiredFMV
    ) internal pure returns (uint256 start, uint256 amount, uint256 reserveFMV) {
        uint256 tranferFMV;
        ///@dev call when always offsetFMV <= plotFMV
        uint256 availableFMV = plotFMV - offsetFMV;
        if (requiredFMV >= availableFMV) {
            tranferFMV = availableFMV;
            reserveFMV = requiredFMV - tranferFMV;
            if (offsetFMV == 0) {
                /// @dev in that case, tranfer all pods in the plot and avoid unnecessary division by 1
                // ignore this for gas optimization
                // start = 0;
                amount = originalPods;
            }
        } else {
            tranferFMV = requiredFMV;
            // ignore this for gas optimization
            // reserveFMV = 0;
        }
        if (amount == 0) {
            if (offsetFMV != 0) start = (originalPods * offsetFMV) / plotFMV;
            amount = (originalPods * tranferFMV) / plotFMV;
        }
    }

    /// @dev plots can be splitted and we get correct offset of sub plot based on historical split info by senior tranches
    function getPlotWithOffset(
        uint256 plotIndex, //index of plots array, not podIndex
        uint256 originalPods,
        uint256 plotFMV,
        uint256 offsetFMV,
        uint256 requiredFMV,
        uint256 level,
        uint128[6] memory startOffsets
    ) internal pure returns (uint256 offset, uint256 start, uint256 amount, uint256 reserveFMV) {        
        (start, amount, reserveFMV) = getPlotSplittedByFMV(originalPods, plotFMV, offsetFMV, requiredFMV);
        uint256 _level = level;
        // check sub plots splitted by senior tranche level
        // if the sub plot is located in same plot, we start from the plot offset
        while (true) {
            uint256 _offset = startOffsets[_level + 3];
            uint256 _lastPlotIndex = startOffsets[_level];
            if (_offset != 0 && _lastPlotIndex == plotIndex) {
                offset = _offset;
                if (_level == level) start = 0;
                else {
                    unchecked {
                        start -= _offset;
                    }
                }
                break;
            }
            if (_level == 0) break;
            else {
                unchecked {
                    --_level;
                }
            }
        }
    }
}
