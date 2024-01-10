// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

import "./ERC721PresetMinterPauser.sol";

contract TokauMetacityLand is ERC721PresetMinterPauser {
    constructor(string memory baseUri) ERC721PresetMinterPauser("Tokau Metacity Land", "TML", baseUri) {
    }
}
