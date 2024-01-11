// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./NFTCollection.sol";

abstract contract NFTCollectionPausableMint is NFTCollection {
    bool public pausedMint = true;

    error MintPaused();

    function _mintAmount(uint256 _amount) internal virtual override {
        if (pausedMint) {
            revert MintPaused();
        }
        super._mintAmount(_amount);
    }

    function pauseMint() external onlyOwner {
        pausedMint = true;
    }

    function unpauseMint() external onlyOwner {
        pausedMint = false;
    }
}
