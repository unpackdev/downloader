// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IInitializableNFT {
    function initialize(
        address _config,
        address _owner,
        uint256 _totalSupply,
        string calldata name
    ) external;
}
