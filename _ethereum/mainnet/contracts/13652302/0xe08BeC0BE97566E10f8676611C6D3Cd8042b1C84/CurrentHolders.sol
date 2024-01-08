 /**
 *
 * Copyright Notice: User must include the following signature.
 *
 * Smart Contract Developer: www.QambarRaza.com
 *
 * ..#######.....###....##.....##.########.....###....########.
 * .##.....##...##.##...###...###.##.....##...##.##...##.....##
 * .##.....##..##...##..####.####.##.....##..##...##..##.....##
 * .##.....##.##.....##.##.###.##.########..##.....##.########.
 * .##..##.##.#########.##.....##.##.....##.#########.##...##..
 * .##....##..##.....##.##.....##.##.....##.##.....##.##....##.
 * ..#####.##.##.....##.##.....##.########..##.....##.##.....##
 * .########.....###....########....###...
 * .##.....##...##.##........##....##.##..
 * .##.....##..##...##......##....##...##.
 * .########..##.....##....##....##.....##
 * .##...##...#########...##.....#########
 * .##....##..##.....##..##......##.....##
 * .##.....##.##.....##.########.##.....##
 */

// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8.9;

import "./Ownable.sol";

contract CurrentHolders is Ownable {

mapping(address => uint256[]) public cht;
mapping(address => bool) public chtRegister;
mapping(address => uint256) public chtG;

    function registerCH(address[] memory wallets, uint256[][] memory listOfLists) public onlyOwner  {
        for (uint256 i = 0; i < wallets.length; i++) {
            cht[wallets[i]] = listOfLists[i];
            chtRegister[wallets[i]] = true;
        }
    }

    function isCHAddress(address wallet) 
        external
        view
        returns (bool) {
        return chtRegister[wallet];
    }

    function deRegisterAddress(address wallet) public onlyOwner  {
        delete cht[wallet];
    }
}