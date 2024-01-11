//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

interface IREMXCollectionFactory {
    function createCollection(
        address _admin,
        address _minter,
        address revenueSplitter,
        string memory name,
        string memory symbol,
        uint256 royalty,
        string memory baseURI
    ) external returns (address);
}
