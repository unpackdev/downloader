
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITraitRegistry {
    function getImplementer(uint16 traitID) external view returns (address);
    function addressCanModifyTrait(address, uint16) external view returns (bool);
    function addressCanModifyTraits(address, uint16[] memory) external view returns (bool);
    function hasTrait(uint16 traitID, uint16 tokenID) external view returns (bool);
    function setTrait(uint16 traitID, uint16 tokenID, bool) external;
    function setTraitOnTokens(uint16 traitID, uint16[] memory tokenID, bool[] memory) external;
    function owner() external view returns (address);
    function contractController(address) external view returns (bool);
}
