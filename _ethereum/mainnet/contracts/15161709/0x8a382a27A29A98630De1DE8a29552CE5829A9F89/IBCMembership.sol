// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Enumerable.sol";

interface IBCMembership is IERC721, IERC721Enumerable {

    function safeMint(address to) external;

    function safeMint(address to, string memory uri) external;

    function setBaseUri(string memory _baseUri) external;

    function transferOwnership(address newOwner) external;

}
