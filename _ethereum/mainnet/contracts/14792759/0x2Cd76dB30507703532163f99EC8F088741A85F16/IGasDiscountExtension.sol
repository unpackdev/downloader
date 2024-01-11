// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./IChi.sol";

/// @title Interface for calculating CHI discounts
interface IGasDiscountExtension {
    function calculateGas(
        uint256 gasUsed,
        uint256 flags,
        uint256 calldataLength
    ) external view returns (IChi, uint256);
}
