// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC721Upgradeable.sol";

interface IERC721Permit is IERC721Upgradeable {
    function permit(
        address owner,
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function permitAll(
        address owner,
        address spender,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}
