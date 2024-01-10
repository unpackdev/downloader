// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./errors.sol";
import "./IURIBuilder.sol";
import "./Property.sol";
import "./TraitSet.sol";
import "./Random.sol";

contract FishingRod is Property {
    mapping(uint256 => TraitSet) private _traits;

    IURIBuilder private _uriBuilder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    // solhint-disable-next-line no-empty-blocks
    constructor() initializer {}

    function initialize(Tier[5] calldata tiers) public initializer {
        __Property_init("Fishing Rod", "ROD", tiers);
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

            TraitSet memory traits;

            traits.tier = uint8(tier);

            if (tier < 4) {
                traits.handle = uint8(Random.inRange(0, 3, seed++));
                traits.material = uint8(Random.inRange(0, 3, seed++));

                if (tier == 2) {
                    traits.durability = uint8(Random.inRange(5, 10, seed++));
                    traits.luck = uint8(Random.inRange(5, 10, seed++) * 5);
                } else {
                    traits.durability = uint8(Random.inRange(10, 35, seed++));
                    traits.luck = uint8(Random.inRange(10, 20, seed++) * 5);
                }
            } else if (tier == 4) {
                traits.durability = uint8(Random.inRange(35, 70, seed++));
                traits.handle = uint8(Random.inRange(0, 3, seed++));
                traits.kind = uint8(Random.inRange(0, 1, seed++));
                traits.luck = uint8(Random.inRange(20, 40, seed++) * 5);
                traits.material = uint8(Random.inRange(0, traits.kind == 0 ? 4 : 3, seed++));
            } else {
                traits.durability = 100;
                traits.kind = uint8(Random.inRange(0, 2, seed++));
                traits.luck = 400;
                traits.material = uint8(Random.inRange(0, 3, seed++));

                if (traits.kind == 0) {
                    traits.handle = uint8(Random.inRange(0, 1, seed++));
                } else if (traits.kind == 1) {
                    traits.handle = uint8(Random.inRange(0, 4, seed++));
                } else {
                    traits.handle = uint8(Random.inRange(0, 3, seed++));
                }
            }

            _traits[tokenId] = traits;
        }

        _updateNonce();
    }

    function _mintCore(uint256 tokenId) internal override {
        uint256 seed = _nonce;

        _traits[tokenId] = TraitSet({
            durability: uint8(Random.inRange(1, 5, seed++)),
            handle: uint8(Random.inRange(0, 3, seed++)),
            kind: 0,
            luck: uint16(Random.inRange(2, 5, seed++) * 5),
            material: uint8(Random.inRange(0, 3, seed++)),
            tier: 1
        });
    }

    function _tierOf(uint256 tokenId) internal view override returns (uint256) {
        return _traits[tokenId].tier;
    }
}
