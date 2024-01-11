// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;


library LibTrade {
    bytes32 constant _ORDER_TYPEHASH = 0x287d88810c333c982eb76bb0816bf9f46aed64f1f5378d80081fbfdc7928ab5e;

    uint constant CodeIdxSignature = 7;
    uint constant CodeIdxPrice = 6;
    uint constant CodeIdxAskFilled = 5;
    uint constant CodeIdxBidFilled = 4;
    uint constant CodeIdxAskCost = 3;
    uint constant CodeIdxBidCost = 2;
    uint constant CodeIdxAskBalance = 1;
    uint constant CodeIdxBidBalance = 0;

    /// @dev code [signature|price|ask.fill|bid.fill|ask.cost|bid.cost|ask.available|bid.available]
    struct Acceptance {
        uint mid;
        uint code;
        uint[3] askTransfers;
        uint[3] bidTransfers;
    }

    struct Order {
        address account;
        address tokenIn;
        address tokenOut;
        uint amount;
        uint lprice;
    }

    struct OrderPacked {
        uint id;
        address account;
        uint amount;
        uint lprice;
        bytes sig;
    }

    struct MatchExecution {
        uint mid;
        address base;
        address quote;
        OrderPacked ask;
        OrderPacked bid;
        uint amount;
        uint price;
        uint priceN;
        uint reserve;
        bool unwrap;
    }

    function recover(MatchExecution memory exec, bytes32 domainSeparator) internal pure returns (bool) {
        Order memory ask = Order(exec.ask.account, exec.base, exec.quote, exec.ask.amount, exec.ask.lprice);
        Order memory bid = Order(exec.bid.account, exec.quote, exec.base, exec.bid.amount, exec.bid.lprice);
        return recoverOrder(ask, domainSeparator, exec.ask.sig) && recoverOrder(bid, domainSeparator, exec.bid.sig);
    }

    function recoverOrder(Order memory order, bytes32 domainSeparator, bytes memory signature) private pure returns (bool) {
        require(signature.length == 65, "invalid signature length");

        bytes32 structHash;
        bytes32 orderDigest;

        // Order struct (5 fields) and type hash (5 + 1) * 32 = 192
        assembly {
            let dataStart := sub(order, 32)
            let temp := mload(dataStart)
            mstore(dataStart, _ORDER_TYPEHASH)
            structHash := keccak256(dataStart, 192)
            mstore(dataStart, temp)
        }

        assembly {
            let freeMemoryPointer := mload(0x40)
            mstore(freeMemoryPointer, "\x19\x01")
            mstore(add(freeMemoryPointer, 2), domainSeparator)
            mstore(add(freeMemoryPointer, 34), structHash)
            orderDigest := keccak256(freeMemoryPointer, 66)
        }

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "invalid signature 's' value");

        address signer;

        if (v > 30) {
            require(v - 4 == 27 || v - 4 == 28, "invalid signature 'v' value");
            signer = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", orderDigest)), v - 4, r, s);
        } else {
            require(v == 27 || v == 28, "invalid signature 'v' value");
            signer = ecrecover(orderDigest, v, r, s);
        }
        return signer != address(0) && signer == order.account;
    }
}
