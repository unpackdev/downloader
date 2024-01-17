// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

abstract contract HasSecondarySaleFees {

    event SecondarySaleFees(uint256 tokenId, address[] recipients, uint[] bps);

    constructor() {
    }

    function getFeeRecipients(uint256 id) public view virtual returns (address payable[] memory);
    function getFeeBps(uint256 id) public view virtual returns (uint[] memory);
}
