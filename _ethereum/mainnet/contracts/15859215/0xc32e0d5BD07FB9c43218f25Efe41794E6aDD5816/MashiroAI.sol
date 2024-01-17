// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title: NFTMinterMerkle
/// @author: Pacy

/************************************************
           '     .    ╓▄▄▄▄▄,'
                  ╓▓███████████▓ç
                ▄█████████████████Q
               ▓███████████████████▌
              ▓█████████▓▓▓▓╢▓██████▌
          '  ▐██████▀  ▓▓▓▓▓▓████████⌐
        ⁿ ''╙█████▓▌    ▓██ ▀████████
             └█▌██▌   ●  ▓   ●  ███▓
             »Γ╫███╓           ▐███
              ``╙██▄     W      ▓██
                 ██▀▓▄       ▄█▀█
               - ╫█   ▒≥. -≥░µ .█
               ``»█╙▓█░░░░░░░█▓╩█
        ░░φ░▄▄▄▓██████░░░░░░Ü██████▓▄▄▄
   -≥░░░▄▓█████████████└²≥╚╙█████████████▌▄
``"░░¡▓██████████████████▄███████████████████
 ***********************************************/

import "./ERC1967Proxy.sol";

contract MashiroAI is ERC1967Proxy {
    // pass erc721 delegate address and initialize data
    constructor(address _logic, bytes memory _data)
        payable
        ERC1967Proxy(_logic, _data)
    {}
}
