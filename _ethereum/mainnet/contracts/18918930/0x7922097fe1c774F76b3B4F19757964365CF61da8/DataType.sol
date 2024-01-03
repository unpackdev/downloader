// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


library  DataType {

    // process buy additional flag
    uint256 constant internal BUY_ADDITIONAL_IDX_WL_MAX_BUY_NUM = 0; // whitelist max buy number
    uint256 constant internal BUY_ADDITIONAL_IDX_SIMULATION     = 1; // simulation buy

    // role
    uint256 constant internal ROLE_LAUNCHPAD_FEE_RECEIPTS   = 1; // fee receipt
    uint256 constant internal ROLE_LAUNCHPAD_CONTROLLER     = 2; // launchpad controller
    uint256 constant internal ROLE_PROXY_OWNER              = 4; // proxy admin
    uint256 constant internal ROLE_LAUNCHPAD_SIGNER         = 8; // launchpad signer

    // simulation flag
    uint256 constant internal SIMULATION_NONE                       = 0; // no simulation
    uint256 constant internal SIMULATION_CHECK                      = 1; // check param
    uint256 constant internal SIMULATION_CHECK_REVERT               = 2; // check param, then revert
    uint256 constant internal SIMULATION_CHECK_PROCESS_REVERT       = 3; // check param & process, then revert
    uint256 constant internal SIMULATION_CHECK_SKIP_START_PROCESS_REVERT = 4; // escape check start time param, process, then revert
    uint256 constant internal SIMULATION_CHECK_SKIP_WHITELIST_PROCESS_REVERT = 5; // escape check skip whitelist param, process, then revert
    uint256 constant internal SIMULATION_CHECK_SKIP_BALANCE_PROCESS_REVERT = 6; // escape check skip whitelist param, process, then revert
    uint256 constant internal SIMULATION_NO_CHECK_PROCESS_REVERT    = 7; // escape check param, process, then revert

    enum WhiteListModel {
        NONE,                     // 0 - No White List
        ON_CHAIN_CHECK,           // 1 - Check address on-chain
        OFF_CHAIN_SIGN,           // 2 - Signed by off-chain valid address
        OFF_CHAIN_MERKLE_ROOT     // 3 - check off-chain merkle tree root
    }

    struct LaunchpadSlot {
        uint32 saleQty;    // current sale number, must from 0
        bytes4 launchpadId; // launchpad id
        uint8 slotId; // slot id
        bool enable;  // enable flag
        WhiteListModel whiteListModel;
        uint8 feeType; // 0 - to feeReceipt, 1 - to targetContract
        address feeReceipt;

        uint32 maxSupply; // max supply of this slot
        uint16 maxBuyQtyPerAccount; // max buy qty per address
        // finalPrice = price * (10 ** priceUint)
        uint16 pricePresale;
        uint16 price;
        uint16 priceUint;
        address paymentToken;

        uint32 saleStart; // buy start time, seconds
        uint32 saleEnd; // buy end time, seconds
        uint32 whiteListSaleStart; // whitelist start time
        address signer; // signers for whitelist

        bool storeSaleQtyFlag; // true - store， false - no need to store
        bool storeAccountQtyFlag; // true - store， false - no need to store
        uint8 mintParams;
        uint8 queryAccountMintedQtyParams;
        bytes4 mintSelector;
        bytes4 queryAccountMintedQtySelector;
        address targetContract; // target contract of 3rd project,
    }

    struct Launchpad {
        uint8 slotNum;
    }

    // stats info for buyer account
    struct AccountSlotStats {
        uint16 totalBuyQty; // total buy num already
    }

    struct BuyParameter {
        bytes4 launchpadId;
        uint256 slotId;
        uint256 quantity;
        uint256 maxWhitelistBuy;
        bytes data;
    }
}
