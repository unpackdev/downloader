// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IChainRunnersBaseRenderer {
    function getRaceIndex(uint16 _dna) external view returns (uint8);

    function getLayerIndex(
        uint16 _dna,
        uint8 _index,
        uint16 _raceIndex
    ) external view returns (uint8);
}
