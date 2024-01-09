// SPDX-License-Identifier: MIT

/// @title RaidParty Helper Contract for Enhanceability

/**
 *   ___      _    _ ___          _
 *  | _ \__ _(_)__| | _ \__ _ _ _| |_ _  _
 *  |   / _` | / _` |  _/ _` | '_|  _| || |
 *  |_|_\__,_|_\__,_|_| \__,_|_|  \__|\_, |
 *                                    |__/
 */

pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./AddressUpgradeable.sol";
import "./ISeeder.sol";
import "./IEnhancer.sol";
import "./Seedable.sol";
import "./IEnhanceable.sol";
import "./IRaidERC721.sol";

abstract contract Enhanceable is IEnhanceable, Initializable, Seedable {
    using AddressUpgradeable for address;

    mapping(uint256 => EnhancementRequest) private _enhancements;
    uint256 private _enhancementCounter;
    ISeeder internal _seeder;
    IRaidERC721 internal _token;

    function __Enhanceable_init(address seeder, address token)
        public
        initializer
    {
        _seeder = ISeeder(seeder);
        _token = IRaidERC721(token);
        _enhancementCounter = 1;
    }

    function enhancementCost(uint256 tokenId)
        external
        view
        virtual
        returns (uint256, bool);

    function enhance(uint256 tokenId, uint256) public virtual {
        require(
            _enhancements[tokenId].requester == address(0),
            "Enhanceable::enhance: token bound to pending request"
        );
        _enhancements[tokenId] = EnhancementRequest(
            _enhancementCounter,
            msg.sender
        );
        _seeder.requestSeed(_enhancementCounter);
        unchecked {
            _enhancementCounter += 1;
        }
        emit EnhancementRequested(tokenId, block.timestamp);
    }

    // Caller must emit and determine resultant state before calling super
    function reveal(uint256[] calldata ids) public virtual {
        unchecked {
            for (uint256 i = 0; i < ids.length; i++) {
                require(
                    _checkOnEnhancement(ids[i]),
                    "Enhanceable::reveal: reveal for unsupported contract"
                );
                delete _enhancements[ids[i]];
            }
        }
    }

    function _checkOnEnhancement(uint256 tokenId) internal returns (bool) {
        address owner = _token.ownerOf(tokenId);
        if (owner.isContract()) {
            try IEnhancer(owner).onEnhancement(tokenId) returns (
                bytes4 retval
            ) {
                return retval == IEnhancer.onEnhancement.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("Enhanceable: transfer to non Enhancer implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _roll(uint256 seed, uint256 probability)
        internal
        pure
        returns (bool)
    {
        if (seed % 10000 < probability) {
            return true;
        } else {
            return false;
        }
    }

    function _getSeed(uint256 tokenId) internal view returns (uint256) {
        return _seeder.getSeedSafe(address(this), _enhancements[tokenId].id);
    }

    function _setSeeder(address seeder) internal {
        _seeder = ISeeder(seeder);
        emit SeederUpdated(msg.sender, seeder);
    }
}
