// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./LoftzStylesV1.sol";
import "./Ownable.sol";
import "./BitMaps.sol";
import "./IERC721.sol";

contract RobotMinterV1 is Ownable {
    using BitMaps for BitMaps.BitMap;

    struct PartialBitMapEntry {
        uint256 index;
        uint256 value;
    }

    error InvalidOgTokenOrOwner();

    event Claim(uint256 ogTokenId);

    IERC721 public immutable ogToonz;
    LoftzStylesV1 public immutable lotfzStyles;

    // A "true" value in this bit map means the corresponding OG Toon can claim.
    BitMaps.BitMap private canClaim;

    constructor(IERC721 _ogToonz, LoftzStylesV1 _loftzStyles) {
        ogToonz = _ogToonz;
        lotfzStyles = _loftzStyles;
    }

    // =============================================================
    // Main Token Logic
    // =============================================================

    function claim(uint256[] memory _robotIds) external {
        uint256 i = 0;
        for (;;) {
            uint256 robotId = _robotIds[i];

            if (!canClaim.get(robotId) || ogToonz.ownerOf(robotId) != msg.sender) {
                revert InvalidOgTokenOrOwner();
            }

            canClaim.unset(robotId);
            emit Claim(robotId);

            if (_robotIds.length == ++i) break;
        }

        lotfzStyles.mint(msg.sender, 1, _robotIds.length, "");
    }

    // =============================================================
    // Maintenance Actions
    // =============================================================

    function updateClaimBitMap(PartialBitMapEntry[] memory _bitMapEntries) public onlyOwner {
        uint256 i = 0;
        for (;;) {
            canClaim._data[_bitMapEntries[i].index] = _bitMapEntries[i].value;

            if (_bitMapEntries.length == ++i) break;
        }
    }

    // =============================================================
    // Off-chain Indexing Tools
    // =============================================================

    function filterValidOgTokens(address _owner, uint256[] memory _tokenIds) public view returns (uint256[] memory tokenIds) {
        tokenIds = new uint256[](_tokenIds.length);
        uint256 currentValidTokenIndex = 0;

        uint256 i = 0;
        for (;;) {
            uint256 tokenId = _tokenIds[i];

            if (canClaim.get(tokenId) && ogToonz.ownerOf(tokenId) == _owner) {
                tokenIds[currentValidTokenIndex++] = tokenId;
            }

            if (_tokenIds.length == ++i) break;
        }

        assembly {
            // Resize array to fit actual result...
            mstore(tokenIds, currentValidTokenIndex)
        }
    }
}
