// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import "./Ownable.sol";

abstract contract MintGuard is Ownable {
    error MintNotOpen();

    uint256 public mintOpenOnTimestamp;

    function checkIfMintOpen() internal view {
        if (block.timestamp < mintOpenOnTimestamp) {
            revert MintNotOpen();
        }
    }

    function changeMintOpenOnTimestamp(uint256 newMintOpenOnTimestamp) external onlyOwner {
        mintOpenOnTimestamp = newMintOpenOnTimestamp;
    }
}
