//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IPriceFeed.sol";
import "./IEpoch.sol";

interface IGMUOracle is IPriceFeed, IEpoch {
    function updatePrice() external;
}
