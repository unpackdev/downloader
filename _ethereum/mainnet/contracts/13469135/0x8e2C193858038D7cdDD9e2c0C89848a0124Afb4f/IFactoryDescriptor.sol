// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "./ITheCreepz.sol";

interface IFactoryDescriptor {
    function getCreepz(ITheCreepz.Creepz memory) external view returns (string memory);
    function getDefs(ITheCreepz.Creepz memory) external view returns (string memory);
    function getArtItems(ITheCreepz.Creepz memory) external view returns (string[17] memory);

}
