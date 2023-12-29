// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./InterestToken.sol";
import "./DateString.sol";

interface ITrancheFactory {
    function getData()
        external
        returns (
            address,
            uint256,
            InterestToken,
            address
        );
}
