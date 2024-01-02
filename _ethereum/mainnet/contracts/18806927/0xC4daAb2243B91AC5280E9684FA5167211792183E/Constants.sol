// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

library Constants {
    /*-------------------------------- Role --------------------------------*/
    // 0x0000000000000000000000000000000000000000000000000000000000000000
    bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;
    // 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775
    bytes32 constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    // 0xfc425f2263d0df187444b70e47283d622c70181c5baebb1306a01edba1ce184c
    bytes32 constant DEPLOYER_ROLE = keccak256("DEPLOYER_ROLE");
    // 0x6c0757dc3e6b28b2580c03fd9e96c274acf4f99d91fbec9b418fa1d70604ff1c
    bytes32 constant FEE_MANAGER_ROLE = keccak256("FEE_MANAGER_ROLE");
    // 0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6
    bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");
    // 0x3c11d16cbaffd01df69ce1c404f6340ee057498f5f00246190ea54220576a848
    bytes32 constant BURNER_ROLE = keccak256("BURNER_ROLE");
    // 0x63eb04268b235ac1afacf3bcf4b19c5c175d0417a1555fb3ff79ae190f71ee7c
    bytes32 constant FEE_STORE_MANAGER_ROLE = keccak256("FEE_STORE_MANAGER_ROLE");
    // 0x77f52ccf2f32e71a0cff8f14ad8c8303b7d2e4c7609b8fba963114f4db2af767
    bytes32 constant FEE_DISTRIBUTOR_PUSH_ROLE = keccak256("FEE_DISTRIBUTOR_PUSH_ROLE");
    // 0xe85d5f1f8338cb18f500856d1568d0f3b0d0971f25b3ccd134475e991354edbf
    bytes32 constant FEE_DISTRIBUTOR_MANAGER = keccak256("FEE_DISTRIBUTOR_MANAGER");
    /*----------------------------------------------------------------------*/

    /*------------------------------- Fee ID -------------------------------*/
    // 0xacfc432e98ad100d9f8c385f3782bc88a17e1de7e53f69678cbcc41e8ffe72b0
    bytes32 constant ERC20_MARKETING_FEE = keccak256("ERC20_MARKETING_FEE");
    // 0x6b78196f16f828b24a5a6584d4a1bcc5ce2f3154ba57839db273e6a4ebbe92c2
    bytes32 constant ERC20_REWARD_FEE = keccak256("ERC20_REWARD_FEE");
    // 0x6e3678bee6f77c8a6179922c9a518b08407e6d9d2593ac683a87c979c8b31a12
    bytes32 constant ERC20_PLATFORM_FEE = keccak256("ERC20_PLATFORM_FEE");
    // 0x6e2178bb28988b4c92cd3092e9e342e7639bfda2f68a02ac478cb084759607cf
    bytes32 constant ERC20_DEVELOPER_FEE = keccak256("ERC20_DEVELOPER_FEE");
    /*----------------------------------------------------------------------*/

    /*--------------------------- Relayer Actions --------------------------*/
    // 0xf145583e6e33d9da99af75b579493b11db4229a339336b82c748312f152b29a9
    bytes32 constant RELAYER_ACTION_DEPLOY_FEES = keccak256("RELAYER_ACTION_DEPLOY_FEES");
    // 0xf375f410a0dc135af0d9a16e273eac999064981d8813a68af762e93567a43aac
    bytes32 constant RELAYER_ACTION_DEPLOY_FEES_CONFIRM = keccak256("RELAYER_ACTION_DEPLOY_FEES_CONFIRM");
    // 0x9d62257b25ea052fe7cd5123fd6b791268b8673b073aae5de4a823c4dc7d7607
    bytes32 constant RELAYER_ACTION_SEND_FEES = keccak256("RELAYER_ACTION_SEND_FEES");
    /*----------------------------------------------------------------------*/
}
