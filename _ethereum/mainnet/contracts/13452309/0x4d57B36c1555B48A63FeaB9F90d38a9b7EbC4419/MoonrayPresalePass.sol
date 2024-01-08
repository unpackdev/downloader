// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./MoonrayPresalePassBase.sol";

/**
 * @title Moonray Presale Pass Wrapper Contract
 *  _______                                        _______
 * (_______)                                      (_______)
 *  _  _  _  ___   ___  ____   ____ _____ _   _    _   ___ _____ ____  _____
 * | ||_|| |/ _ \ / _ \|  _ \ / ___|____ | | | |  | | (_  (____ |    \| ___ |
 * | |   | | |_| | |_| | | | | |   / ___ | |_| |  | |___) / ___ | | | | ____|
 * |_|   |_|\___/ \___/|_| |_|_|   \_____|\__  |   \_____/\_____|_|_|_|_____)
 *                                       (____/
 *  ______                       _           ______
 * (_____ \                     | |         (_____ \
 *  _____) )___ _____  ___ _____| | _____    _____) )____  ___  ___
 * |  ____/ ___) ___ |/___|____ | || ___ |  |  ____(____ |/___)/___)
 * | |   | |   | ____|___ / ___ | || ____|  | |    / ___ |___ |___ |
 * |_|   |_|   |_____|___/\_____|\_)_____)  |_|    \_____(___/(___/
 *
 * Credit to https://patorjk.com/ for text generator.
 */
contract MoonrayPresalePass is MoonrayPresalePassBase {
    constructor()
        MoonrayPresalePassBase(
            'https://gateway.pinata.cloud/ipfs/QmeGTYN27v9QW2HrHsdfdWesbFRiUnhFWrPDoCoAKqo66L/1.json',
            1,
            9000,
            0
        )
    {
        //'https://gateway.pinata.cloud/ipfs/QmeGTYN27v9QW2HrHsdfdWesbFRiUnhFWrPDoCoAKqo66L/{id}.json' is not well supported by OpenSea.
        // Implementation version: 1
    }
}
