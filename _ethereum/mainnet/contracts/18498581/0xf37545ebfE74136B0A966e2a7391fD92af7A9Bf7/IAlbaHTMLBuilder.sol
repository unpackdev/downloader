// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

interface IAlbaHTMLBuilder {
    function tokenHTML(
        bytes16 uuid,
        uint256 tokenId,
        bytes32 seed,
        bytes16[] memory deps
    ) external view returns (bytes memory);
}
