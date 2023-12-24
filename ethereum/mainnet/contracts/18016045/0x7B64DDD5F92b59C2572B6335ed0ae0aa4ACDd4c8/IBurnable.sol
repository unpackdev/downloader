// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./IERC721A.sol";

interface IBurnable is IERC721A{
    function burnBatch(uint256[] memory _tokenIds) external;
}
