// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

library DubiexLib {
    enum CurrencyType {NULL, ETH, ERC20, BOOSTABLE_ERC20, ERC721}

    // Enum is used to read only a specific part of the order pair from
    // storage, since it is a bad idea to always perform 4 SLOADs.
    enum OrderPairReadStrategy {SKIP, MAKER, TAKER, FULL}

    struct OrderPair {
        address makerContractAddress;
        CurrencyType makerCurrencyType;
        address takerContractAddress;
        CurrencyType takerCurrencyType;
    }

    // To reduce the number of reads, the order pairs
    // are stored packed and on read unpacked as required.
    // Also see `OrderPair` and `OrderPairReadStrategy`.
    struct PackedOrderPair {
        // 20 bytes address + 1 byte currency type
        uint168 makerPair;
        // 20 bytes address + 1 byte currency type
        uint168 takerPair;
    }

    struct PackedOrderBookItem {
        // Serialized `UnpackedOrderBookItem`
        uint256 packedData;
        //
        // Mostly zero
        //
        uint32 successorOrderId;
        uint32 ancestorOrderId;
    }

    struct UnpackedOrderBookItem {
        uint32 id;
        uint96 makerValue;
        uint96 takerValue;
        uint32 orderPairAlias;
        // The resolved pair based on the order pair alias
        OrderPair pair;
        OrderFlags flags;
    }

    // Struct that contains all unpacked data and the additional almost-always zero fields from
    // the packed order bookt item - returned from `getOrder()` to be more user-friendly to consume.
    struct PrettyOrderBookItem {
        uint32 id;
        uint96 makerValue;
        uint96 takerValue;
        uint32 orderPairAlias;
        OrderPair pair;
        OrderFlags flags;
        uint32 successorOrderId;
        uint32 ancestorOrderId;
    }

    struct OrderFlags {
        bool isMakerERC721;
        bool isTakerERC721;
        bool isHidden;
        bool hasSuccessor;
    }

    function packOrderBookItem(UnpackedOrderBookItem memory _unpacked)
        internal
        pure
        returns (uint256)
    {
        // Bitpacking saves gas on read/write:

        // 61287 gas
        // struct Item1 {
        //     uint256 word1;
        //     uint256 word2;
        // }

        // // 62198 gas
        // struct Item2 {
        //     uint256 word1;
        //     uint128 a;
        //     uint128 b;
        // }

        // // 62374 gas
        // struct Item3 {
        //     uint256 word1;
        //     uint64 a;
        //     uint64 b;
        //     uint64 c;
        //     uint64 d;
        // }

        uint256 packedData;
        uint256 offset;

        // 1) Set first 32 bits to id
        uint32 id = _unpacked.id;
        packedData |= id;
        offset += 32;

        // 2) Set next 96 bits to maker value
        uint96 makerValue = _unpacked.makerValue;
        packedData |= uint256(makerValue) << offset;
        offset += 96;

        // 3) Set next 96 bits to taker value
        uint96 takerValue = _unpacked.takerValue;
        packedData |= uint256(takerValue) << offset;
        offset += 96;

        // 4) Set next 28 bits to order pair alias
        // Since it is stored in a uint32 AND it with a bitmask where the first 28 bits are 1
        uint32 orderPairAlias = _unpacked.orderPairAlias;
        uint32 orderPairAliasMask = (1 << 28) - 1;
        packedData |= uint256(orderPairAlias & orderPairAliasMask) << offset;
        offset += 28;

        // 5) Set remaining bits to flags
        OrderFlags memory flags = _unpacked.flags;
        if (flags.isMakerERC721) {
            // Maker currency type is ERC721
            packedData |= 1 << (offset + 0);
        }

        if (flags.isTakerERC721) {
            // Taker currency type is ERC721
            packedData |= 1 << (offset + 1);
        }

        if (flags.isHidden) {
            // Order is hidden
            packedData |= 1 << (offset + 2);
        }

        if (flags.hasSuccessor) {
            // Order has a successor
            packedData |= 1 << (offset + 3);
        }

        offset += 4;

        assert(offset == 256);
        return packedData;
    }

    function unpackOrderBookItem(uint256 packedData)
        internal
        pure
        returns (UnpackedOrderBookItem memory)
    {
        UnpackedOrderBookItem memory _unpacked;
        uint256 offset;

        // 1) Read id from the first 32 bits
        _unpacked.id = uint32(packedData >> offset);
        offset += 32;

        // 2) Read maker value from next 96 bits
        _unpacked.makerValue = uint96(packedData >> offset);
        offset += 96;

        // 3) Read taker value from next 96 bits
        _unpacked.takerValue = uint96(packedData >> offset);
        offset += 96;

        // 4) Read order pair alias from next 28 bits
        uint32 orderPairAlias = uint32(packedData >> offset);
        uint32 orderPairAliasMask = (1 << 28) - 1;
        _unpacked.orderPairAlias = orderPairAlias & orderPairAliasMask;
        offset += 28;

        // NOTE: the caller still needs to read the order pair from storage
        // with the unpacked alias

        // 5) Read order flags from remaining bits
        OrderFlags memory flags = _unpacked.flags;

        flags.isMakerERC721 = (packedData >> (offset + 0)) & 1 == 1;
        flags.isTakerERC721 = (packedData >> (offset + 1)) & 1 == 1;
        flags.isHidden = (packedData >> (offset + 2)) & 1 == 1;
        flags.hasSuccessor = (packedData >> (offset + 3)) & 1 == 1;

        offset += 4;

        assert(offset == 256);

        return _unpacked;
    }

    function packOrderPair(OrderPair memory unpacked)
        internal
        pure
        returns (PackedOrderPair memory)
    {
        uint168 packedMaker = uint160(unpacked.makerContractAddress);
        packedMaker |= uint168(unpacked.makerCurrencyType) << 160;

        uint168 packedTaker = uint160(unpacked.takerContractAddress);
        packedTaker |= uint168(unpacked.takerCurrencyType) << 160;

        return PackedOrderPair(packedMaker, packedTaker);
    }

    function unpackOrderPairAddressType(uint168 packed)
        internal
        pure
        returns (address, CurrencyType)
    {
        // The first 20 bytes of order pair are used for the maker address
        address unpackedAddress = address(packed);
        // The next 8 bits for the maker currency type
        CurrencyType unpackedCurrencyType = CurrencyType(uint8(packed >> 160));

        return (unpackedAddress, unpackedCurrencyType);
    }

    /**
     * @dev A struct representing the payload of `makeOrder`.
     */
    struct MakeOrderInput {
        uint96 makerValue;
        uint96 takerValue;
        OrderPair pair;
        // An id of an existing order can be optionally provided to
        // update the makerValue-takerValue ratio with a single call as opposed to cancel-then-make-new-order.
        uint32 orderId;
        // If specified, this order becomes a successor for the ancestor order and will be hidden until
        // the ancestor has been filled.
        uint32 ancestorOrderId;
        // When calling make order using an existing order id, the `updatedRatio` will be applied on
        // the `makerValue` to calculate the new `takerValue`.
        uint128 updatedRatioWei;
    }

    /**
     * @dev A struct representing the payload of `takeOrder`.
     */
    struct TakeOrderInput {
        uint32 id;
        address payable maker;
        uint96 takerValue;
        // The expected max taker maker ratio of the order to take.
        uint256 maxTakerMakerRatio;
    }

    /**
     * @dev A struct representing the payload of `cancelOrder`.
     */
    struct CancelOrderInput {
        uint32 id;
        address payable maker;
    }
}
