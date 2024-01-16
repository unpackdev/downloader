// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/// @title ITokenEmissionAdminFacet
/// @author Kfish n Chips
/// @custom:security-contact security@kfishnchips.com
interface ITokenEmissionAdminFacet  {
    error InvalidContractAddress();
    error InvalidBalanceConditionAmount();
    error AddressIsEoA();
}
