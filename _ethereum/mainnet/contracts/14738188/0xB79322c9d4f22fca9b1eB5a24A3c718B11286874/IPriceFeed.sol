// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IPriceFeed {

    // --- Events ---
    event LastGoodPriceUpdated(uint _lastGoodPrice);
   
    // --- Function ---
    function fetchPrice() external returns (uint);

    // Getter for the last good price seen from an oracle by Liquity
    function lastGoodPrice() external view returns (uint);

}
