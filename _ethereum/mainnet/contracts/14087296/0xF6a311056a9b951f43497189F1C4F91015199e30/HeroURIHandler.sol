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
import "./Enhanceable.sol";
import "./IHeroURIHandler.sol";
import "./IHero.sol";
import "./IConfetti.sol";

contract HeroURIHandler is
    IHeroURIHandler,
    Initializable,
    Enhanceable,
    AccessControlEnumerableUpgradeable
{
    using StringsUpgradeable for uint256;

    // Contract state and constants
    uint8 public constant MAX_DMG_MULTIPLIER = 17;
    uint8 public constant MIN_DMG_MULTIPLIER = 12;
    uint8 public constant MAX_PARTY_SIZE = 6;
    uint8 public constant MIN_PARTY_SIZE = 4;
    uint8 public constant MAX_ENHANCEMENT = 14;
    uint8 public constant MIN_ENHANCEMENT = 0;

    mapping(uint8 => uint256) private _enhancementCosts;
    mapping(uint8 => uint256) private _enhancementOdds;
    mapping(uint8 => uint256) private _enhancementDegredationOdds;
    mapping(uint256 => uint8) private _enhancement;
    IConfetti private _confetti;
    address private _team;

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
        _confetti = IConfetti(confetti);
        _team = admin;

        // Initialize enhancement costs
        _enhancementCosts[0] = 250 * 10**18;
        _enhancementCosts[1] = 300 * 10**18;
        _enhancementCosts[2] = 450 * 10**18;
        _enhancementCosts[3] = 500 * 10**18;
        _enhancementCosts[4] = 575 * 10**18;
        _enhancementCosts[5] = 650 * 10**18;
        _enhancementCosts[6] = 800 * 10**18;
        _enhancementCosts[7] = 1000 * 10**18;
        _enhancementCosts[8] = 1250 * 10**18;
        _enhancementCosts[9] = 1500 * 10**18;
        _enhancementCosts[10] = 2000 * 10**18;
        _enhancementCosts[11] = 2000 * 10**18;
        _enhancementCosts[12] = 2000 * 10**18;
        _enhancementCosts[13] = 2000 * 10**18;

        // Initialize enhancement odds
        _enhancementOdds[0] = 8500;
        _enhancementOdds[1] = 7500;
        _enhancementOdds[2] = 6500;
        _enhancementOdds[3] = 5500;
        _enhancementOdds[4] = 4500;
        _enhancementOdds[5] = 3500;
        _enhancementOdds[6] = 3000;
        _enhancementOdds[7] = 2500;
        _enhancementOdds[8] = 2000;
        _enhancementOdds[9] = 1000;
        _enhancementOdds[10] = 500;
        _enhancementOdds[11] = 500;
        _enhancementOdds[12] = 500;
        _enhancementOdds[13] = 500;

        // Initialize enhancement odds
        _enhancementDegredationOdds[0] = 0;
        _enhancementDegredationOdds[1] = 0;
        _enhancementDegredationOdds[2] = 2500;
        _enhancementDegredationOdds[3] = 2500;
        _enhancementDegredationOdds[4] = 2500;
        _enhancementDegredationOdds[5] = 3500;
        _enhancementDegredationOdds[6] = 3500;
        _enhancementDegredationOdds[7] = 3500;
        _enhancementDegredationOdds[8] = 4000;
        _enhancementDegredationOdds[9] = 4500;
        _enhancementDegredationOdds[10] = 5000;
        _enhancementDegredationOdds[11] = 5000;
        _enhancementDegredationOdds[12] = 5000;
        _enhancementDegredationOdds[13] = 5000;
    }

    // Returns on-chain stats for a given token
    function getStats(uint256 tokenId)
        public
        view
        override
        returns (Stats.HeroStats memory)
    {
        uint256 seed = _seeder.getSeedSafe(address(_token), tokenId);
        uint8 dmgMulRange = MAX_DMG_MULTIPLIER - MIN_DMG_MULTIPLIER + 1;
        uint8 pSizeRange = MAX_PARTY_SIZE - MIN_PARTY_SIZE + 1;

        return
            Stats.HeroStats(
                MIN_DMG_MULTIPLIER + uint8(seed % dmgMulRange),
                MIN_PARTY_SIZE +
                    uint8(
                        uint256(keccak256(abi.encodePacked(seed))) % pSizeRange
                    ),
                _enhancement[tokenId]
            );
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
            _enhancementCosts[_enhancement[tokenId]],
            _enhancement[tokenId] > 2
        );
    }

    function enhance(uint256 tokenId, uint256 burnTokenId)
        public
        override(Enhanceable, IEnhanceable)
    {
        uint8 enhancement = _enhancement[tokenId];
        require(
            enhancement < MAX_ENHANCEMENT,
            "HeroURIHandler::enhance: max enhancement reached"
        );
        uint256 cost = _enhancementCosts[enhancement];

        _confetti.transferFrom(msg.sender, address(this), cost);
        uint256 teamAmount = (cost * 20) / 100;
        _confetti.transfer(_team, teamAmount);
        _confetti.burn(cost - teamAmount);

        if (enhancement > 2) {
            _token.safeTransferFrom(msg.sender, address(this), burnTokenId);
            _token.burn(burnTokenId);
        }

        super.enhance(tokenId, burnTokenId);
    }

    // Caller must emit and determine resultant state before calling super
    function reveal(uint256[] calldata tokenIds) public override {
        unchecked {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                uint256 seed = _getSeed(tokenIds[i]);
                uint8 enhancement = _enhancement[tokenIds[i]];
                bool success = false;
                bool degraded = false;

                if (_roll(seed, _enhancementOdds[enhancement])) {
                    _enhancement[tokenIds[i]] += 1;
                    success = true;
                } else if (
                    _roll(
                        seed,
                        _enhancementOdds[enhancement] +
                            _enhancementDegredationOdds[enhancement]
                    ) && enhancement > MIN_ENHANCEMENT
                ) {
                    _enhancement[tokenIds[i]] -= 1;
                    degraded = true;
                }

                emit EnhancementCompleted(
                    tokenIds[i],
                    block.timestamp,
                    success,
                    degraded
                );
            }

            super.reveal(tokenIds);
        }
    }

    function isGenesis(uint256 tokenId) external pure returns (bool) {
        return tokenId <= 1111;
    }

    /** INTERNAL */

    function _baseURI() internal pure returns (string memory) {
        return "https://api.raid.party/metadata/hero/";
    }
}
