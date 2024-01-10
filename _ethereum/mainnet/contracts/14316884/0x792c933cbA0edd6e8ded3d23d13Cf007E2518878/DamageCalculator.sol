// SPDX-License-Identifier: MIT

/// @title RaidParty Party Contract

/**
 *   ___      _    _ ___          _
 *  | _ \__ _(_)__| | _ \__ _ _ _| |_ _  _
 *  |   / _` | / _` |  _/ _` | '_|  _| || |
 *  |_|_\__,_|_\__,_|_| \__,_|_|  \__|\_, |
 *                                    |__/
 */

pragma solidity ^0.8.0;

import "./IParty.sol";
import "./IDamageCalculator.sol";
import "./IHero.sol";
import "./IFighter.sol";
import "./IHeroURIHandler.sol";
import "./IFighterURIHandler.sol";
import "./Damage.sol";

contract DamageCalculator is IDamageCalculator {
    IHero private _hero;
    IFighter private _fighter;

    uint32 private constant PRECISION = 1000;

    constructor(address hero, address fighter) {
        _hero = IHero(hero);
        _fighter = IFighter(fighter);
    }

    function getHero() external view returns (address) {
        return address(_hero);
    }

    function getFighter() external view returns (address) {
        return address(_fighter);
    }

    // getDamageComponents computes and returns a large array of damage components maintaining input ordering
    function getDamageComponents(
        uint256[] calldata heroIds,
        uint256[] calldata fighterIds
    ) external view override returns (Damage.DamageComponent[] memory) {
        // Initialize equipped array
        Damage.DamageComponent[]
            memory components = new Damage.DamageComponent[](
                heroIds.length + fighterIds.length
            );
        uint256 idx;

        idx = _getHeroComponents(components, heroIds, idx);
        idx = _getFighterComponents(components, fighterIds, idx);

        return components;
    }

    // Returns a hero damage component given an enhancement value
    function getHeroEnhancementComponents(
        uint256[] calldata ids,
        uint8[] calldata prev
    ) external view override returns (Damage.DamageComponent[] memory) {
        Damage.DamageComponent[]
            memory components = new Damage.DamageComponent[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            components[i] = _getHeroDamageComponentEnhancement(ids[i], prev[i]);
        }
        return components;
    }

    // Returns a fighter damage component given an enhancement value
    function getFighterEnhancementComponents(
        uint256[] calldata ids,
        uint8[] calldata prev
    ) external view override returns (Damage.DamageComponent[] memory) {
        Damage.DamageComponent[]
            memory components = new Damage.DamageComponent[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            components[i] = _getFighterDamageComponentEnhancement(
                ids[i],
                prev[i]
            );
        }
        return components;
    }

    // Returns a hero damage component
    function getHeroDamageComponent(uint256 hero)
        external
        view
        override
        returns (Damage.DamageComponent memory)
    {
        return _getHeroDamageComponent(hero);
    }

    // Returns a fighter damage component
    function getFighterDamageComponent(uint256 fighter)
        external
        view
        override
        returns (Damage.DamageComponent memory)
    {
        return _getFighterDamageComponent(fighter);
    }

    // Collection of internal functions to get property damage components
    function _getFighterDamageComponent(uint256 id)
        internal
        view
        returns (Damage.DamageComponent memory)
    {
        Stats.FighterStats memory fStats = IFighterURIHandler(
            _fighter.getHandler()
        ).getStats(id);

        return
            Damage.DamageComponent(
                0,
                uint32(
                    fStats.dmg +
                        _getFighterEnhancementAdjustment(
                            fStats.enhancement,
                            fStats.dmg
                        )
                )
            );
    }

    function _getHeroDamageComponent(uint256 id)
        internal
        view
        returns (Damage.DamageComponent memory)
    {
        Stats.HeroStats memory hStats = IHeroURIHandler(_hero.getHandler())
            .getStats(id);

        return
            Damage.DamageComponent(
                uint32(
                    hStats.dmgMultiplier +
                        _getHeroEnhancementMultiplier(hStats.enhancement, id)
                ),
                0
            );
    }

    // Collection of internal functions to get property damage components with caller provided enhancement values
    function _getFighterDamageComponentEnhancement(
        uint256 id,
        uint8 enhancement
    ) internal view returns (Damage.DamageComponent memory) {
        Stats.FighterStats memory fStats = IFighterURIHandler(
            _fighter.getHandler()
        ).getStats(id);

        return
            Damage.DamageComponent(
                0,
                uint32(
                    fStats.dmg +
                        _getFighterEnhancementAdjustment(
                            enhancement,
                            fStats.dmg
                        )
                )
            );
    }

    function _getHeroDamageComponentEnhancement(uint256 id, uint8 enhancement)
        internal
        view
        returns (Damage.DamageComponent memory)
    {
        Stats.HeroStats memory hStats = IHeroURIHandler(_hero.getHandler())
            .getStats(id);

        return
            Damage.DamageComponent(
                uint32(
                    hStats.dmgMultiplier +
                        _getHeroEnhancementMultiplier(enhancement, id)
                ),
                0
            );
    }

    // Collection of internal functions to return components to caller provided component array
    function _getHeroComponents(
        Damage.DamageComponent[] memory components,
        uint256[] memory heroes,
        uint256 idx
    ) internal view returns (uint256) {
        for (uint256 i = 0; i < heroes.length; i++) {
            components[idx] = _getHeroDamageComponent(heroes[i]);
            idx += 1;
        }

        return idx;
    }

    function _getFighterComponents(
        Damage.DamageComponent[] memory components,
        uint256[] memory fighters,
        uint256 idx
    ) internal view returns (uint256) {
        for (uint256 i = 0; i < fighters.length; i++) {
            components[idx] = _getFighterDamageComponent(fighters[i]);
            idx += 1;
        }

        return idx;
    }

    // Collection of internal functions for enhancement computations
    function _getHeroEnhancementMultiplier(uint8 enhancement, uint256 tokenId)
        internal
        pure
        returns (uint8 multiplier)
    {
        if (tokenId <= 1111 && enhancement >= 5) {
            multiplier = 4 + 3 * (enhancement - 4);
        } else if (enhancement >= 5) {
            multiplier = 4 + 2 * (enhancement - 4);
        } else {
            multiplier = enhancement;
        }
    }

    function _getFighterEnhancementAdjustment(uint8 enhancement, uint32 damage)
        internal
        pure
        returns (uint32)
    {
        if (enhancement == 0) {
            return 0;
        } else if (enhancement == 1) {
            return (160 * damage) / 100;
        } else if (enhancement == 2) {
            return (254 * damage) / 100;
        } else if (enhancement == 3) {
            return (320 * damage) / 100;
        } else if (enhancement == 4) {
            return (372 * damage) / 100;
        } else if (enhancement == 5) {
            return (414 * damage) / 100;
        } else if (enhancement == 6) {
            return (449 * damage) / 100;
        } else if (enhancement == 7) {
            return (480 * damage) / 100;
        } else if (enhancement == 8) {
            return (507 * damage) / 100;
        } else if (enhancement == 9) {
            return (532 * damage) / 100;
        } else if (enhancement == 10) {
            return (554 * damage) / 100;
        } else if (enhancement == 11) {
            return (574 * damage) / 100;
        } else if (enhancement == 12) {
            return (592 * damage) / 100;
        } else if (enhancement == 13) {
            return (609 * damage) / 100;
        } else if (enhancement == 14) {
            return (625 * damage) / 100;
        }

        return 0;
    }
}
