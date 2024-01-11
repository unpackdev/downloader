// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//                        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//                        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//                        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//                        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@    //
//    @@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////

import "./ERC721OwnerEnumerable.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

error InvalidMintCaller();
error OverTokenLimit();
error TokenAlreadyClaimed();
error TokenHasNoClaim();

interface IMintable {
    function mint(address claimer) external;
}

/**
 * MinimenClubLegendary is the second contract in a pair of contracts that allow for a legendary claimable mint.
 * This contract only has a few tokens excusively minted, with onchain-randomness, by the original MinimenClub contract.
 *
 * Mints occur by calling the {claim} method in the original contract on a rare tokenId that has not been claimed yet.
 * The determination of which tokens are rare and how claims are limited are all determined by the original contract.
 */
contract MinimenClubLegendary is ERC721OwnerEnumerable, IMintable {
    using Strings for uint256;

    uint256 public constant MAX_TOKENS = 69;

    // Only Address that can mint tokens from this contract
    address public mintSourceAddress;

    // Used to maintain constant time on-chain random ID generation
    uint256[MAX_TOKENS] private indices;

    // Token metadata for all tokens
    string public tokenDirectory;

    constructor(
        string memory name,
        string memory symbol,
        string memory _tokenDirectory,
        address _sourceAddress,
        uint256 royalty,
        address royaltyWallet
    ) ERC721(name, symbol) {
        tokenDirectory = _tokenDirectory;
        mintSourceAddress = _sourceAddress;
        _setRoyaltyBPS(royalty);
        _setRoyaltyWallet(royaltyWallet);
        _setTokenRange(1, MAX_TOKENS);
    }

    /**
     * @dev allows owner to update royalties following EIP-2981 at anytime
     */
    function updateRoyalty(uint256 royaltyBPS, address royaltyWallet)
        external
        onlyOwner
    {
        _setRoyaltyBPS(royaltyBPS);
        _setRoyaltyWallet(royaltyWallet);
    }

    /**
     * @dev Display the metadata for a tokenId.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert QueryForNonexistentToken();
        return
            string(abi.encodePacked(tokenDirectory, "/", tokenId.toString()));
    }

    /**
     * @dev Updates the token metadata of the collection.
     */
    function setTokenDirectory(string memory _tokenDirectory)
        external
        onlyOwner
    {
        tokenDirectory = _tokenDirectory;
    }

    /**
     * @dev Allows ONLY mintSourceAddress to mint a random token to the given address.
     */
    function mint(address claimer) external {
        if (_msgSender() != mintSourceAddress) revert InvalidMintCaller();
        if (totalSupply() >= _tokenLimit()) revert OverTokenLimit();
        _mintRandomIndex(claimer);
    }

    /// @notice Generates a pseudo random index of our tokens that has not been used so far
    function _mintRandomIndex(address receiver) internal {
        uint256 supplyLeft = _tokenLimit() - totalSupply();
        // generate a random index
        uint256 index = _random(supplyLeft);
        uint256 tokenAtPlace = indices[index];

        uint256 tokenId;
        // if we havent stored a replacement token...
        if (tokenAtPlace == 0) {
            //... we just return the current index
            tokenId = index;
        } else {
            // else we take the replace we stored with logic below
            tokenId = tokenAtPlace;
        }

        // get the highest token id we havent handed out
        uint256 lastTokenAvailable = indices[supplyLeft - 1];
        // we need to store a replacement token for the next time we roll the same index
        // if the last token is still unused...
        if (lastTokenAvailable == 0) {
            // ... we store the last token as index
            indices[index] = supplyLeft - 1;
        } else {
            // ... we store the token that was stored for the last token
            indices[index] = lastTokenAvailable;
        }

        _mint(receiver, tokenId + _minTokenId);
    }

    /// @notice Generates a pseudo random number based on arguments with decent entropy
    /// @param max The maximum value we want to receive
    /// @return A random number less than the max
    function _random(uint256 max) internal view returns (uint256) {
        uint256 rand = uint256(
            keccak256(
                abi.encode(
                    _msgSender(),
                    block.difficulty,
                    block.timestamp,
                    blockhash(block.number - 1)
                )
            )
        );
        return rand % max;
    }
}
