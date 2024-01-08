// SPDX-License-Identifier: MIT
//  ______   ______     _____
// /\__  _\ /\  == \   /\  __-.
// \/_/\ \/ \ \  __<   \ \ \/\ \
//    \ \_\  \ \_____\  \ \____-
//     \/_/   \/_____/   \/____/
//
pragma solidity 0.8.6;

interface IZeroExV4Exchange {
    //
    //      _                   _
    //  ___| |_ _ __ _   _  ___| |_ ___
    // / __| __| '__| | | |/ __| __/ __|
    // \__ \ |_| |  | |_| | (__| |_\__ \
    // |___/\__|_|   \__,_|\___|\__|___/
    //
    //

    struct RfqOrder {
        address makerToken;
        address takerToken;
        uint128 makerAmount;
        uint128 takerAmount;
        address maker;
        address taker;
        address txOrigin;
        bytes32 pool;
        uint64 expiry;
        uint256 salt;
    }

    struct Signature {
        SignatureType signatureType;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    //
    //   ___ _ __  _   _ _ __ ___  ___
    //  / _ \ '_ \| | | | '_ ` _ \/ __|
    // |  __/ | | | |_| | | | | | \__ \
    //  \___|_| |_|\__,_|_| |_| |_|___/
    //

    enum SignatureType {
        ILLEGAL,
        INVALID,
        EIP712,
        ETHSIGN
    }

    function fillRfqOrder(
        RfqOrder memory order,
        Signature memory signature,
        uint128 takerTokenFillAmount
    ) external returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount);
}
