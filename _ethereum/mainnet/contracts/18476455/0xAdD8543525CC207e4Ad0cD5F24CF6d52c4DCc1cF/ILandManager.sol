// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILandManager {
    event LandMinted(
        address owner,
        uint256 id,
        uint256 maticPrice,
        uint256 nvsPrice
    );
    event LandUpgrade(
        address owner,
        uint256 id,
        uint256 floor,
        uint256 richness,
        uint256 price
    );

}
