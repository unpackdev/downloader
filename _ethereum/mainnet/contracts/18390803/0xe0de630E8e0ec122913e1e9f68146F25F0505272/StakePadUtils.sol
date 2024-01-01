// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

library StakePadUtils {
    struct BeaconDepositParams {
        bytes pubkey;
        bytes withdrawal_credentials;
        bytes signature;
        bytes32 deposit_data_root;
    }
}
