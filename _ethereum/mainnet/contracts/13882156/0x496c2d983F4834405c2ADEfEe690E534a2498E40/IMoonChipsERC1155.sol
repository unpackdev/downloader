// contracts/IMBytes.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1155.sol";

interface IMoonChipsERC1155 is IERC1155 {
    function collectionFull(uint8 _collectionId)
        external
        view
        returns (bool);
}