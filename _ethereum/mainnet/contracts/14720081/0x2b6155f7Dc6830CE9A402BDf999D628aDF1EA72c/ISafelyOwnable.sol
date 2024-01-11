// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

interface ISafelyOwnable {
    function nominateNewOwner(address _owner) external;
    function acceptOwnership() external;
}