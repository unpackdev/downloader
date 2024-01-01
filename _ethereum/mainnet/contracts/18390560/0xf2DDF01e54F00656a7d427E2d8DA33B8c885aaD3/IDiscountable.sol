// SPDX-License-Identifier: MIT

/// @author Tient Technologies (Twitter:https://twitter.com/tient_tech | Github:https://github.com/Tient-Technologies | LinkedIn:https://www.linkedin.com/company/tient-technologies/)
/// @dev NiceArti (https://github.com/NiceArti)
/// To maintain developer you can also donate to this address - 0xDc3d3fA1aEbd13fF247E5F5D84A08A495b3215FB
/// @title Generalized interface for discounts

pragma solidity ^0.8.18;

interface IDiscountable
{
    /// @dev Interface function for dicounts
    /// @param account address of user
    /// @return tuple of boolean value and uint8
    /// Boolean - returns true if account has discount, false by default
    /// Uint8 - percentage amount of discount (Ex: 20%, 30%), zero by default
    function hasDiscount(address account) external view returns (bool, uint8);
}