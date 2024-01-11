// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract IFlowerFamAffliliate {
    function affiliateKickback() external returns (uint256) {}

    function affiliatePercentage() external returns (uint256) {}

    function registerAffiliate(address affiliate, uint256 earned) external {}

    function setUserRegistered(address user) external {}

    function affiliateRegistration(address user) external returns (bool) {}
}
