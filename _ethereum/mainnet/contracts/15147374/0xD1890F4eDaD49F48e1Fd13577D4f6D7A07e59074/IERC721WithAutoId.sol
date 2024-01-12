// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./IERC721Mintable.sol";

interface IERC721WithAutoId is IERC721Mintable {
    function currentId() external returns (uint256);
}