// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./ERC165Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";

import "./IPrimexDNS.sol";
import "./IReserveStorage.sol";

abstract contract ReserveStorage is
    IReserveStorage,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC165Upgradeable
{
    IPrimexDNS internal dns;
    address internal registry;

    // map pToken address to its transfer restrictions
    mapping(address => TransferRestrictions) public override transferRestrictions;
}
