// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./errors.sol";
import "./IURIBuilder.sol";
import "./Property.sol";
import "./TraitSet.sol";
import "./Random.sol";

contract Ship is Property {
    struct ShipParams {
        uint128 base;
        uint8 flags;
        uint8 maxHealth;
        uint8 minHealth;
        uint8 maxSpeed;
        uint8 minSpeed;
        uint248 gilding;
        uint8 sails;
    }

    mapping(uint256 => ShipParams) private _params;
    mapping(uint256 => TraitSet) private _traits;

    IURIBuilder private _uriBuilder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    // solhint-disable-next-line no-empty-blocks
    constructor() initializer {}

    function initialize(Tier[5] calldata tiers) public initializer {
        __Property_init("Ship", "SHIP", tiers);

        _params[1] = ShipParams({
            base: 4,
            flags: 0,
            gilding: 0,
            maxHealth: 10,
            minHealth: 2,
            maxSpeed: 5,
            minSpeed: 2,
            sails: 0
        });
        _params[2] = ShipParams({
            base: 4,
            flags: 0,
            gilding: 4,
            maxHealth: 20,
            minHealth: 10,
            maxSpeed: 10,
            minSpeed: 5,
            sails: 5
        });
        _params[3] = ShipParams({
            base: 4,
            flags: 0,
            gilding: 8,
            maxHealth: 70,
            minHealth: 30,
            maxSpeed: 20,
            minSpeed: 10,
            sails: 7
        });
        _params[4] = ShipParams({
            base: 4,
            flags: 4,
            gilding: 8,
            maxHealth: 160,
            minHealth: 80,
            maxSpeed: 40,
            minSpeed: 20,
            sails: 8
        });
        _params[5] = ShipParams({
            base: 0x0546_0546_0546_0546_0546_0546_0546_0226,
            flags: 4,
            gilding: 0x044c_044c_044c_044c_044c_044c_044c_044c_044c_044c_044c_044c_00e6,
            maxHealth: 0,
            minHealth: 0,
            maxSpeed: 0,
            minSpeed: 0,
            sails: 11
        });
    }

    function setURIBuilder(address address_) external override onlyOwner {
        _uriBuilder = IURIBuilder(address_);
    }

    function traitsOf(uint256 tokenId) external view onlyOwner returns (TraitSet memory) {
        _ensureExists(tokenId);

        return _traits[tokenId];
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _ensureExists(tokenId);

        return _uriBuilder.build(tokenId, _traits[tokenId]);
    }

    function upgrade(uint256[] calldata tokenIds, uint256[] calldata tiers) public override {
        super.upgrade(tokenIds, tiers);

        uint256 seed = _nonce;

        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tier = tiers[i];
            uint256 tokenId = tokenIds[i];

            if (_traits[tokenId].tier >= tier) {
                revert IllegalUpgrade(tokenId, tier);
            }

            ShipParams memory params = _params[tier];
            TraitSet memory traits;

            traits.tier = uint8(tier);

            if (tier < 5) {
                traits.base = Base(Random.inRange(0, params.base, seed++));
                traits.gilding = uint8(Random.inRange(1, params.gilding, seed++));
                traits.health = uint16(Random.inRange(params.minHealth, params.maxHealth, seed++) * 50);
                traits.sails = uint8(Random.inRange(1, params.sails, seed++));
                traits.speed = uint16(Random.inRange(params.minSpeed, params.maxSpeed, seed++) * 5);
            }

            if (tier == 4) {
                traits.flags = uint8(Random.inRange(1, params.flags, seed++));
            } else if (tier == 5) {
                traits.base = Base(Random.weighted(params.base, 8, seed++));
                traits.health = 15000;
                traits.speed = 400;

                if (traits.base != Base.Turtle) {
                    traits.gilding = uint8(Random.weighted(params.gilding, 13, seed++) + 1);
                    traits.flags = uint8(Random.inRange(1, params.flags, seed++));
                    traits.sails = uint8(Random.inRange(1, params.sails, seed++));
                }
            }

            _traits[tokenId] = traits;
        }

        _updateNonce();
    }

    function _mintCore(uint256 tokenId) internal override {
        ShipParams memory params = _params[1];
        uint256 seed = _nonce;

        _traits[tokenId] = TraitSet({
            base: Base(Random.inRange(0, params.base, seed++)),
            flags: 0,
            gilding: 0,
            health: uint16(Random.inRange(params.minHealth, params.maxHealth, seed++) * 50),
            sails: 0,
            speed: uint16(Random.inRange(params.minSpeed, params.maxSpeed, seed++) * 5),
            tier: 1
        });
    }

    function _tierOf(uint256 tokenId) internal view override returns (uint256) {
        return _traits[tokenId].tier;
    }
}
