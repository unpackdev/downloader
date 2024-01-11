// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IBuyout {
    enum Status {
        NEW, // Buyout not offered yet
        OPEN, // Buyout offer is currently open
        COUNTERED, // Fails, counter-offerers can claim listing tokens
        SUCCESS // Success, listing token holders can surrender tokens in exchange for funding token
    }

    function status() external view returns (IBuyout.Status s);

    function offerer() external returns (address);
}
