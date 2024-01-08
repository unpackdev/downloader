// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./ERC721PresetMinterPauserAutoId.sol";

contract CaptureClubNFT is ERC721PresetMinterPauserAutoId {
    constructor(string memory name, string memory symbol, string memory baseURI) public ERC721PresetMinterPauserAutoId(name, symbol, baseURI) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());

        _setBaseURI(baseURI);
    }
}