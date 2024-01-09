// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.6;

interface IOwnable {
    function nominateNewOwner(address _owner) external;
    function acceptOwnership() external;
}