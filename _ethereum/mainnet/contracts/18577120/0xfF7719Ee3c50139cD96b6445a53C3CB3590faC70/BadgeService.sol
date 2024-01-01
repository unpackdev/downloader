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

// OpenZeppelin
import "./IERC20Metadata.sol";

// Local imports - Storages
import "./LibAppStorage.sol";
import "./LibBaseAsset.sol";

// Local imports - Interfaces
import "./IEquityBadge.sol";

library BadgeService {
    /// @dev Mint badge.
    /// @param _badgeId ID of badge
    /// @param _investment Amount of badges to mint is proportional to investment amount
    function mintBadge(string memory _raiseId, uint256 _badgeId, uint256 _investment) internal {
        // tx.members
        address sender_ = msg.sender;

        // get badge
        IEquityBadge badge = LibAppStorage.getBadge();

        // get base asset
        IERC20Metadata baseAsset_ = IERC20Metadata(LibBaseAsset.getAddress(_raiseId));

        // erc1155 bytes conversion
        bytes memory data_ = abi.encode(_badgeId);

        // mint equity badge
        badge.mint(sender_, _badgeId, _investment / 10 ** baseAsset_.decimals(), data_);
    }

    /// @dev Convert raise id to badge id.
    /// @param _raiseId ID of the raise
    function convertRaiseToBadge(string memory _raiseId) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(_raiseId)));
    }

    /// @dev Set URI for given badge id on the Equity Badge ERC-1155 token.
    /// @param _badgeId ID of badge
    /// @param _uri URI
    function setEquityBadgeURI(uint256 _badgeId, string memory _uri) internal {
        LibAppStorage.getBadge().setURI(_badgeId, _uri);
    }
}
