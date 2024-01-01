// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface iSCL {

    struct SCGearConfig {
        uint8 weaponId;
        uint8 chestId;
        uint8 headId;
        uint8 legsId;
        uint8 vehicleId;
        uint8 armsId;
        uint8 artifactId;
        uint8 ringId;
    }

    function getWeaponId(uint256 tokenId_) external view returns (uint256);
    function getChestId(uint256 tokenId_) external view returns (uint256);
    function getHeadId(uint256 tokenId_) external view returns (uint256);
    function getLegsId(uint256 tokenId_) external view returns (uint256);
    function getVehicleId(uint256 tokenId_) external view returns (uint256);
    function getArmsId(uint256 tokenId_) external view returns (uint256);
    function getArtifactId(uint256 tokenId_) external view returns (uint256);
    function getRingId(uint256 tokenId_) external view returns (uint256);
    function getSCGearConfig(uint256 tokenId_) external view returns (SCGearConfig memory);
}

interface iCS {

    struct Character {
        uint8 race_;
        uint8 renderType_;
        uint16 transponderId_;
        uint16 spaceCapsuleId_;
        uint8 augments_;
        uint16 basePoints_;
        uint16 totalEquipmentBonus_;
    }

    function characters(uint256 tokenId_) external view returns (Character memory);
}

contract CharacterSCLib {

    iCS public constant CS = iCS(0xC7C40032E952F52F1ce7472913CDd8EeC89521c4);
    iSCL public constant SCL = iSCL(0x9BF54865C073bDDcdbAe7e23AeE518252ae9D18c);

    function _getSCFromCS(uint256 tokenId_) internal view returns (uint256) {
        return CS.characters(tokenId_).spaceCapsuleId_;
    }

    function getWeaponId(uint256 tokenId_) external view returns (uint256) {
        return SCL.getWeaponId(uint256(_getSCFromCS(tokenId_)));
    }
    function getChestId(uint256 tokenId_) external view returns (uint256) {
        return SCL.getChestId(uint256(_getSCFromCS(tokenId_)));
    }
    function getHeadId(uint256 tokenId_) external view returns (uint256) {
        return SCL.getHeadId(uint256(_getSCFromCS(tokenId_)));
    }
    function getLegsId(uint256 tokenId_) external view returns (uint256) {
        return SCL.getLegsId(uint256(_getSCFromCS(tokenId_)));
    }
    function getVehicleId(uint256 tokenId_) external view returns (uint256) {
        return SCL.getVehicleId(uint256(_getSCFromCS(tokenId_)));
    }
    function getArmsId(uint256 tokenId_) external view returns (uint256) {
        return SCL.getArmsId(uint256(_getSCFromCS(tokenId_)));
    }
    function getArtifactId(uint256 tokenId_) external view returns (uint256) {
        return SCL.getArtifactId(uint256(_getSCFromCS(tokenId_)));
    }
    function getRingId(uint256 tokenId_) external view returns (uint256) {
        return SCL.getRingId(uint256(_getSCFromCS(tokenId_)));
    }
    function getSCGearConfig(uint256 tokenId_) external view returns (iSCL.SCGearConfig memory) {
        return SCL.getSCGearConfig(uint256(_getSCFromCS(tokenId_)));
    }
}