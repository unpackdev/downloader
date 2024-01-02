// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IERC165.sol";

interface ISwapper is IERC165 {
    struct Claim {
        uint256 powAmount;
        uint256 punksAmount;
        bool powPunksAsCredits;
        uint256[] planetIds;
        uint256[] planetAmounts;
    }
}
