// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

import "./IERC165.sol";
import "./Parameters.sol";
import "./Graphics2D.sol";

interface IUniverseMachineRenderer is IERC165 {
    function image(Parameters memory parameters)
        external
        view
        returns (string memory);

    function render(
        uint256 tokenId,
        int32 seed,
        address parameters
    ) external view returns (uint8[] memory);
}


