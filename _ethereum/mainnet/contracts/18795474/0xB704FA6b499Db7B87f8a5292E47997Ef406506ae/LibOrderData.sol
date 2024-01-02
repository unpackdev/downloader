// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;
/* Gambulls LibOrderData 2023 */

import "./LibOrder.sol";
import "./LibPart.sol";

library LibOrderData {
    struct GenericOrderData {
        LibPart.Part[] payouts; // royalty
        LibPart.Part[] originFees; // platformFee
    }

    function parse(bytes memory data) pure internal returns (LibPart.Part[] memory payouts, LibPart.Part[] memory originFees) {
        (payouts, originFees) = abi.decode(data, (LibPart.Part[], LibPart.Part[]));
    }
}
