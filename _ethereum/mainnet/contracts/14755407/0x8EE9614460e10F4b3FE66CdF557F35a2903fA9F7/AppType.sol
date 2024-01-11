// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

library AppType {
    enum Model {
        BATCH
    }

    enum AddressConfig {
        NONE,
        ADMIN,
        FEE_WALLET
    }

    enum UintConfig {
        NONE,
        CHAIN_ID
    }

    enum BoolConfig {
        NONE,
        PAUSED
    }

    enum StringConfig {
        NONE,
        APP_NAME
    }

    struct IConfigKey {
        AddressConfig addressK;
        UintConfig uintK;
        BoolConfig boolK;
        StringConfig stringK;
    }

    struct IConfigValue {
        address addressV;
        uint256 uintV;
        bool boolV;
        string stringV;
    }

    struct Config {
        mapping(AddressConfig => address) addresses;
        mapping(UintConfig => uint256) uints;
        mapping(BoolConfig => bool) bools;
        mapping(StringConfig => string) strings;
    }

    struct NFT {
        uint256 batchId;
        uint96 royaltyPercent;
        uint256 tierId;
        address swapToken;
        string uri;
    }

    struct Batch {
        uint256 id;
        uint256 isOpenAt;
        bool disabled;
        bytes32 root;
    }

    struct State {
        mapping(Model => uint256) id;
        mapping(uint256 => Batch) batches;
        mapping(bytes32 => bool) excludedLeaves;
        mapping(uint256 => mapping(address => uint256)) tierSwapAmounts;
        Config config;
    }
}
