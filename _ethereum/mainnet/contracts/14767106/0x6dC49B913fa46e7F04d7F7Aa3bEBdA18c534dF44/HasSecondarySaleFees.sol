// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface HasSecondarySaleFees {
    function getFeeRecipients(uint256 id)
        external
        view
        returns (address payable[] memory);

    function getFeeBps(uint256 id)
        external
        view
        returns (uint256[] memory);
}