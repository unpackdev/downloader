// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./BaseNFT721.sol";

contract NfStreets is BaseNFT721 {
    constructor()
    BaseNFT721("NfStreets", "NFST", "https://streets.delarix.com/metadata/nfstreets/", "https://streets.delarix.com/metadata/nfstreets/nfstreets.json", 43600, 5, 0.005 ether, true)
    {}
}
