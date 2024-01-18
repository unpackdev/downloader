// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./ShinikiMarketplaceCore.sol";

contract ShinikiMarketplace is
    ShinikiMarketplaceCore
{
    function initialize(address operator) external initializer {
        __Context_init_unchained();
        __ReentrancyGuard_init_unchained();
        __Pausable_init_unchained();
        __TransferExecutor_init_unchained();
        __TransferManager_init_unchained();
        __OrderValidator_init_unchained();

        TRUSTED_PARTY = 0x7C17B4Ab8d2D4E0233D4ADa4B8e29F3D47Ed5b09;
        isOperators[operator] = true;
    }
}
