//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721PresetMinterPauserAutoId.sol";
import "./ERC721URIStorage.sol";

contract Headhunter is ERC721PresetMinterPauserAutoId {
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI
    ) ERC721PresetMinterPauserAutoId(_name, _symbol, _baseTokenURI) {}

    function setBaseUri(string memory _uri) public {
        // only pauser role can change uri
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "ERC721PresetMinterPauserAutoId: must have pauser role to pause"
        );

        _baseTokenURI = _uri;
    }
}
