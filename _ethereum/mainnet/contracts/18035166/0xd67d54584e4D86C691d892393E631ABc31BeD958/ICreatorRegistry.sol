// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICreatorRegistry {
    function tokenCreator(address _contractAddress, uint256 _tokenId)
        external
        view
        returns (address payable);
}
