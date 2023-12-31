// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// NFTC Open Source Contracts See: https://github.com/NFTCulture/nftc-contracts
import "./NFTCSplitsAndRoyalties.sol";

abstract contract PixelPioneerSplitsAndRoyalties is NFTCSplitsAndRoyalties {
    address[] internal addresses = [0xB19C6659570b64DAd956b1A1b477764C9eF9546f];

    uint256[] internal splits = [100];

    uint96 private constant DEFAULT_ROYALTY_BASIS_POINTS = 1000;

    constructor() NFTCSplitsAndRoyalties(addresses, splits, address(this), DEFAULT_ROYALTY_BASIS_POINTS) {
        // Nothing to do.
    }
}
