// SPDX-License-Identifier: MIT

/***
 __ _  _  _  _  _  ____   __  ____  ____  ____  ____  _  _
(  / )/ )( \/ )( \(  _ \ /  \(_  _)(_  _)(  __)(  _ \( \/ )
 )  ( ) \/ () \/ ( ) __/(  O ) )(    )(   ) _)  )   / )  /
(__\_)\____/\____/(__)   \__/ (__)  (__) (____)(__\_)(__/
*/

// Contract by @Montana_Wong

pragma solidity ^0.8.7;

import "./ERC721Kuullection.sol";

contract Chalices is ERC721Kuullection {
    constructor(string memory _baseTokenURI) ERC721Kuullection("Chalices", "CHALICES", _baseTokenURI, 0x18866C05Ac6BbdC0e0cB8Fc5E2e9be400aF516c3, 7) {}

    function _startTokenId() internal view override returns (uint256) {
        return 1;
    }
}
