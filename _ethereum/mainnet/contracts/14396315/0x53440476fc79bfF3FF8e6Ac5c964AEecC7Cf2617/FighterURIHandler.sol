// SPDX-License-Identifier: MIT

/// @title RaidParty Fighter URI Handler

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
import "./IFighterURIHandler.sol";
import "./IERC20Burnable.sol";
import "./IFighter.sol";

contract FighterURIHandler is
    IFighterURIHandler,
    Initializable,
    Enhanceable,
    AccessControlEnumerableUpgradeable,
    ERC721HolderUpgradeable
{
    using StringsUpgradeable for uint256;

    // Contract state and constants
    uint32 public constant MAX_DMG = 1400;
    uint32 public constant MIN_DMG = 800;
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
        address fighter,
        address confetti
    ) public initializer {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        __Enhanceable_init(seeder, fighter);
        _confetti = IERC20Burnable(confetti);
        _team = admin;
        _paused = true;
    }

    // Returns on-chain stats for a given token
    function getStats(uint256 tokenId)
        public
        view
        override
        returns (Stats.FighterStats memory)
    {
        uint256 seed = _seeder.getSeedSafe(address(_token), tokenId);
        uint32 range = MAX_DMG - MIN_DMG + 1;

        return
            Stats.FighterStats(
                MIN_DMG + uint32(seed % range),
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
        return (_getEnhancementCost(_enhancement[tokenId]), true);
    }

    function enhance(uint256 tokenId, uint256 burnTokenId)
        public
        override(Enhanceable, IEnhanceable)
        whenNotPaused
    {
        require(
            tokenId != burnTokenId,
            "FighterURIHandler::enhance: target token cannot equal burn token"
        );
        require(
            msg.sender == _token.ownerOf(tokenId),
            "FighterURIHandler::enhance: enhancer must be token owner"
        );
        uint8 enhancement = _enhancement[tokenId];
        require(
            enhancement < MAX_ENHANCEMENT,
            "FighterURIHandler::enhance: max enhancement reached"
        );
        uint256 cost = _getEnhancementCost(enhancement);
        uint256 teamAmount = (cost * 15) / 100;
        _confetti.transferFrom(msg.sender, _team, teamAmount);
        _confetti.burnFrom(msg.sender, cost - teamAmount);

        _token.safeTransferFrom(msg.sender, address(this), burnTokenId);
        _token.burn(burnTokenId);

        super.enhance(tokenId, burnTokenId);
    }

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

    /** INTERNAL */

    function _baseURI() internal pure returns (string memory) {
        return "https://api.raid.party/metadata/fighter/";
    }

    function _getEnhancementCost(uint256 enh) internal pure returns (uint256) {
        if (enh == 0) {
            return 25 * 10**18;
        } else if (enh == 1) {
            return 35 * 10**18;
        } else if (enh == 2) {
            return 50 * 10**18;
        } else if (enh == 3) {
            return 75 * 10**18;
        } else if (enh == 4) {
            return 100 * 10**18;
        } else if (enh == 5) {
            return 125 * 10**18;
        } else if (enh == 6) {
            return 150 * 10**18;
        } else if (enh == 7) {
            return 300 * 10**18;
        } else if (enh == 8) {
            return 350 * 10**18;
        } else if (enh == 9) {
            return 500 * 10**18;
        } else if (enh == 10) {
            return 500 * 10**18;
        } else if (enh == 11) {
            return 500 * 10**18;
        } else if (enh == 12) {
            return 500 * 10**18;
        } else if (enh == 13) {
            return 500 * 10**18;
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
