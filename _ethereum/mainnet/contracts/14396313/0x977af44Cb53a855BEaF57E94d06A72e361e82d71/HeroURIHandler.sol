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
import "./Enhanceable.sol";
import "./IHeroURIHandler.sol";
import "./IHero.sol";
import "./IERC20Burnable.sol";

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

    // Returns the token URI for off-chain cosmetic data
    function tokenURI(uint256 tokenId) public pure returns (string memory) {
        return string(abi.encodePacked(_baseURI(), tokenId.toString()));
    }

    /** ENHANCEMENT */

    // Returns enhancement cost in confetti, and whether a token must be burned
    function enhancementCost(uint256 tokenId)
        external
        view
        override(Enhanceable, IEnhanceable)
        returns (uint256, bool)
    {
        return (
            _getEnhancementCost(_enhancement[tokenId]),
            _enhancement[tokenId] > 3
        );
    }

    function enhance(uint256 tokenId, uint256 burnTokenId)
        public
        override(Enhanceable, IEnhanceable)
        whenNotPaused
    {
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
        uint256 teamAmount = (cost * 15) / 100;
        _confetti.transferFrom(msg.sender, _team, teamAmount);
        _confetti.burnFrom(msg.sender, cost - teamAmount);

        if (enhancement > 3) {
            _token.safeTransferFrom(msg.sender, address(this), burnTokenId);
            _token.burn(burnTokenId);
        }

        super.enhance(tokenId, burnTokenId);
    }

    // Caller must emit and determine resultant state before calling super
    function reveal(uint256[] calldata tokenIds) public override whenNotPaused {
        unchecked {
            uint8[] memory enhancements = new uint8[](tokenIds.length);
            for (uint256 i = 0; i < tokenIds.length; i++) {
                uint256 seed = _getSeed(tokenIds[i]);
                uint8 enhancement = _enhancement[tokenIds[i]];
                bool success = false;
                bool degraded = false;

                if (_roll(seed, _getEnhancementOdds(enhancement))) {
                    _enhancement[tokenIds[i]] += 1;
                    success = true;
                } else if (
                    _roll(
                        uint256(keccak256(abi.encode(seed))),
                        _getEnhancementDegredationOdds(enhancement)
                    ) && enhancement > MIN_ENHANCEMENT
                ) {
                    _enhancement[tokenIds[i]] -= 1;
                    degraded = true;
                }

                enhancements[i] = enhancement;

                emit EnhancementCompleted(
                    tokenIds[i],
                    block.timestamp,
                    success,
                    degraded
                );
            }

            super.reveal(tokenIds);

            require(
                _checkOnEnhancement(tokenIds, enhancements),
                "Enhanceable::reveal: reveal for unsupported contract"
            );
        }
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
}
