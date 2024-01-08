//SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

// ============ Imports ============

import "./IERC721Enumerable.sol";
import "./ERC1155.sol";
import "./Ownable.sol";
import "./LootTokensMetadata.sol";

interface ILootAirdrop {
    function claimForLoot(uint256) external payable;
    function safeTransferFrom(address, address, uint256) external payable;
}

interface IAdventurer {
    function mint() external;
    function mintToAccount(address _account) external;
    function totalSupply() external returns (uint256);
    function equipBulk(uint256 tokenId, address[] memory itemAddresses, uint256[] memory itemIds) external;
    function equip(uint256 tokenId, address itemAddress, uint256 itemId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

library Errors {
    string constant DoesNotOwnLootbag = "you do not own the lootbag for this airdrop";
    string constant IsNotLoot = "msg.sender is not the loot contract";
}

/// @title Loot Tokens
/// @author Gary Thung, forked from Georgios Konstantopoulos
/// @notice Allows "opening" your ERC721 Loot bags and extracting the items inside it
/// The created tokens are ERC1155 compatible, and their on-chain SVG is their name
contract Lootmart is Ownable, ERC1155, LootTokensMetadata {
    // The OG Loot bags contract
    IERC721Enumerable immutable loot;

    IAdventurer immutable adventurer;

    // Track claimed Lootmart components
    mapping(uint256 => bool) public claimedByTokenId;

    // tokenIdStart of 1 is based on the following lines in the Loot contract:
    /**
    function claim(uint256 tokenId) public nonReentrant {
        require(tokenId > 0 && tokenId < 7778, "Token ID invalid");
        _safeMint(_msgSender(), tokenId);
    }
    */
    uint256 public tokenIdStart = 1;

    // tokenIdEnd of 8000 is based on the following lines in the Loot contract:
    /**
        function ownerClaim(uint256 tokenId) public nonReentrant onlyOwner {
        require(tokenId > 7777 && tokenId < 8001, "Token ID invalid");
        _safeMint(owner(), tokenId);
    }
    */
    uint256 public tokenIdEnd = 8000;

    constructor(address _loot, address _adventurer, string memory _baseURI) ERC1155("") LootTokensMetadata(_baseURI) {
        loot = IERC721Enumerable(_loot);
        adventurer = IAdventurer(_adventurer);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155) returns (bool) {
        return
            interfaceId == 0xeea73b1a ||
            super.supportsInterface(interfaceId);
    }

    /// @notice Claims the components for the given tokenId
    function claimForLoot(uint256 tokenId) external {
        _claim(tokenId, _msgSender());
    }

    /// @notice Claims all components for caller
    function claimAllForOwner() external {
        uint256 tokenBalanceOwner = loot.balanceOf(_msgSender());

        // Check that caller owns any Loots
        require(tokenBalanceOwner > 0, "NO_TOKENS_OWNED");

        // i < tokenBalanceOwner because tokenBalanceOwner is 1-indexed
        for (uint256 i = 0; i < tokenBalanceOwner; i++) {
            _claim(loot.tokenOfOwnerByIndex(_msgSender(), i), _msgSender());
        }
    }

    /// @notice Claims all components for given IDs
    function claimForTokenIds(uint256[] memory tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _claim(tokenIds[i], _msgSender());
        }
    }

    /// @notice Claims the components for the given tokenId and mints an adventurer
    function claimForLootWithAdventurer(uint256 tokenId) external {
        _claim(tokenId, _msgSender());
        adventurer.mintToAccount(_msgSender());
    }

    /// @notice Claims all components for caller and mints an adventurer
    function claimAllForOwnerWithAdventurer() external {
        uint256 tokenBalanceOwner = loot.balanceOf(_msgSender());

        // Check that caller owns any Loots
        require(tokenBalanceOwner > 0, "NO_TOKENS_OWNED");

        // i < tokenBalanceOwner because tokenBalanceOwner is 1-indexed
        for (uint256 i = 0; i < tokenBalanceOwner; i++) {
            _claim(loot.tokenOfOwnerByIndex(_msgSender(), i), _msgSender());
        }

        adventurer.mintToAccount(_msgSender());
    }

    /// @notice Claims all components for given IDs and mints an adventurer
    function claimForTokenIdsWithAdventurer(uint256[] memory tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _claim(tokenIds[i], _msgSender());
        }

        adventurer.mintToAccount(_msgSender());
    }

    /// @notice Claim all components for a loot bag. Performs safety checks
    function _claim(uint256 tokenId, address tokenOwner) internal {
        // Check that caller owns the loot bag
        require(tokenOwner == loot.ownerOf(tokenId), "MUST_OWN_TOKEN_ID");

        // Check that the token ID is in range
        // We use >= and <= to here because all of the token IDs are 0-indexed
        require(tokenId >= tokenIdStart && tokenId <= tokenIdEnd, "TOKEN_ID_OUT_OF_RANGE");

        // Check that components not claimed already
        require(!claimedByTokenId[tokenId], "ALREADY_CLAIMED");

        // Mark as claimed
        claimedByTokenId[tokenId] = true;

        // NB: We patched ERC1155 to expose `_balances` so
        // that we can manually mint to a user, and manually emit a `TransferBatch`
        // event. If that's unsafe, we can fallback to using _mint
        uint256[] memory ids = new uint256[](8);
        uint256[] memory amounts = new uint256[](8);
        ids[0] = itemId(tokenId, weaponComponents, WEAPON);
        ids[1] = itemId(tokenId, chestComponents, CHEST);
        ids[2] = itemId(tokenId, headComponents, HEAD);
        ids[3] = itemId(tokenId, waistComponents, WAIST);
        ids[4] = itemId(tokenId, footComponents, FOOT);
        ids[5] = itemId(tokenId, handComponents, HAND);
        ids[6] = itemId(tokenId, neckComponents, NECK);
        ids[7] = itemId(tokenId, ringComponents, RING);

        for (uint256 i = 0; i < ids.length; i++) {
            amounts[i] = 1;

            // +21k per call / unavoidable - requires patching OZ
            _balances[ids[i]][tokenOwner] += 1;
        }

        emit TransferBatch(_msgSender(), address(0), tokenOwner, ids, amounts);
    }

    function itemId(
        uint256 tokenId,
        function(uint256) view returns (uint256[5] memory) componentsFn,
        uint256 itemType
    ) private view returns (uint256) {
        uint256[5] memory components = componentsFn(tokenId);
        return TokenId.toId(components, itemType);
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return tokenURI(tokenId);
    }

    /**
    * @dev Convert uint to bytes.
    */
    function toBytes(uint256 x) internal pure returns (bytes memory b) {
        b = new bytes(32);
        assembly { mstore(add(b, 32), x) }
    }
}
