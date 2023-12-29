// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Order.sol";
import "./Signature.sol";
import "./BytesLib.sol";
import "./IERC1271.sol";

abstract contract BebopSigning {

    event OrderSignerRegistered(address maker, address signer, bool allowed);

    bytes32 private constant DOMAIN_NAME = keccak256("BebopSettlement");
    bytes32 private constant DOMAIN_VERSION = keccak256("1");

    bytes4 private constant EIP1271_MAGICVALUE = bytes4(keccak256("isValidSignature(bytes32,bytes)"));

    uint256 private constant ETH_SIGN_HASH_PREFIX = 0x19457468657265756d205369676e6564204d6573736167653a0a333200000000;

    bytes32 public constant EIP712_DOMAIN_TYPEHASH = keccak256(abi.encodePacked(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    ));

    bytes32 public constant AGGREGATED_ORDER_TYPE_HASH = keccak256(abi.encodePacked(
        "Aggregate(uint256 expiry,address taker_address,address[] maker_addresses,uint256[] maker_nonces,address[][] taker_tokens,address[][] maker_tokens,uint256[][] taker_amounts,uint256[][] maker_amounts,address receiver,bytes commands)"
    ));

    bytes32 public constant PARTIAL_AGGREGATED_ORDER_TYPE_HASH = keccak256(abi.encodePacked(
        "Partial(uint256 expiry,address taker_address,address maker_address,uint256 maker_nonce,address[] taker_tokens,address[] maker_tokens,uint256[] taker_amounts,uint256[] maker_amounts,address receiver,bytes commands)"
    ));

    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    mapping(address => mapping(uint256 => uint256)) private maker_validator;
    mapping(address => mapping(address => bool)) private orderSignerRegistry;

    constructor(){
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = keccak256(
            abi.encode(EIP712_DOMAIN_TYPEHASH, DOMAIN_NAME, DOMAIN_VERSION, block.chainid, address(this))
        );
    }

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return block.chainid == _CACHED_CHAIN_ID
            ? _CACHED_DOMAIN_SEPARATOR
            : keccak256(
                abi.encode(EIP712_DOMAIN_TYPEHASH, DOMAIN_NAME, DOMAIN_VERSION, block.chainid, address(this))
            );
    }

    function hashAggregateOrder(Order.Aggregate memory order) public view returns (bytes32) {
        return
        keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        AGGREGATED_ORDER_TYPE_HASH,
                        order.expiry,
                        order.taker_address,
                        keccak256(abi.encodePacked(order.maker_addresses)),
                        keccak256(abi.encodePacked(order.maker_nonces)),
                        keccak256(encodeTightlyPackedNested(order.taker_tokens)),
                        keccak256(encodeTightlyPackedNested(order.maker_tokens)),
                        keccak256(encodeTightlyPackedNestedInt(order.taker_amounts)),
                        keccak256(encodeTightlyPackedNestedInt(order.maker_amounts)),
                        order.receiver,
                        keccak256(order.commands)
                    )
                )
            )
        );
    }

    function hashPartialOrder(Order.Partial memory order) public view returns (bytes32) {
        return
        keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        PARTIAL_AGGREGATED_ORDER_TYPE_HASH,
                        order.expiry,
                        order.taker_address,
                        order.maker_address,
                        order.maker_nonce,
                        keccak256(abi.encodePacked(order.taker_tokens)),
                        keccak256(abi.encodePacked(order.maker_tokens)),
                        keccak256(abi.encodePacked(order.taker_amounts)),
                        keccak256(abi.encodePacked(order.maker_amounts)),
                        order.receiver,
                        keccak256(order.commands)
                    )
                )
            )
        );
    }

    function registerAllowedOrderSigner(address signer, bool allowed) external {
        orderSignerRegistry[msg.sender][signer] = allowed;
        emit OrderSignerRegistered(msg.sender, signer, allowed);
    }

    function validateSignature(
        address validationAddress,
        bytes32 hash,
        Signature.TypedSignature memory signature,
        bool isMaker
    ) public view {
        if (signature.signatureType == Signature.Type.EIP712) {
            // Signed using EIP712
            (bytes32 r, bytes32 s, uint8 v) = Signature.getRsv(signature.signatureBytes);
            address signer = ecrecover(hash, v, r, s);
            require(signer != address(0), "Invalid signer");
            if (signer != validationAddress && (!isMaker || !orderSignerRegistry[validationAddress][signer])) {
                revert("Invalid EIP712 order signature");
            }
        } else if (signature.signatureType == Signature.Type.EIP1271) {
            require(
                IERC1271(validationAddress).isValidSignature(hash, signature.signatureBytes) == EIP1271_MAGICVALUE,
                "Invalid EIP1271 order signature"
            );
        } else if (signature.signatureType == Signature.Type.ETHSIGN) {
            bytes32 ethSignHash;
            assembly {
                mstore(0, ETH_SIGN_HASH_PREFIX) // length of 28 bytes
                mstore(28, hash) // length of 32 bytes
                ethSignHash := keccak256(0, 60)
            }
            (bytes32 r, bytes32 s, uint8 v) = Signature.getRsv(signature.signatureBytes);
            address signer = ecrecover(ethSignHash, v, r, s);
            require(signer != address(0), "Invalid signer");
            if (signer != validationAddress && (!isMaker || !orderSignerRegistry[validationAddress][signer])) {
                revert("Invalid ETHSIGH order signature");
            }
        } else {
            revert("Invalid Signature Type");
        }
    }

    function encodeTightlyPackedNestedInt(uint256[][] memory _nested_array) private pure returns (bytes memory encoded) {
        uint nested_array_length = _nested_array.length;
        for (uint i = 0; i < nested_array_length; i++) {
            encoded = abi.encodePacked(
                encoded,
                keccak256(abi.encodePacked(_nested_array[i]))
            );
        }
        return encoded;
    }

    function encodeTightlyPackedNested(address[][] memory _nested_array) private pure returns (bytes memory encoded) {
        uint nested_array_length = _nested_array.length;
        for (uint i = 0; i < nested_array_length; i++) {
            encoded = abi.encodePacked(
                encoded,
                keccak256(abi.encodePacked(_nested_array[i]))
            );
        }
        return encoded;
    }

    function invalidateOrder(address maker, uint256 nonce) private {
        require(nonce != 0, "Nonce must be non-zero");
        uint256 invalidatorSlot = nonce >> 8;
        uint256 invalidatorBit = 1 << (nonce & 0xff);
        mapping(uint256 => uint256) storage invalidatorStorage = maker_validator[maker];
        uint256 invalidator = invalidatorStorage[invalidatorSlot];
        require(invalidator & invalidatorBit != invalidatorBit, "Invalid maker order (nonce)");
        invalidatorStorage[invalidatorSlot] = invalidator | invalidatorBit;
    }

    function assertAndInvalidateMakerOrders(
        Order.Aggregate memory order,
        Signature.MakerSignatures[] memory makerSigs
    ) private {
        // number of columns = number of sigs otherwise unwarranted columns can be injected by sender.
        require(order.taker_tokens.length == makerSigs.length, "Taker tokens length mismatch");
        require(order.maker_tokens.length == makerSigs.length, "Maker tokens length mismatch");
        require(order.taker_amounts.length == makerSigs.length, "Taker amounts length mismatch");
        require(order.maker_amounts.length == makerSigs.length, "Maker amounts length mismatch");
        require(order.maker_nonces.length == makerSigs.length, "Maker nonces length mismatch");
        require(order.maker_addresses.length == makerSigs.length, "Maker addresses length mismatch");
        uint numMakerSigs = makerSigs.length;
        uint tokenTransfers;
        for (uint256 i; i < numMakerSigs; ++i) {
            // validate the partially signed orders.
            address maker_address = order.maker_addresses[i];
            require(order.maker_tokens[i].length == order.maker_amounts[i].length, "Maker tokens and amounts length mismatch");
            require(order.taker_tokens[i].length == order.taker_amounts[i].length, "Taker tokens and amounts length mismatch");
            Order.Partial memory partial_order = Order.Partial(
                order.expiry,
                order.taker_address,
                maker_address,
                order.maker_nonces[i],
                order.taker_tokens[i],
                order.maker_tokens[i],
                order.taker_amounts[i],
                order.maker_amounts[i],
                order.receiver,
                BytesLib.slice(
                    order.commands, tokenTransfers, order.maker_tokens[i].length + order.taker_tokens[i].length
                )
            );
            validateSignature(maker_address, hashPartialOrder(partial_order), makerSigs[i].signature, true);
            invalidateOrder(maker_address, order.maker_nonces[i]);
            tokenTransfers += order.maker_tokens[i].length + order.taker_tokens[i].length;
        }
        require(tokenTransfers == order.commands.length, "Token transfers length mismatch");
    }

    function assertAndInvalidateAggregateOrder(
        Order.Aggregate memory order,
        Signature.TypedSignature memory takerSig,
        Signature.MakerSignatures[] memory makerSigs
    ) internal returns (bytes32) {
        bytes32 h = hashAggregateOrder(order);
        if (msg.sender != order.taker_address){
            validateSignature(order.taker_address, h, takerSig, false);
        }

        // construct and validate maker partial orders
        assertAndInvalidateMakerOrders(order, makerSigs);

        require(order.expiry > block.timestamp, "Signature expired");
        return h;
    }
}
