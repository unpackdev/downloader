// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOldTrainingGrounds {
    function ownsToken(uint256 tokenId) external view returns (bool);
}