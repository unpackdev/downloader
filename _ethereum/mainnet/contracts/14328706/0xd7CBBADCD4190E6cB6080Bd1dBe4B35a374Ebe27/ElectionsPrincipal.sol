// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

interface ElectionsPrincipal {
    function candidateOf(address account) external view returns (address);

    function votesOf(address account) external view returns (uint256);
}
