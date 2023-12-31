// SPDX-License-Identifier: MIT

pragma solidity >=0.6.9 <0.8.0;

import "./LibOrder.sol";
import "./LibOrderData.sol";
import "./LibOrderDataV1.sol";
import "./LibPart.sol";

library LibOrderData {

    function parse(LibOrder.Order memory order) pure internal returns (LibOrderDataV1.DataV1 memory dataOrder) {
        if (order.dataType == LibOrderDataV1.V1) {
            dataOrder = LibOrderDataV1.decodeOrderDataV1(order.data);
            if (dataOrder.payouts.length == 0) {
                dataOrder = payoutSet(order.maker, dataOrder, order.contributors);
            }
        } else if (order.dataType == 0xffffffff) {
            dataOrder = payoutSet(order.maker, dataOrder, order.contributors);
        } else {
            revert("Unknown Order data type");
        }
    }

    function payoutSet(
        address orderAddress,
        LibOrderDataV1.DataV1 memory dataOrderOnePayoutIn,
        LibOrder.Contributor[] memory contributors
    ) pure internal returns (LibOrderDataV1.DataV1 memory) {

        LibPart.Part[] memory payout = new LibPart.Part[](contributors.length + 1);
        uint96 totalShare;
        for (uint256 i = 0; i < contributors.length; i++) {
            payout[i + 1].account = payable(contributors[i].account);
            payout[i + 1].value = contributors[i].value;
            totalShare += contributors[i].value;
        }
        payout[0].account = payable(orderAddress);
        payout[0].value = 10000 - totalShare;
        dataOrderOnePayoutIn.payouts = payout;
        return dataOrderOnePayoutIn;
    }
}
