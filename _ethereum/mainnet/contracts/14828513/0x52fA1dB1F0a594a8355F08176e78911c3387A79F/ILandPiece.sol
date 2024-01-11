// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface ILandPiece {
    function mintFor(address to, uint8 id) external;
}
