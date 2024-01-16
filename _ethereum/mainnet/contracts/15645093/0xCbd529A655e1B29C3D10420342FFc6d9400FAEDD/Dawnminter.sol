// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./QQL.sol";

contract Dawnminter {
    event TestHit(uint256 supply);
    event ProdHit();

    QQL constant Q = QQL(0x845dD2a7eE2a92A0518AB2135365Ed63fdbA0C88);
    bytes32 constant SEED_LION =
        bytes32(
            0xe03a5189dac8182085e4adf66281f679fff2291d9f39e54a3b83e18620d1a34d
        );
    bytes32 constant SEED_PHANTOM =
        bytes32(
            0xe03a5189dac8182085e4adf66281f679fff2291db91a2be890f22886e121c32c
        );
    address constant RECIPIENT = 0xE03a5189dAC8182085e4aDF66281F679fFf2291D;

    function test(uint256 targetTimestamp) external {
        if (block.timestamp < targetTimestamp) revert("Dawnminter: hold...");
        emit TestHit(Q.totalSupply());
    }

    function go() external {
        if (block.timestamp < Q.unlockTimestamp())
            revert("Dawnminter: hold...");
        uint256 supply = Q.totalSupply();
        if (supply == 12) {
            Q.mintTo(22, SEED_PHANTOM, RECIPIENT);
            Q.mintTo(23, SEED_LION, RECIPIENT);
        } else {
            Q.mintTo(22, SEED_LION, RECIPIENT);
            Q.mintTo(23, SEED_PHANTOM, RECIPIENT);
        }
        emit ProdHit();
    }
}
