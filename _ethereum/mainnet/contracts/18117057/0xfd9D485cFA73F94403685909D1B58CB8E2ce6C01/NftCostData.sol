// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.19;

import "./Fee.sol";

struct NftCostData {
    bool specificNftId;
    uint256 nftId;
    uint256 price;
    Fee fee;
}