// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.12;

interface IBrainsDistributor {
    function burnBrainsFor(address holder, uint256 amount) external;
    function mintBrainsFor(address holder, uint256 amount) external;
}