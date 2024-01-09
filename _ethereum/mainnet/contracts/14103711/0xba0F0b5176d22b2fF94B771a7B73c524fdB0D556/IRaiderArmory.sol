//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRaiderArmory {
    function addWeaponToToken(uint256 _tokenId, uint256 _weaponId) external;

    function hasWeapon(uint256 _tokenId, uint256 _weaponId)
        external
        returns (bool);

    function getMaxWeaponScore(uint256 _tokenId) external view returns (uint8);
}
