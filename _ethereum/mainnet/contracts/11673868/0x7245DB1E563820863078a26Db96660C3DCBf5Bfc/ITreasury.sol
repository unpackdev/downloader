// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ITreasury {
    function epoch() external view returns (uint256);
    
    function nextEpochPoint() external view returns (uint256);

    function getDollarPrice() external view returns (uint256);
}
