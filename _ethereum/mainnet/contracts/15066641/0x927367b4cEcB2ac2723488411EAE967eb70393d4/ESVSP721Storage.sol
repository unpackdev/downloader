// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IESVSP.sol";

abstract contract ESVSP721StorageV1 {
    /**
     * @notice Base URI
     */
    string public baseTokenURI;

    /**
     * @notice ESVSP contract
     */
    IESVSP public esVSP;

    /**
     * @notice Tracks the next token id to mint
     */
    uint256 public nextTokenId;
}
