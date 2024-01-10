// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// NFTC Open Source Contracts See: https://github.com/NFTCulture/nftc-open-contracts
import "./GuardedAgainstContracts.sol";
import "./LockedPaymentSplitter.sol";

// NFTC Prerelease Contracts
import "./OnePhaseMint.sol";

// ERC721A from Chiru Labs
import "./ERC721A.sol";

// OZ Libraries
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

/**
 * @title Justice for Ukraine, A Charitable Project
 * @author @J, NFT Culture
 * @dev Standard ERC721a Implementation
 *
 * Visit the NFTC Labs open source repo on github:
 * https://github.com/NFTCulture/nftc-open-contracts
 */
abstract contract JusticeForUkraineBase is
    ERC721A,
    Ownable,
    GuardedAgainstContracts,
    ReentrancyGuard,
    LockedPaymentSplitter,
    OnePhaseMint
{
    using Strings for uint256;

    uint256 private constant MAX_NFTS_FOR_SALE = 20000;
    uint256 private constant MAX_MINT_BATCH_SIZE = 100;

    string public baseURI;

    constructor(
        string memory __name,
        string memory __symbol,
        string memory __baseURI,
        address[] memory __addresses,
        uint256[] memory __splits
    )
        ERC721A(__name, __symbol)
        SlimPaymentSplitter(__addresses, __splits)
        OnePhaseMint(0.001 ether)
    {
        baseURI = __baseURI;
    }

    function maxSupply() external pure returns (uint256) {
        return MAX_NFTS_FOR_SALE;
    }

    function publicMintBatchSize() external pure returns (uint256) {
        return MAX_MINT_BATCH_SIZE;
    }

    function isOpenEdition() external pure returns (bool) {
        // Front end minting websites should treat this mint as an open edition, even though there is a hard cap.
        return true;
    }

    function setBaseURI(string memory __baseUri) external onlyOwner {
        baseURI = __baseUri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'No token');

        string memory base = _baseURI();
        require(bytes(base).length > 0, 'Base unset');

        return string(abi.encodePacked(base, _tokenFilename(tokenId)));
    }

    /**
     * @notice Owner: reserve tokens for team.
     *
     * @param friends addresses to send tokens  to.
     * @param count the number of tokens to mint.
     */
    function reserveTokens(address[] memory friends, uint256 count) external onlyOwner {
        require(0 < count && count <= MAX_MINT_BATCH_SIZE, 'Invalid count');

        uint256 idx;
        for (idx = 0; idx < friends.length; idx++) {
            _internalMintTokens(friends[idx], count);
        }
    }

    /**
     * @notice Mint tokens - purchase bound by terms & conditions of project.
     *
     * @param count the number of tokens to mint.
     */
    function mintTokens(uint256 count) external payable nonReentrant onlyUsers isPublicMinting {
        require(0 < count && count <= MAX_MINT_BATCH_SIZE, 'Invalid count');
        require(publicMintPricePerNft * count == msg.value, 'Invalid price');

        _internalMintTokens(_msgSender(), count);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _tokenFilename(uint256 tokenId) internal view virtual returns (string memory) {
        return tokenId.toString();
    }

    function _internalMintTokens(address minter, uint256 count) internal {
        require(totalSupply() + count <= MAX_NFTS_FOR_SALE, 'Limit exceeded');

        _safeMint(minter, count);
    }
}
