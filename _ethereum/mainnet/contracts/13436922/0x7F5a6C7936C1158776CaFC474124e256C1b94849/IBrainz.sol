// contracts/IBrainz.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBrainz {
    function burnFrom(address account, uint256 amount) external;
}