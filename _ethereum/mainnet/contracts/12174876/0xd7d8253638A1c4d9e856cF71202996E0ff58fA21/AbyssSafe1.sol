/*
░█████╗░██████╗░██╗░░░██╗░██████╗░██████╗  ███████╗██╗███╗░░██╗░█████╗░███╗░░██╗░█████╗░███████╗
██╔══██╗██╔══██╗╚██╗░██╔╝██╔════╝██╔════╝  ██╔════╝██║████╗░██║██╔══██╗████╗░██║██╔══██╗██╔════╝
███████║██████╦╝░╚████╔╝░╚█████╗░╚█████╗░  █████╗░░██║██╔██╗██║███████║██╔██╗██║██║░░╚═╝█████╗░░
██╔══██║██╔══██╗░░╚██╔╝░░░╚═══██╗░╚═══██╗  ██╔══╝░░██║██║╚████║██╔══██║██║╚████║██║░░██╗██╔══╝░░
██║░░██║██████╦╝░░░██║░░░██████╔╝██████╔╝  ██║░░░░░██║██║░╚███║██║░░██║██║░╚███║╚█████╔╝███████╗
╚═╝░░╚═╝╚═════╝░░░░╚═╝░░░╚═════╝░╚═════╝░  ╚═╝░░░░░╚═╝╚═╝░░╚══╝╚═╝░░╚═╝╚═╝░░╚══╝░╚════╝░╚══════╝
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AbyssSafeBase.sol";

/**
 * Abyss Finance's AbyssSafe Contract
 * The main smart contract that is responsible for deposits and withdrawal of tokens.
 */
contract AbyssSafe1 is AbyssSafeBase {
    uint256 public override constant unlockTime = 86400; // mainnet
    // uint256 public override constant unlockTime = 60; // testnet

    constructor(address token, address lockup, uint256 abyssRequired) AbyssSafeBase(token, lockup, unlockTime, abyssRequired) {
    }
}
