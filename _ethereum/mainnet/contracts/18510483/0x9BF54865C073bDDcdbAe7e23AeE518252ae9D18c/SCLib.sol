// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library Strings {
    function toString(uint256 value) internal pure 
    returns (string memory str) { assembly {
        let m := add(mload(0x40), 0xa0)
        mstore(0x40, m)
        str := sub(m, 0x20)
        mstore(str, 0)

        let end := str

        for { let temp := value } 1 {} {
            str := sub(str, 1)
            mstore8(str, add(48, mod(temp, 10)))
            temp := div(temp, 10)
            if iszero(temp) { break }
        }

        let length := sub(end, str)
        str := sub(str, 0x20)
        mstore(str, length)
    }}
}

contract SCLib {

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

    function _capsuleRNG(uint256 tokenId_, string memory keyPrefix_, uint256 length_) 
    private pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            string(abi.encodePacked(
                keyPrefix_, Strings.toString(tokenId_)
            )) 
        ))) % length_;
    }

    function getWeaponId(uint256 tokenId_) public pure returns (uint256) {
        return _capsuleRNG(tokenId_, "WEAPONS", 18);
    }
    function getChestId(uint256 tokenId_) public pure returns (uint256) {
        return _capsuleRNG(tokenId_, "CHEST", 15);
    }
    function getHeadId(uint256 tokenId_) public pure returns (uint256) {
        return _capsuleRNG(tokenId_, "HEAD", 15);
    }
    function getLegsId(uint256 tokenId_) public pure returns (uint256) {
        return _capsuleRNG(tokenId_, "LEGS", 15);
    }
    function getVehicleId(uint256 tokenId_) public pure returns (uint256) {
        return _capsuleRNG(tokenId_, "VEHICLE", 15);
    }
    function getArmsId(uint256 tokenId_) public pure returns (uint256) {
        return _capsuleRNG(tokenId_, "ARMS", 15);
    }
    function getArtifactId(uint256 tokenId_) public pure returns (uint256) {
        return _capsuleRNG(tokenId_, "ARTIFACTS", 3);
    }
    function getRingId(uint256 tokenId_) public pure returns (uint256) {
        return _capsuleRNG(tokenId_, "RINGS", 5);
    }

    function getSCGearConfig(uint256 tokenId_) external pure returns (SCGearConfig memory) {
        SCGearConfig memory _Gear = SCGearConfig(
            uint8(getWeaponId(tokenId_)),
            uint8(getChestId(tokenId_)),
            uint8(getHeadId(tokenId_)),
            uint8(getLegsId(tokenId_)),
            uint8(getVehicleId(tokenId_)),
            uint8(getArmsId(tokenId_)),
            uint8(getArtifactId(tokenId_)),
            uint8(getRingId(tokenId_))
        );

        return _Gear;
    }
}