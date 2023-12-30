// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./EIP712Boostable.sol";
import "./DubiexLib.sol";

/**
 * @dev Dubiex Boostable primitives following the EIP712 standard
 */
abstract contract Boostable is EIP712Boostable {
    bytes32 private constant BOOSTED_MAKE_ORDER_TYPEHASH = keccak256(
        "BoostedMakeOrder(MakeOrderInput input,address maker,BoosterFuel fuel,BoosterPayload boosterPayload)BoosterFuel(uint96 dubi,uint96 unlockedPrps,uint96 lockedPrps,uint96 intrinsicFuel)BoosterPayload(address booster,uint64 timestamp,uint64 nonce,bool isLegacySignature)MakeOrderInput(uint96 makerValue,uint96 takerValue,OrderPair pair,uint32 orderId,uint32 ancestorOrderId,uint128 updatedRatioWei)OrderPair(address makerContractAddress,address takerContractAddress,uint8 makerCurrencyType,uint8 takerCurrencyType)"
    );

    bytes32 private constant BOOSTED_TAKE_ORDER_TYPEHASH = keccak256(
        "BoostedTakeOrder(TakeOrderInput input,address taker,BoosterFuel fuel,BoosterPayload boosterPayload)BoosterFuel(uint96 dubi,uint96 unlockedPrps,uint96 lockedPrps,uint96 intrinsicFuel)BoosterPayload(address booster,uint64 timestamp,uint64 nonce,bool isLegacySignature)TakeOrderInput(uint32 id,address maker,uint96 takerValue,uint256 maxTakerMakerRatio)"
    );

    bytes32 private constant BOOSTED_CANCEL_ORDER_TYPEHASH = keccak256(
        "BoostedCancelOrder(CancelOrderInput input,BoosterFuel fuel,BoosterPayload boosterPayload)BoosterFuel(uint96 dubi,uint96 unlockedPrps,uint96 lockedPrps,uint96 intrinsicFuel)BoosterPayload(address booster,uint64 timestamp,uint64 nonce,bool isLegacySignature)CancelOrderInput(uint32 id,address maker)"
    );

    bytes32 private constant MAKE_ORDER_INPUT_TYPEHASH = keccak256(
        "MakeOrderInput(uint96 makerValue,uint96 takerValue,OrderPair pair,uint32 orderId,uint32 ancestorOrderId,uint128 updatedRatioWei)OrderPair(address makerContractAddress,address takerContractAddress,uint8 makerCurrencyType,uint8 takerCurrencyType)"
    );

    bytes32 private constant TAKE_ORDER_INPUT_TYPEHASH = keccak256(
        "TakeOrderInput(uint32 id,address maker,uint96 takerValue,uint256 maxTakerMakerRatio)"
    );

    bytes32 private constant CANCEL_ORDER_INPUT_TYPEHASH = keccak256(
        "CancelOrderInput(uint32 id,address maker)"
    );

    bytes32 private constant ORDER_PAIR_TYPEHASH = keccak256(
        "OrderPair(address makerContractAddress,address takerContractAddress,uint8 makerCurrencyType,uint8 takerCurrencyType)"
    );

    constructor(address optIn)
        public
        EIP712Boostable(
            optIn,
            keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    keccak256("Dubiex"),
                    keccak256("1"),
                    _getChainId(),
                    address(this)
                )
            )
        )
    {}

    /**
     * @dev A struct representing the payload of `boostedMakeOrder`.
     */
    struct BoostedMakeOrder {
        DubiexLib.MakeOrderInput input;
        address payable maker;
        BoosterFuel fuel;
        BoosterPayload boosterPayload;
    }

    /**
     * @dev A struct representing the payload of `boostedTakeOrder`.
     */
    struct BoostedTakeOrder {
        DubiexLib.TakeOrderInput input;
        address payable taker;
        BoosterFuel fuel;
        BoosterPayload boosterPayload;
    }

    /**
     * @dev A struct representing the payload of `boostedCancelOrder`.
     */
    struct BoostedCancelOrder {
        DubiexLib.CancelOrderInput input;
        BoosterFuel fuel;
        BoosterPayload boosterPayload;
    }

    function hashBoostedMakeOrder(
        BoostedMakeOrder memory boostedMakeOrder,
        address booster
    ) internal view returns (bytes32) {
        return
            BoostableLib.hashWithDomainSeparator(
                _DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        BOOSTED_MAKE_ORDER_TYPEHASH,
                        hashMakeOrderInput(boostedMakeOrder.input),
                        boostedMakeOrder.maker,
                        BoostableLib.hashBoosterFuel(boostedMakeOrder.fuel),
                        BoostableLib.hashBoosterPayload(
                            boostedMakeOrder.boosterPayload,
                            booster
                        )
                    )
                )
            );
    }

    function hashBoostedTakeOrder(
        BoostedTakeOrder memory boostedTakeOrder,
        address booster
    ) internal view returns (bytes32) {
        return
            BoostableLib.hashWithDomainSeparator(
                _DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        BOOSTED_TAKE_ORDER_TYPEHASH,
                        hashTakeOrderInput(boostedTakeOrder.input),
                        boostedTakeOrder.taker,
                        BoostableLib.hashBoosterFuel(boostedTakeOrder.fuel),
                        BoostableLib.hashBoosterPayload(
                            boostedTakeOrder.boosterPayload,
                            booster
                        )
                    )
                )
            );
    }

    function hashBoostedCancelOrder(
        BoostedCancelOrder memory boostedCancelOrder,
        address booster
    ) internal view returns (bytes32) {
        return
            BoostableLib.hashWithDomainSeparator(
                _DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        BOOSTED_CANCEL_ORDER_TYPEHASH,
                        hashCancelOrderInput(boostedCancelOrder.input),
                        BoostableLib.hashBoosterFuel(boostedCancelOrder.fuel),
                        BoostableLib.hashBoosterPayload(
                            boostedCancelOrder.boosterPayload,
                            booster
                        )
                    )
                )
            );
    }

    function hashMakeOrderInput(DubiexLib.MakeOrderInput memory input)
        private
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    MAKE_ORDER_INPUT_TYPEHASH,
                    input.makerValue,
                    input.takerValue,
                    hashOrderPair(input.pair),
                    input.orderId,
                    input.ancestorOrderId,
                    input.updatedRatioWei
                )
            );
    }

    function hashOrderPair(DubiexLib.OrderPair memory pair)
        private
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    ORDER_PAIR_TYPEHASH,
                    pair.makerContractAddress,
                    pair.takerContractAddress,
                    pair.makerCurrencyType,
                    pair.takerCurrencyType
                )
            );
    }

    function hashTakeOrderInput(DubiexLib.TakeOrderInput memory input)
        private
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    TAKE_ORDER_INPUT_TYPEHASH,
                    input.id,
                    input.maker,
                    input.takerValue,
                    input.maxTakerMakerRatio
                )
            );
    }

    function hashCancelOrderInput(DubiexLib.CancelOrderInput memory input)
        private
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(CANCEL_ORDER_INPUT_TYPEHASH, input.id, input.maker)
            );
    }
}
