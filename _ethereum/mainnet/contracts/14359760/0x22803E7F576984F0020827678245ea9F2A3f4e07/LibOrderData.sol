// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./LibPart.sol";
import "./LibOrder.sol";

library LibOrderData {
    bytes4 constant public ORDER_DATA = bytes4(keccak256("ORDER_DATA"));

    struct Data {
        LibPart.Part[] revenueSplits;
    }

    function decodeOrderData(bytes memory data) internal pure returns (Data memory orderData) {
        orderData = abi.decode(data, (Data));
    }

    function parse(LibOrder.Order memory order) pure internal returns (LibOrderData.Data memory dataOrder) {
        if (order.dataType == ORDER_DATA) {
            dataOrder = decodeOrderData(order.data);
        } else {
            LibOrderData.Data memory _dataOrder;
            dataOrder = _dataOrder;
        }
    }
}
