// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

/**
 * @title EoaGuard
 * @author JieLi
 *
 * @notice Protect functions from smart contract
 */
contract EoaGuard {
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "PB: ONLY EOA");
        _;
    }
}
