// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IKeyGateway {
    function useNfts(
        uint256 _requirement,
        address[] memory _collections,
        uint256[] memory _nfts,
        address _owner
    ) external;
}
