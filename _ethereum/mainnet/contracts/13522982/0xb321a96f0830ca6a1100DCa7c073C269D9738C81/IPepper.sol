// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Enumerable.sol";

interface IPepper is IERC721, IERC721Enumerable {
    function burn(uint256 nftId) external;

    function directMint(address to, uint256[] calldata nftIds) external;

    function checkApprovedOrOwner(address spender, uint256 nftId)
        external
        view
        returns (bool);
}
