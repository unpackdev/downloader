// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

interface ISocksMinter {
    error BoxAlreadyClaimed(uint256 boxId);
    error CallerNotOwner(uint256 boxId);

    function getBoxesThatMinted(uint256 boxId) external view returns (bool);
}
