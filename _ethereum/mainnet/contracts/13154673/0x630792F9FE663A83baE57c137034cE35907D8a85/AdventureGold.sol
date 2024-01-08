// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Context.sol";
import "./IERC721Enumerable.sol";

/// @title Adventure Gold for Loot holders!
/// @author Will Papper <https://twitter.com/WillPapper>
/// @notice This contract mints Adventure Gold for Loot holders. It allows:
/// * Loot holders to claim Adventure Gold
/// @custom:unaudited This contract has not been audited. Use at your own risk.
contract AdventureGold is Context, ERC20 {
    // Loot contract is available at https://etherscan.io/address/0xD987C5800EF371844CEaC3D0Ee29E4ff29162d7C
    address public lootContractAddress =
        0xD987C5800EF371844CEaC3D0Ee29E4ff29162d7C;
    IERC721Enumerable public lootContract;

    // Give out 10,000 Adventure Gold for every Loot Bag that a user holds
    uint256 public adventureGoldPerTokenId = 10000 * (10**decimals());

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

    // Track claimed tokens
    // IMPORTANT: The format of the mapping is:
    // claimedByTokenId[tokenId][claimed]
    mapping(uint256 => bool) public claimedByTokenId;

    constructor() ERC20("Space Gold", "SGLD") {
        lootContract = IERC721Enumerable(lootContractAddress);
    }

    /// @notice Claim Adventure Gold for a given Loot ID
    /// @param tokenId The tokenId of the Loot NFT
    function claimById(uint256 tokenId) external {
        // Follow the Checks-Effects-Interactions pattern to prevent reentrancy
        // attacks

        // Checks

        // Check that the msgSender owns the token that is being claimed
        require(
            _msgSender() == lootContract.ownerOf(tokenId),
            "MUST_OWN_TOKEN_ID"
        );

        // Further Checks, Effects, and Interactions are contained within the
        // _claim() function
        _claim(tokenId, _msgSender());
    }

    /// @notice Claim Adventure Gold for all tokens owned by the sender
    /// @notice This function will run out of gas if you have too much loot! If
    /// this is a concern, you should use claimRangeForOwner and claim Adventure
    /// Gold in batches.
    function claimAllForOwner() external {
        uint256 tokenBalanceOwner = lootContract.balanceOf(_msgSender());

        // Checks
        require(tokenBalanceOwner > 0, "NO_TOKENS_OWNED");

        // i < tokenBalanceOwner because tokenBalanceOwner is 1-indexed
        for (uint256 i = 0; i < tokenBalanceOwner; i++) {
            // Further Checks, Effects, and Interactions are contained within
            // the _claim() function
            _claim(
                lootContract.tokenOfOwnerByIndex(_msgSender(), i),
                _msgSender()
            );
        }
    }

    /// @notice Claim Adventure Gold for all tokens owned by the sender within a
    /// given range
    /// @notice This function is useful if you own too much Loot to claim all at
    /// once or if you want to leave some Loot unclaimed.
    function claimRangeForOwner(uint256 ownerIndexStart, uint256 ownerIndexEnd)
        external
    {
        uint256 tokenBalanceOwner = lootContract.balanceOf(_msgSender());

        // Checks
        require(tokenBalanceOwner > 0, "NO_TOKENS_OWNED");

        // We use < for ownerIndexEnd and tokenBalanceOwner because
        // tokenOfOwnerByIndex is 0-indexed while the token balance is 1-indexed
        require(
            ownerIndexStart >= 0 && ownerIndexEnd < tokenBalanceOwner,
            "INDEX_OUT_OF_RANGE"
        );

        // i <= ownerIndexEnd because ownerIndexEnd is 0-indexed
        for (uint256 i = ownerIndexStart; i <= ownerIndexEnd; i++) {
            // Further Checks, Effects, and Interactions are contained within
            // the _claim() function
            _claim(
                lootContract.tokenOfOwnerByIndex(_msgSender(), i),
                _msgSender()
            );
        }
    }

    /// @dev Internal function to mint Loot upon claiming
    function _claim(uint256 tokenId, address tokenOwner) internal {
        // Checks
        // Check that the token ID is in range
        // We use >= and <= to here because all of the token IDs are 0-indexed
        require(
            tokenId >= tokenIdStart && tokenId <= tokenIdEnd,
            "TOKEN_ID_OUT_OF_RANGE"
        );

        // Check that Adventure Gold have not already been claimed
        // for a given tokenId
        require(!claimedByTokenId[tokenId], "GOLD_CLAIMED_FOR_TOKEN_ID");

        // Effects

        // Mark that Adventure Gold has been claimed for the
        // given tokenId
        claimedByTokenId[tokenId] = true;

        // Interactions

        // Send Adventure Gold to the owner of the token ID
        _mint(tokenOwner, adventureGoldPerTokenId);
    }
}
