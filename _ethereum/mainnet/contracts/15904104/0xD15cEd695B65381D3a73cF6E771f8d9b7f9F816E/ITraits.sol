// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "IERC1155.sol";

interface ITraits is IERC1155 {
    error Soulbound();
    error NotClaimable();
    error NonExistent();
    error HasClaimed();
    error NoCoin();
    error InvalidShards();
    error InvalidLength();
    error ArrayLengthMismatch();
}
