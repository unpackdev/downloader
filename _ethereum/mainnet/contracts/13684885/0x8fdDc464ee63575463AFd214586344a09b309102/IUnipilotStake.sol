//SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

interface IUnipilotStake {
    function getBoostMultiplier(
        address userAddress,
        address poolAddress,
        uint256 tokenId
    ) external view returns (uint256);

    function userMultiplier(address userAddress, address poolAddress)
        external
        view
        returns (uint256);
}
