// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Stats.sol";
import "./Damage.sol";

interface IDamageCalculator {
    function getDamageComponents(
        uint256[] calldata heroIds,
        uint256[] calldata fighterIds
    ) external view returns (Damage.DamageComponent[] memory);

    function getHeroEnhancementComponents(
        uint256[] calldata ids,
        uint8[] calldata prev
    ) external view returns (Damage.DamageComponent[] memory);

    function getFighterEnhancementComponents(
        uint256[] calldata ids,
        uint8[] calldata prev
    ) external view returns (Damage.DamageComponent[] memory);

    function getHeroDamageComponent(uint256 id)
        external
        view
        returns (Damage.DamageComponent memory);

    function getFighterDamageComponent(uint256 id)
        external
        view
        returns (Damage.DamageComponent memory);
}
