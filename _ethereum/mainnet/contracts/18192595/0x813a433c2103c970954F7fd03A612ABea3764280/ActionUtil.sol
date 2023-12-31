// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./constants.sol";
import "./enums.sol";
import "./types.sol";

/**
 * @title libraries to encode action arguments
 */
library ActionUtil {
    function concat(ActionArgs[] memory x, ActionArgs[] memory v) internal pure returns (ActionArgs[] memory y) {
        y = new ActionArgs[](x.length + v.length);
        uint256 z;
        uint256 i;
        for (i; i < x.length;) {
            y[z] = x[i];
            unchecked {
                ++z;
                ++i;
            }
        }
        for (i = 0; i < v.length;) {
            y[z] = v[i];
            unchecked {
                ++z;
                ++i;
            }
        }
    }

    function append(ActionArgs[] memory x, ActionArgs memory v) internal pure returns (ActionArgs[] memory y) {
        y = new ActionArgs[](x.length + 1);
        uint256 i;
        for (i; i < x.length;) {
            y[i] = x[i];
            unchecked {
                ++i;
            }
        }
        y[i] = v;
    }

    function append(BatchExecute[] memory x, BatchExecute memory v) internal pure returns (BatchExecute[] memory y) {
        y = new BatchExecute[](x.length + 1);
        uint256 i;
        for (i; i < x.length;) {
            y[i] = x[i];
            unchecked {
                ++i;
            }
        }
        y[i] = v;
    }

    // add a function prefixed with test here so forge coverage will ignore this file
    function testChillOnHelper() public {}
}
