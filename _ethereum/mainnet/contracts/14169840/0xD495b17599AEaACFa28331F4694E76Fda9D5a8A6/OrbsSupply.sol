//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

abstract contract OrbsSupply {
    uint256 private constant MERCURY = 0;
    uint256 private constant VENUS = 1;
    uint256 private constant MARS = 2;
    uint256 private constant JUPITER = 3;
    uint256 private constant SATURN = 4;
    uint256 private constant URANUS = 5;
    uint256 private constant NEPTUNE = 6;
    uint256 private constant GAIA = 7;
    uint256 private constant SOL = 8;
    uint256 private constant LUNA = 9;

    /**
     * @notice Returns the orb type given a random index
     * @param mintIndex Index to mint for the current sender
     */
    function getOrbType(uint256 mintIndex) internal view returns (uint256) {
        uint256 index = getOrbIndex(mintIndex);

        if (index >= 0 && index < 13) {
            return MERCURY;
        }
        if (index > 12 && index < 26) {
            return VENUS;
        }
        if (index > 25 && index < 39) {
            return MARS;
        }
        if (index > 38 && index < 52) {
            return JUPITER;
        }
        if (index > 51 && index < 65) {
            return SATURN;
        }
        if (index > 64 && index < 78) {
            return URANUS;
        }
        if (index > 77 && index < 91) {
            return NEPTUNE;
        }
        if (index > 90 && index < 94) {
            return GAIA;
        }
        if (index > 93 && index < 97) {
            return SOL;
        }
        return LUNA;
    }

    /**
     * @notice Returns the orb index for a given minter and the mint index
     * @dev mint index is for those who mint more than one so they don't get the same type for every mint
     */
    function getOrbIndex(uint256 mintIndex) private view returns (uint256) {
        return
            uint256(keccak256(abi.encodePacked(msg.sender, mintIndex))) % 100;
    }
}
