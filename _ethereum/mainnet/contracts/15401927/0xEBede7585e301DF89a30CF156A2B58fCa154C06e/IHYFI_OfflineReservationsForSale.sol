// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.12;

interface IHYFI_OfflineReservationsForSale {
    function getBuyers() external view returns (address[] memory);

    function getBuyerReservedAmount(address user)
        external
        view
        returns (uint256);
}
