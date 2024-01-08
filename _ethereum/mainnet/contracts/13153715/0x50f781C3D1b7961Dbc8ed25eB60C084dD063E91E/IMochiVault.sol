// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Float.sol";

struct Detail {
    Status status;
    uint256 collateral;
    uint256 debt;
    uint256 debtIndex;
    address referrer;
}

enum Status {
    Invalid, // not minted
    Idle, // debt = 0, collateral = 0
    Collaterized, // debt = 0, collateral > 0
    Active, // debt > 0, collateral > 0
    Liquidated
}

interface IMochiVault {
    function details(uint256 tokenId) external view returns (Detail memory);
}
