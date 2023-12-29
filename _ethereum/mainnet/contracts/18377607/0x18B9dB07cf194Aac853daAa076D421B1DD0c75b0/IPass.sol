// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./IERC721.sol";

interface IPass is IERC721 {
    function safeMint(address to) external;
}
