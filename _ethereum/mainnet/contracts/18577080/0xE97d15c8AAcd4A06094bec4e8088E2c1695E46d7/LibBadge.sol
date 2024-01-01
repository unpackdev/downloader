// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/**************************************

    security-contact:
    - security@angelblock.io

    maintainers:
    - marcin@angelblock.io
    - piotr@angelblock.io
    - mikolaj@angelblock.io
    - sebastian@angelblock.io

    contributors:
    - domenico@angelblock.io

**************************************/

// ToDo : NatSpec + Comments

library LibBadge {
    bytes32 internal constant BADGE_STORAGE_POSITION = keccak256("angelblock.fundraising.badge");

    struct BaseAssetStorage {
        mapping(string => string) badgeUris;
    }

    function badgeStorage() internal pure returns (BaseAssetStorage storage bs) {
        bytes32 position = BADGE_STORAGE_POSITION;

        assembly {
            bs.slot := position
        }

        return bs;
    }

    function setBadgeUri(string memory _raiseId, string memory _badgeUri) internal {
        badgeStorage().badgeUris[_raiseId] = _badgeUri;
    }
}
