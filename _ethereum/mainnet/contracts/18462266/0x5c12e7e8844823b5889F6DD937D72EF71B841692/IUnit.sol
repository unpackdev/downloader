// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IUnit {
    struct UnitTemplate {
        uint256 id;
        string name;
        uint256 level;
        uint256 generation;
        string corporation;
        string model;
        string description;
        string image;
        uint256[] values;
        string rarity;
        uint256 modSlots;
    }

    struct Unit {
        uint256 template;
        uint256 visual;
        uint256[] mods;
    }

    event UnitTemplateCreated(UnitTemplate);
    event UnitTemplateUpdated(UnitTemplate);

    function createUnitTemplate(UnitTemplate calldata _unitTemplate) external;

    function updateUnitTemplate(
        uint256,
        UnitTemplate calldata _unitTemplate
    ) external;
}
