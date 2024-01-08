/*
    Copyright 2021 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "./Decimal.sol";

/**
 * @title TimeUtils
 * @notice Library that accompanies Decimal to convert unix time into Decimal.D256 values
 */
library TimeUtils {
    /**
     * @notice Number of seconds in a single day
     */
    uint256 private constant SECONDS_IN_DAY = 86400;

    /**
     * @notice Converts an integer number of seconds to a Decimal.D256 amount of days
     * @param s Number of seconds to convert
     * @return Equivalent amount of days as a Decimal.D256
     */
    function secondsToDays(uint256 s) internal pure returns (Decimal.D256 memory) {
        return Decimal.ratio(s, SECONDS_IN_DAY);
    }
}
