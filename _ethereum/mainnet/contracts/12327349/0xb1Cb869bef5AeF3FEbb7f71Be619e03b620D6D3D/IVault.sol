//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

interface IVault {
    function pegIn(
        uint256 _tokenAmount,
        address _tokenAddress,
        string calldata _destinationAddress,
        bytes calldata _userData
    ) external returns (bool);
}
