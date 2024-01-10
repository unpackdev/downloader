// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

interface IKeyClaimable {
    function claimKeyFor(address owner) external;
    function claimKeysFor(address owner, uint8 amount) external;
}