// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

abstract contract IIconRenderer {
    function imageURL(uint256 tokenID, string memory style)
        external
        view
        virtual
        returns (string memory);
}
