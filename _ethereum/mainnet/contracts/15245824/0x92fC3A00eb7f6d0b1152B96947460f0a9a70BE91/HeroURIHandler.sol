// SPDX-License-Identifier: MIT

/// @title RaidParty Hero URI Handler

/**
 *   ___      _    _ ___          _
 *  | _ \__ _(_)__| | _ \__ _ _ _| |_ _  _
 *  |   / _` | / _` |  _/ _` | '_|  _| || |
 *  |_|_\__,_|_\__,_|_| \__,_|_|  \__|\_, |
 *                                    |__/
 */

pragma solidity ^0.8.0;

import "./StringsUpgradeable.sol";
import "./Initializable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./ERC721HolderUpgradeable.sol";
import "./MathUpgradeable.sol";
import "./Enhanceable.sol";
import "./IHeroURIHandler.sol";
import "./IHero.sol";
import "./IERC20Burnable.sol";
import "./IGuildURIHandler.sol";

contract HeroURIHandler is
    IHeroURIHandler,
    Initializable,
    Enhanceable,
    AccessControlEnumerableUpgradeable,
    ERC721HolderUpgradeable
{
    using StringsUpgradeable for uint256;

    // Contract state and constants
    uint8 public constant MAX_DMG_MULTIPLIER = 17;
    uint8 public constant MIN_DMG_MULTIPLIER = 12;
    uint8 public constant MIN_DMG_MULTIPLIER_GENESIS = 13;
    uint8 public constant MAX_PARTY_SIZE = 6;
    uint8 public constant MIN_PARTY_SIZE = 4;
    uint8 public constant MAX_ENHANCEMENT = 14;
    uint8 public constant MIN_ENHANCEMENT = 0;

    mapping(uint256 => uint8) private _enhancement;
    IERC20Burnable private _confetti;
    address private _team;
    bool private _paused;

    IGuildURIHandler private _guild;
    bytes32 public constant CALL_FOR_ROLE = keccak256("CALL_FOR_ROLE");

    modifier whenNotPaused() {
        require(!_paused, "FighterURIHandler: contract paused");
        _;
    }

    /** PUBLIC */

    function initialize(
        address admin,
        address seeder,
        address hero,
        address confetti
    ) public initializer {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        __Enhanceable_init(seeder, hero);
        _confetti = IERC20Burnable(confetti);
        _team = admin;
        _paused = true;
    }

    // Returns on-chain stats for a given token
    function getStats(uint256 tokenId)
        public
        view
        override
        returns (Stats.HeroStats memory)
    {
        uint256 seed = _seeder.getSeedSafe(address(_token), tokenId);
        uint8 enh = _enhancement[tokenId];
        uint8 adjustment = _getPartySizeAdjustment(enh);

        if (tokenId <= 1111) {
            uint8 dmgMulRange = MAX_DMG_MULTIPLIER -
                MIN_DMG_MULTIPLIER_GENESIS +
                1;

            return
                Stats.HeroStats(
                    MIN_DMG_MULTIPLIER_GENESIS + 1 + uint8(seed % dmgMulRange),
                    6 + adjustment,
                    enh
                );
        } else {
            uint8 dmgMulRange = MAX_DMG_MULTIPLIER - MIN_DMG_MULTIPLIER + 1;
            uint8 pSizeRange = MAX_PARTY_SIZE - MIN_PARTY_SIZE + 1;

            return
                Stats.HeroStats(
                    MIN_DMG_MULTIPLIER + uint8(seed % dmgMulRange),
                    MIN_PARTY_SIZE +
                        adjustment +
                        uint8(
                            uint256(keccak256(abi.encodePacked(seed))) %
                                pSizeRange
                        ),
                    enh
                );
        }
    }

    // Returns the seeder contract address
    function getSeeder() external view override returns (address) {
        return address(_seeder);
    }

    // Sets the seeder contract address
    function setSeeder(address seeder) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setSeeder(seeder);
    }

    // Returns the guild contract address
    function getGuild() external view override returns (address) {
        return address(_guild);
    }

    // Sets the guild contract address
    function setGuild(IGuildURIHandler guild)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _guild = guild;
    }

    // Returns the token URI for off-chain cosmetic data
    function tokenURI(uint256 tokenId) public pure returns (string memory) {
        return string(abi.encodePacked(_baseURI(), tokenId.toString()));
    }

    /** ENHANCEMENT */

    // Returns enhancement cost in confetti, and whether a token must be burned
    function enhancementCost(uint256 tokenId)
        external
        view
        override(IEnhanceable, Enhanceable)
        returns (uint256, bool)
    {
        return (
            _getEnhancementCost(_enhancement[tokenId]),
            _enhancement[tokenId] > 3
        );
    }

    function enhance(uint256 tokenId, uint256 burnTokenId)
        public
        override(IEnhanceable, Enhanceable)
        whenNotPaused
    {
        _enhance(tokenId, burnTokenId, msg.sender);
    }

    function enhanceFor(
        uint256 tokenId,
        uint256 burnTokenId,
        address user
    ) public override whenNotPaused onlyRole(CALL_FOR_ROLE) {
        _enhance(tokenId, burnTokenId, user);
    }

    function reveal(uint256[] calldata tokenIds) public override whenNotPaused {
        _reveal(tokenIds, msg.sender);
    }

    function revealFor(uint256[] calldata tokenIds, address user)
        public
        override
        whenNotPaused
        onlyRole(CALL_FOR_ROLE)
    {
        _reveal(tokenIds, user);
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _paused = true;
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _paused = false;
    }

    function isGenesis(uint256 tokenId) external pure returns (bool) {
        return tokenId <= 1111;
    }

    /** INTERNAL */

    function _getPartySizeAdjustment(uint8 enhancement)
        internal
        pure
        returns (uint8 adjustment)
    {
        if (enhancement >= 5) {
            adjustment = enhancement - 4;
        }
    }

    function _baseURI() internal pure returns (string memory) {
        return "https://api.raid.party/metadata/hero/";
    }

    function _getEnhancementCost(uint256 enh) internal pure returns (uint256) {
        if (enh == 0) {
            return 250 * 10**18;
        } else if (enh == 1) {
            return 500 * 10**18;
        } else if (enh == 2) {
            return 750 * 10**18;
        } else if (enh == 3) {
            return 1000 * 10**18;
        } else if (enh == 4) {
            return 1250 * 10**18;
        } else if (enh == 5) {
            return 1500 * 10**18;
        } else if (enh == 6) {
            return 1750 * 10**18;
        } else if (enh == 7) {
            return 2000 * 10**18;
        } else if (enh == 8) {
            return 2250 * 10**18;
        } else if (enh == 9) {
            return 2500 * 10**18;
        } else if (enh == 10) {
            return 2500 * 10**18;
        } else if (enh == 11) {
            return 2500 * 10**18;
        } else if (enh == 12) {
            return 2500 * 10**18;
        } else if (enh == 13) {
            return 2500 * 10**18;
        } else {
            return type(uint256).max;
        }
    }

    function _getEnhancementOdds(uint256 enh) internal pure returns (uint256) {
        if (enh == 0) {
            return 9000;
        } else if (enh == 1) {
            return 8500;
        } else if (enh == 2) {
            return 8000;
        } else if (enh == 3) {
            return 7500;
        } else if (enh == 4) {
            return 7000;
        } else if (enh == 5) {
            return 6500;
        } else if (enh == 6) {
            return 6000;
        } else if (enh == 7) {
            return 5500;
        } else if (enh == 8) {
            return 5000;
        } else {
            return 2500;
        }
    }

    function _getEnhancementDegredationOdds(uint256 enh)
        internal
        pure
        returns (uint256)
    {
        if (enh == 0) {
            return 0;
        } else if (enh == 1) {
            return 500;
        } else if (enh == 2) {
            return 1000;
        } else if (enh == 3) {
            return 1500;
        } else if (enh == 4) {
            return 2000;
        } else if (enh == 5) {
            return 2500;
        } else if (enh == 6) {
            return 3000;
        } else if (enh == 7) {
            return 3500;
        } else if (enh == 8) {
            return 4000;
        } else {
            return 5000;
        }
    }

    function _enhance(
        uint256 tokenId,
        uint256 burnTokenId,
        address user
    ) internal {
        require(
            tokenId != burnTokenId,
            "HeroURIHandler::enhance: target token cannot equal burn token"
        );
        require(
            msg.sender == _token.ownerOf(tokenId),
            "HeroURIHandler::enhance: enhancer must be token owner"
        );
        uint8 enhancement = _enhancement[tokenId];
        require(
            enhancement < MAX_ENHANCEMENT,
            "HeroURIHandler::enhance: max enhancement reached"
        );

        uint256 cost = _getEnhancementCost(enhancement);
        uint256 guildId = _guild.getGuild(user);
        if (guildId != 0) {
            cost -=
                (cost *
                    _guild.getGuildTechLevel(
                        guildId,
                        IGuildURIHandler.Branch.FRUGALITY
                    )) /
                200;
        }

        uint256 teamAmount = (cost * 15) / 100;
        _confetti.transferFrom(msg.sender, _team, teamAmount);
        _confetti.burnFrom(msg.sender, cost - teamAmount);

        if (enhancement > 3) {
            _token.safeTransferFrom(msg.sender, address(this), burnTokenId);
            _token.burn(burnTokenId);
        }

        super.enhance(tokenId, burnTokenId);
    }

    function _reveal(uint256[] calldata tokenIds, address user) internal {
        unchecked {
            uint256 guildId = _guild.getGuild(user);
            uint256 indemnityBuff;
            uint256 superstitionBuff;
            uint256 fortuneBuff;

            if (guildId != 0) {
                IGuildURIHandler.TechTree memory tree = _guild.getGuildTechTree(
                    guildId
                );

                // INDEMNITY: Second-wind chance on failure
                // 1% | 2% | 3% | 4% | 10%
                indemnityBuff =
                    ((tree.indemnity == 5) ? 10 : tree.indemnity) *
                    100;

                // SUPERSTITION: Downgrade chance decrease
                // 1% | 2% | 3% | 4% | 5%
                superstitionBuff = tree.superstition * 100;

                // FORTUNE: Enhancement success chance increase
                // 1% | 2% | 3% | 4% | 5%
                fortuneBuff = tree.fortune * 100;
            }

            uint8[] memory enhancements = new uint8[](tokenIds.length);
            for (uint256 i = 0; i < tokenIds.length; i++) {
                require(
                    _token.ownerOf(tokenIds[i]) == msg.sender,
                    "HeroURIHandler::reveal: revealer not owner"
                );

                enhancements[i] = _enhancement[tokenIds[i]];

                uint256 successOdds = _getEnhancementOdds(enhancements[i]);
                successOdds = MathUpgradeable.min(
                    10000,
                    successOdds + fortuneBuff
                );

                uint256 degradeOdds = _getEnhancementDegredationOdds(
                    enhancements[i]
                );
                degradeOdds = (superstitionBuff >= degradeOdds ||
                    enhancements[i] <= MIN_ENHANCEMENT)
                    ? 0
                    : degradeOdds - superstitionBuff;

                (bool success, bool degraded) = _rollEnhancement(
                    _getSeed(tokenIds[i]),
                    successOdds,
                    degradeOdds,
                    indemnityBuff
                );

                if (success) {
                    _enhancement[tokenIds[i]] += 1;
                } else if (degraded) {
                    _enhancement[tokenIds[i]] -= 1;
                }

                emit EnhancementCompleted(
                    tokenIds[i],
                    block.timestamp,
                    success,
                    degraded
                );
            }

            super._reveal(tokenIds);

            require(
                _checkOnEnhancement(tokenIds, enhancements),
                "Enhanceable::reveal: reveal for unsupported contract"
            );
        }
    }

    function _rollEnhancement(
        uint256 seed,
        uint256 successOdds,
        uint256 degradeOdds,
        uint256 secondWindOdds
    ) internal pure returns (bool, bool) {
        bool success = false;
        bool degraded = false;

        // Roll for success using initial seed
        if (successOdds >= 10000 || _roll(seed, successOdds)) {
            success = true;
        } else {
            seed = uint256(keccak256(abi.encode(seed)));
            if (secondWindOdds > 0 && _roll(seed, secondWindOdds)) {
                // Attempt a static second-wind roll with new seed if indemnity has
                // been leveled up, otherwise continue with degrade roll.
                success = true;
            } else if (
                // Attempt another independent roll for enhancement downgrade
                degradeOdds > 0 &&
                _roll(uint256(keccak256(abi.encode(seed))), degradeOdds)
            ) {
                degraded = true;
            }
        }

        return (success, degraded);
    }
}
