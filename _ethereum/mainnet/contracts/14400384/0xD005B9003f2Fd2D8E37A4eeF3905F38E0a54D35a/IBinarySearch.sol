// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/// @custom:security-contact lee@rand.network,adr@rand.network
interface IBinarySearch {
    function binarySearch(uint256[] memory _data, uint256 _target)
        external
        returns (uint256);
}
