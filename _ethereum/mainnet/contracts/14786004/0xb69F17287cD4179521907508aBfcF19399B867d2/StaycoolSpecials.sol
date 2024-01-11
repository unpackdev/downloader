// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Admin.sol";

contract StaycoolSpecials is ERC721, Admin {
    string private BASE_URI = "https://us-central1-staycoolnyc-cb1a2.cloudfunctions.net/specials/";
    uint256 private CURRENT_ID = 1;

    constructor() ERC721("Staycool Specials", "STAYCOOLSPECIALS") {
        _mint(msg.sender, CURRENT_ID);
    }

    function setBaseURI(string memory uri) public onlyAdmins {
        BASE_URI = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }

    function mintTo(address to) external onlyAdmins {
        CURRENT_ID++;
        _mint(to, CURRENT_ID);
    }
}
