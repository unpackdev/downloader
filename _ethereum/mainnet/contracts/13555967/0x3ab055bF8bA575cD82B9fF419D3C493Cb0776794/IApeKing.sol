// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IApeKing {
    function tokensOfOwner(address) external view returns (uint256[] memory);
}
