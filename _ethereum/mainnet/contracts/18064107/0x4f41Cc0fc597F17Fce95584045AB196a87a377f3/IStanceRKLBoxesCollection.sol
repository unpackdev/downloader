// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

interface IStanceRKLBoxesCollection {
    error KongAlreadyClaimed(uint256 kongId);
    error CallerNotOwner(uint256 kongId);
    error OnlyRegisteredMintersAllowed();
    error MinterControllerAddressAlreadySet();

    function getTokensOwnedByAddress(address owner, uint256 offset, uint256 limit)
        external
        view
        returns (uint256[] memory);
}
