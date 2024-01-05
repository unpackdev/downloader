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
contract AbyssSafe3 is AbyssSafeBase {
    uint256 public override constant unlockTime = 259200; // mainnet
    // uint256 public override constant unlockTime = 180; // testnet

    constructor(address token, address lockup, uint256 abyssRequired) AbyssSafeBase(token, lockup, unlockTime, abyssRequired) {
    }
}
