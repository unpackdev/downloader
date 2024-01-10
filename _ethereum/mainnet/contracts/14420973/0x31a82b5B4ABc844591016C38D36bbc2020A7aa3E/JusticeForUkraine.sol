// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./JusticeForUkraineBase.sol";
import "./UkraineWallets.sol";

/**
 * @title JUSTICE (FOR UKRAINE)
 *
 *                       Слава Україні!
 *
 *                           ▓▓▓▓
 *                         ░░████
 *                         ████████
 * ██▒▒                    ████████                    ██
 * ▓▓████                  ████████                ▒▒████
 * ████████                ████████              ████████
 * ▓▓████████              ████████            ██████████
 * ▓▓██████████            ████████          ▒▒████░░████░░
 * ████▒▒  ████░░            ██████          ██████  ████░░
 * ████▒▒  ██████            ████            ████    ████░░
 * ████▒▒    ████            ████          ██████    ████░░
 * ██████    ████            ████          ████▒▒    ████░░
 * ████▒▒    ██████          ████          ████      ████░░
 * ████▒▒    ██████          ████          ████      ████░░
 * ████▒▒    ██████          ████        ▒▒████      ████▒▒
 * ████▒▒      ████          ████        ██████      ████▒▒
 * ████▒▒      ████        ██████        ██████      ████▒▒
 * ████        ████        ████████      ████▒▒      ████▒▒
 * ████░░      ████        ████████      ████▒▒      ████▓▓
 * ████      ██████▒▒    ██████████░░    ████████    ████▓▓
 * ████    ██████        ████  ██████      ▒▒████▒▒  ██████
 * ████████████        ██████    ████        ██████████████
 * ████████████        ████      ██████      ▒▒████████████
 * ████▒▒░░████░░    ██████        ████░░    ████▒▒  ██████
 * ████░░  ██████████████░░        ██████████████    ██████
 * ████      ████████████████  ░░██████████████      ██████
 * ████░░        ▒▒████████████████████████          ██████
 * ████░░        ░░████    ██████▓▓    ████          ██████
 * ████          ██████    ▒▒████      ████          ██████
 * ██████▓▓▓▓██▓▓██████████████████████████████████████████
 * ████████████████████████████████████████████████████████
 *                 ████░░  ██████    ██████
 *                 ██████  ▒▒████    ████░░
 *                 ██████  ▒▒████  ██████
 *                   ████████████  ████
 *                   ░░██████████████▒▒
 *                     ░░██████████▓▓
 *                       ░░██████▒▒
 *                           ██▒▒
 *
 *                      Героям слава!
 *
 *                    WE ARE DETERMINED
 *             THAT BEFORE THE SUN SETS ON THIS
 *       TERRIBLE STRUGGLE OUR FLAG WILL BE RECOGNIZED
 *        THROUGHOUT THE WORLD AS A SYMBOL OF FREEDOM
 *           ON THE ONE HAND AND OF OVERWHELMING
 *                   FORCE ON THE OTHER
 *
 *        -a quote that is truly befitting of Ukraine
 */
contract JusticeForUkraine is UkraineWallets, JusticeForUkraineBase {
    constructor()
        JusticeForUkraineBase(
            'JusticeForUkraine',
            'J4U',
            'https://gateway.pinata.cloud/ipfs/QmYHatcDEaYroUPfGj3wSk2BC3voT78WQias1Q9hiNgZ8n/', // final art v1
            addresses,
            splits)
    {
        // 100% of proceeds go to Ukraine addresses.
        // Donations programmatically verifiable and guaranteed by UkraineWallets and LockedPaymentSplitter.
        // Balances pushed to wallets by contract owner at sellout and/or weekly/monthly/.5eth increments.
    }
}
