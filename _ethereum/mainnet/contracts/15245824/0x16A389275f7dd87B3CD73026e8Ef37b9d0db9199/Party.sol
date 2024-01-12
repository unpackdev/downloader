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

import "./Initializable.sol";
import "./IERC20Upgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ERC1155ReceiverUpgradeable.sol";
import "./ERC721HolderUpgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./Enhancer.sol";
import "./IParty.sol";
import "./IDamageCalculator.sol";
import "./IHero.sol";
import "./IFighter.sol";
import "./IEnhanceable.sol";
import "./IRaid.sol";
import "./Damage.sol";
import "./IGuildURIHandler.sol";

contract Party is
    IParty,
    Initializable,
    AccessControlUpgradeable,
    Enhancer,
    ERC1155ReceiverUpgradeable,
    ERC721HolderUpgradeable
{
    using Damage for Damage.DamageComponent;

    uint256 private constant FIGHTER_SLOTS = 16;

    IRaid private _raid;
    IDamageCalculator private _damageCalculator;
    IHero private _hero;
    IFighter private _fighter;
    IERC20Upgradeable private _confetti;

    mapping(address => mapping(uint256 => address)) private _ownership;
    mapping(address => PartyData) private _parties;
    mapping(address => Damage.DamageComponent) private _damage;

    IGuildURIHandler private _guild;

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address admin,
        IERC20Upgradeable confetti,
        IHero hero,
        IFighter fighter,
        IDamageCalculator damageCalculator
    ) external initializer {
        __AccessControl_init();
        _confetti = confetti;
        _hero = hero;
        _fighter = fighter;
        _damageCalculator = damageCalculator;
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /** Getters / Setters */

    function getHero() external view returns (IHero) {
        return _hero;
    }

    function getFighter() external view returns (IFighter) {
        return _fighter;
    }

    function getDamageCalculator() external view returns (IDamageCalculator) {
        return _damageCalculator;
    }

    function setDamageCalculator(IDamageCalculator calculator)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _damageCalculator = calculator;
    }

    function getRaid() external view returns (IRaid) {
        return _raid;
    }

    function setRaid(IRaid raid) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _raid = raid;
    }

    function getGuild() external view returns (IGuildURIHandler) {
        return _guild;
    }

    function setGuild(IGuildURIHandler guild)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _guild = guild;
    }

    function getConfetti() external view returns (IERC20Upgradeable) {
        return _confetti;
    }

    function getUserHero(address user)
        external
        view
        override
        returns (uint256)
    {
        return _parties[user].hero;
    }

    function getUserFighters(address user)
        public
        view
        override
        returns (uint256[] memory)
    {
        uint256[] memory fighters = new uint256[](FIGHTER_SLOTS);
        for (uint8 i = 0; i < FIGHTER_SLOTS; i++) {
            fighters[i] = _parties[user].fighters[i];
        }
        return fighters;
    }

    function getDamage(address user) external view override returns (uint32) {
        return _getDamage(user);
    }

    /** UTILITY */

    // Force update damage
    /// @dev This function may be deprecated in the near future
    function updateDamage() external {
        uint32 dmg = uint32(_getDamage(msg.sender));
        _raid.updateDamage(msg.sender, dmg);

        emit DamageUpdated(msg.sender, dmg);
    }

    // Force update damage for a given user
    function updateDamage(address user) external {
        uint32 dmg = uint32(_getDamage(user));
        _raid.updateDamage(user, dmg);

        emit DamageUpdated(user, dmg);
    }

    // Enhances a given item (hero / fighter) without requiring the token be withdrawn
    function enhance(
        Property item,
        uint8 slot,
        uint256 burnTokenId
    ) external {
        IEnhanceable handler;
        uint256 tokenId;
        IERC721Upgradeable token;

        if (item == Property.HERO) {
            require(
                _parties[msg.sender].hero != 0,
                "Party::enhance: hero not present"
            );

            token = IERC721Upgradeable(address(_hero));
            handler = IEnhanceable(address(_hero.getHandler()));
            tokenId = _parties[msg.sender].hero;
        } else {
            require(
                _parties[msg.sender].fighters[slot] != 0,
                "Party::enhance: fighter not present"
            );

            token = IERC721Upgradeable(address(_fighter));
            handler = IEnhanceable(address(_fighter.getHandler()));
            tokenId = _parties[msg.sender].fighters[slot];
        }

        (uint256 cost, bool shouldBurn) = handler.enhancementCost(tokenId);

        uint256 guildId = _guild.getGuild(msg.sender);
        if (guildId != 0) {
            // FRUGALITY: Rebate on CFTI sinks
            // 0.5% | 1% | 1.5% | 2% | 2.5%
            cost -=
                (cost *
                    _guild.getGuildTechLevel(
                        guildId,
                        IGuildURIHandler.Branch.FRUGALITY
                    )) /
                200;
        }

        if (shouldBurn) {
            token.transferFrom(msg.sender, address(this), burnTokenId);
            token.approve(address(handler), burnTokenId);
        }

        _confetti.transferFrom(msg.sender, address(this), cost);
        _confetti.approve(address(handler), cost);
        handler.enhanceFor(tokenId, burnTokenId, msg.sender);
    }

    // Reveals for a given item (hero / fighter) without requiring the token be withdrawn
    function reveal(Property item, uint8[] calldata slots) external {
        IEnhanceable handler;
        uint256[] memory tokenIds = (item == Property.HERO)
            ? new uint256[](1)
            : new uint256[](slots.length);

        if (item == Property.HERO) {
            require(
                _parties[msg.sender].hero != 0,
                "Party::enhance: hero not present"
            );

            handler = IEnhanceable(address(_hero.getHandler()));
            tokenIds[0] = _parties[msg.sender].hero;
        } else {
            handler = IEnhanceable(address(_fighter.getHandler()));

            for (uint256 i = 0; i < slots.length; i++) {
                require(
                    _parties[msg.sender].fighters[slots[i]] != 0,
                    "Party::enhance: fighter not present"
                );

                tokenIds[i] = _parties[msg.sender].fighters[slots[i]];
            }
        }

        handler.revealFor(tokenIds, msg.sender);
    }

    // Act applies multiple actions (equip / unequip) for batch execution
    function act(
        Action[] calldata heroActions,
        Action[] calldata fighterActions
    ) external override {
        require(heroActions.length <= 1, "Party::act: too many hero actions");

        uint256[] memory heroesEquipped;
        uint256[] memory heroesUnequipped;
        uint256[] memory fightersEquipped;
        uint256[] memory fightersUnequipped;

        if (heroActions.length > 0) {
            (heroesEquipped, heroesUnequipped) = _act(
                Property.HERO,
                heroActions
            );
        }

        if (fighterActions.length > 0) {
            (fightersEquipped, fightersUnequipped) = _act(
                Property.FIGHTER,
                fighterActions
            );
        }

        if (heroesEquipped.length > 0) {
            _validateParty(msg.sender);
        }

        Damage.DamageComponent[] memory curr = _damageCalculator
            .getDamageComponents(heroesEquipped, fightersEquipped);

        Damage.DamageComponent[] memory prev = _damageCalculator
            .getDamageComponents(heroesUnequipped, fightersUnequipped);

        _updateDamage(msg.sender, prev, curr);
    }

    // Equip applies an item to the callers party
    function equip(
        Property item,
        uint256 id,
        uint8 slot
    ) public override {
        uint256 unequipped = _equip(item, id, slot);

        Damage.DamageComponent[] memory prev;
        Damage.DamageComponent[] memory curr = new Damage.DamageComponent[](1);

        if (unequipped != 0) {
            prev = new Damage.DamageComponent[](1);
        }

        if (item == Property.HERO) {
            if (unequipped != 0) {
                prev[0] = _damageCalculator.getHeroDamageComponent(unequipped);
            }

            curr[0] = _damageCalculator.getHeroDamageComponent(id);
            _validateParty(msg.sender);
        } else if (item == Property.FIGHTER) {
            if (unequipped != 0) {
                prev[0] = _damageCalculator.getFighterDamageComponent(
                    unequipped
                );
            }

            curr[0] = _damageCalculator.getFighterDamageComponent(id);
        }

        _updateDamage(msg.sender, prev, curr);
    }

    // Unequip removes an item from the callers party
    function unequip(Property item, uint8 slot) public override {
        uint256 unequipped = _unequip(item, slot, msg.sender);
        Damage.DamageComponent[] memory prev = new Damage.DamageComponent[](1);

        if (item == Property.HERO) {
            prev[0] = _damageCalculator.getHeroDamageComponent(unequipped);
        } else if (item == Property.FIGHTER) {
            prev[0] = _damageCalculator.getFighterDamageComponent(unequipped);
        }

        _updateDamage(msg.sender, prev, new Damage.DamageComponent[](0));
    }

    function onEnhancement(uint256[] calldata ids, uint8[] calldata prev)
        public
        override
        returns (bytes4)
    {
        require(
            msg.sender == address(_fighter.getHandler()) ||
                msg.sender == address(_hero.getHandler()),
            "Party::onEnhancement: sender must be fighter or hero"
        );

        if (msg.sender == address(_hero.getHandler())) {
            _updateDamageEnhancement(Property.HERO, ids, prev);
        } else {
            _updateDamageEnhancement(Property.FIGHTER, ids, prev);
        }

        return super.onEnhancement(ids, prev);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlUpgradeable, ERC1155ReceiverUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC1155ReceiverUpgradeable.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector;
    }

    /** INTERNAL */

    // Compute a damage update given an array of components
    function _updateDamage(
        address user,
        Damage.DamageComponent[] memory prev,
        Damage.DamageComponent[] memory curr
    ) internal {
        _damage[user] = _damage[user].getDamageUpdate(prev, curr);

        uint32 dmg = uint32(_getDamage(user));
        _raid.updateDamage(user, dmg);

        emit DamageUpdated(user, dmg);
    }

    // Compute damage update given a prev enhancement value
    function _updateDamageEnhancement(
        Property item,
        uint256[] memory ids,
        uint8[] memory prev
    ) internal {
        require(
            ids.length == prev.length,
            "Party::onEnhancement: input length mismatch"
        );
        address token;

        if (item == Property.HERO) {
            token = address(_hero);
        } else {
            token = address(_fighter);
        }

        address owner = _ownership[token][ids[0]];
        for (uint256 i = 0; i < ids.length; i++) {
            require(
                _ownership[token][ids[i]] == owner,
                "Party::onEnhancement: tokens not owned by the same user"
            );
        }

        // Check if party size was downgraded
        if (item == Property.HERO && prev[0] >= 5) {
            IHeroURIHandler handler = IHeroURIHandler(_hero.getHandler());
            Stats.HeroStats memory stats = handler.getStats(ids[0]);
            if (
                stats.enhancement < prev[0] &&
                _parties[owner].fighters[stats.partySize] != 0
            ) {
                Damage.DamageComponent[]
                    memory adjustPrev = new Damage.DamageComponent[](1);
                uint256 u = _unequip(Property.FIGHTER, stats.partySize, owner);
                adjustPrev[0] = _damageCalculator.getFighterDamageComponent(u);
                _updateDamage(
                    owner,
                    adjustPrev,
                    new Damage.DamageComponent[](0)
                );
            }
        }

        Damage.DamageComponent[] memory prevComponents;
        Damage.DamageComponent[] memory currComponents;

        if (item == Property.HERO) {
            prevComponents = _damageCalculator.getHeroEnhancementComponents(
                ids,
                prev
            );
            currComponents = _damageCalculator.getDamageComponents(
                ids,
                new uint256[](0)
            );
        } else {
            prevComponents = _damageCalculator.getFighterEnhancementComponents(
                ids,
                prev
            );
            currComponents = _damageCalculator.getDamageComponents(
                new uint256[](0),
                ids
            );
        }

        _damage[owner] = _damage[owner].getDamageUpdate(
            prevComponents,
            currComponents
        );

        uint32 dpb = uint32(_getDamage(owner));
        _raid.updateDamage(owner, dpb);

        emit DamageUpdated(owner, dpb);
    }

    function _equip(
        Property item,
        uint256 id,
        uint8 slot
    ) internal returns (uint256 unequipped) {
        if (item == Property.HERO) {
            // Handle hero equip
            if (_parties[msg.sender].hero != 0) {
                unequipped = _unequip(item, 0, msg.sender);
            }

            _ownership[address(_hero)][id] = msg.sender;
            _parties[msg.sender].hero = id;
            _hero.transferFrom(msg.sender, address(this), id);
        } else if (item == Property.FIGHTER) {
            // Handle fighter equip
            Stats.HeroStats memory stats = IHeroURIHandler(_hero.getHandler())
                .getStats(_parties[msg.sender].hero);
            require(slot < stats.partySize, "Party::equip: bad slot");

            if (_parties[msg.sender].fighters[slot] != 0) {
                unequipped = _unequip(item, slot, msg.sender);
            }

            _ownership[address(_fighter)][id] = msg.sender;
            _parties[msg.sender].fighters[slot] = id;
            _fighter.transferFrom(msg.sender, address(this), id);
        }

        emit Equipped(msg.sender, uint8(item), slot, id);
    }

    function _unequip(
        Property item,
        uint8 slot,
        address user
    ) internal returns (uint256 id) {
        id = 0;

        if (item == Property.HERO) {
            id = _parties[user].hero;
            require(id != 0, "Party::unequip: hero not present");

            _parties[user].hero = 0;
            _ownership[address(_hero)][id] = address(0);
            _hero.transferFrom(address(this), user, id);
        } else if (item == Property.FIGHTER) {
            id = _parties[user].fighters[slot];
            require(id != 0, "Party::unequip: fighter not present");

            _parties[user].fighters[slot] = 0;
            _ownership[address(_fighter)][id] = address(0);
            _fighter.transferFrom(address(this), user, id);
        }

        emit Unequipped(user, uint8(item), slot, id);
    }

    function _act(Property item, Action[] calldata actions)
        internal
        returns (uint256[] memory, uint256[] memory)
    {
        uint256[] memory equipped = new uint256[](actions.length);
        uint256[] memory unequipped = new uint256[](actions.length);

        uint256 u = 0;

        (uint256 equipCounter, uint256 unequipCounter) = (0, 0);

        // Perform actions
        for (uint256 i = 0; i < actions.length; i++) {
            if (actions[i].action == ActionType.EQUIP) {
                u = _equip(item, actions[i].id, actions[i].slot);

                equipped[equipCounter] = actions[i].id;
                equipCounter += 1;
            } else {
                u = _unequip(item, actions[i].slot, msg.sender);
            }

            if (u != 0) {
                unequipped[unequipCounter] = u;
                unequipCounter += 1;
            }
        }

        // Reset counters and resize arrays
        assembly {
            mstore(
                equipped,
                sub(mload(equipped), sub(actions.length, equipCounter))
            )
            mstore(
                unequipped,
                sub(mload(unequipped), sub(actions.length, unequipCounter))
            )
        }

        return (equipped, unequipped);
    }

    function _validateParty(address user) internal view {
        Stats.HeroStats memory stats = IHeroURIHandler(_hero.getHandler())
            .getStats(_parties[user].hero);

        for (uint256 i = stats.partySize; i < FIGHTER_SLOTS; i++) {
            require(
                _parties[user].fighters[i] == 0,
                "Party::_equip: hero slot mismatch"
            );
        }
    }

    function _getDamage(address user) internal view returns (uint32) {
        uint256 heroId = _parties[user].hero;
        uint32 heroBaseDmg;

        if (heroId == 0) {
            return 0;
        } else if (heroId <= 1111) {
            heroBaseDmg = 1100;
        } else {
            heroBaseDmg = 800;
        }

        uint256 guildId = _guild.getGuild(user);

        if (guildId != 0) {
            IGuildURIHandler.TechTree memory tree = _guild.getGuildTechTree(
                guildId
            );

            // DISCIPLINE: Flat damage buff
            // 2 * heroBaseDmg * (heroLevel + 1) * perkLevel
            uint8 heroLevel = IHeroURIHandler(_hero.getHandler())
                .getStats(heroId)
                .enhancement;
            uint32 gDmg = 2 * heroBaseDmg * (heroLevel + 1) * tree.discipline;

            // MORALE: Damage multiplier
            // 1.5% | 3% | 5% | 7% | 10%
            uint32 gMulti;
            if (tree.morale == 1) {
                gMulti = 15;
            } else if (tree.morale == 2) {
                gMulti = 30;
            } else if (tree.morale == 3) {
                gMulti = 50;
            } else if (tree.morale == 4) {
                gMulti = 70;
            } else if (tree.morale == 5) {
                gMulti = 100;
            }

            return
                ((uint32(_damage[user].computeDamage()) + heroBaseDmg) *
                    (1000 + gMulti)) /
                1000 +
                gDmg;
        }

        return uint32(_damage[user].computeDamage()) + heroBaseDmg;
    }
}
