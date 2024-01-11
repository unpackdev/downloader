// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./MoonrayTokenBase.sol";

/**
 * @title MoonrayToken
 *
 *          /█)       ,                   ,          //   //////////      ///        .///
 *      ./███████#*   ██*          *██\  \███       (██*   /██████████(   /████    ,████
 *     #█=- //        /████      █████\    ████     (██*           .███      ████ ████
 *      \███████\        \███\/███████\      \████* (██*          .#███       /█████
 *         // -=█#         /████/  ███\         ███████*        █████.        ████
 *    /#███████/                   ███\           \████*         \███       ████.
 *        \█)                      ███\              \█*          \███,   ████       
 */
contract MoonrayToken is MoonrayTokenBase {
    address private constant TOKEN_RECEIVER = 0x5F4F90CCd02C02777f96A1FDAd781eaFaEfF38b3;

    constructor() MoonrayTokenBase('Moonray', 'MNRY', 1e9 * 1e18, TOKEN_RECEIVER) {
        // Implementation version: 1
    }
}
