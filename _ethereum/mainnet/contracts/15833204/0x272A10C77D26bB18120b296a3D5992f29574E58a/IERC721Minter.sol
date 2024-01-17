//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./console.sol";

interface IERC721Minter {
    function mint(
        address from,
        address to,
        string calldata newTokenURI,
        bool freezeTokenURI
    ) external returns (uint256);
}
