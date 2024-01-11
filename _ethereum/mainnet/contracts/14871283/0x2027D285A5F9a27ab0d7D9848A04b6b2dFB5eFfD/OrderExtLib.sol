// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AssetLib.sol";
import "./PartLib.sol";

library OrderExtLib {
    bytes4 public constant VERSION = bytes4(keccak256("V1"));

    bytes32 constant ORDER_EXT_TYPEHASH =
        keccak256(
            "OrderExtData(bytes4 version,address forwarder,PartData[] payouts,PartData[] fees)PartData(address account,uint256 value)"
        );

    struct OrderExtData {
        bytes4 version;
        address forwarder;
        PartLib.PartData[] payouts;
        PartLib.PartData[] fees;
    }

    function hash(OrderExtData memory orderExt)
        internal
        pure
        returns (bytes32)
    {
        bytes32[] memory payoutsBytes = new bytes32[](orderExt.payouts.length);
        for (uint256 i = 0; i < orderExt.payouts.length; i++) {
            payoutsBytes[i] = PartLib.hash(orderExt.payouts[i]);
        }
        bytes32[] memory feesBytes = new bytes32[](orderExt.fees.length);
        for (uint256 i = 0; i < orderExt.fees.length; i++) {
            feesBytes[i] = PartLib.hash(orderExt.fees[i]);
        }
        return
            keccak256(
                abi.encode(
                    ORDER_EXT_TYPEHASH,
                    orderExt.version,
                    orderExt.forwarder,
                    keccak256(abi.encodePacked(payoutsBytes)),
                    keccak256(abi.encodePacked(feesBytes))
                )
            );
    }

    function decodeOrderExtData(bytes memory data)
        internal
        pure
        returns (OrderExtData memory)
    {
        return abi.decode(data, (OrderExtData));
    }

    function validate(OrderExtData memory orderExt)
        internal
        pure
        returns (bool, string memory)
    {
        if (orderExt.version != VERSION) {
            return (false, "OrderExtLib: version validation failed");
        } else if (orderExt.payouts.length == 0) {
            return (false, "OrderExtLib: payouts validation failed");
        }
        return (true, "");
    }
}
