// SPDX-License-Identifier: MIT
// Creator: twitter.com/0xNox_ETH

pragma solidity ^0.8.19;

interface IEnhancement {
    function restore(address driverOwner, uint256 enhancementId) external returns (bool);

    function use(address driverOwner, uint256 enhancementId) external returns (bool);
}
