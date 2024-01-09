//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract State {
    enum MintState {
        Closed,
        Active,
        Maintenance,
        Finalized
    }
    MintState public mintState = MintState.Closed;

    /**
     * Modifier that checks mint state to be closed
     */
    modifier closed() {
        require(mintState == MintState.Closed, "Mint not closed");
        _;
    }

    /**
     * Modifier that checks mint state to be active
     */
    modifier active() {
        require(mintState == MintState.Active, "Mint not active");
        _;
    }
}
