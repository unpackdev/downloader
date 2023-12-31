// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// NFTC Prerelease Contracts
import "./SafetyLatch.sol";
import "./ChainNativeMetadataConsumer.sol";
import "./ERC721SolBase_NFTC.sol";

// OZ Libraries
import "./Strings.sol";

// Error Codes
error ExceedsBatchSize();
error ExceedsPurchaseLimit();
error ExceedsSupplyCap();
error InvalidPayment();

/**
 * @title PixelPioneerBase
 * @author @NiftyMike | @NFTCulture
 * @dev ERC721 SolBase implementation with @NFTCulture standardized components.
 *
 * Tokens are minted in advance by the project team.
 */
abstract contract PixelPioneerBase is ERC721SolBase_NFTC, ChainNativeMetadataConsumer, SafetyLatch {
    using Strings for uint256;

    // Pixel Pioneer collection is limited to 5 tokens.
    uint16 private constant MAX_RESERVE_BATCH_SIZE = 5;
    uint16 private constant SUPPLY_CAP = 5;

    constructor(string memory __baseURI) ERC721SolBase_NFTC(SUPPLY_CAP, __baseURI) {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'No token');

        uint256 tokenType = _getProducer().getTokenTypeForToken(tokenId);
        return _getProducer().getJsonAsEncodedString(tokenId, tokenType);
    }

    /**
     * @notice Owner: advance mint tokens.
     *
     * @param destination address to send tokens to.
     * @param count the number of tokens to mint.
     */
    function advanceMintTokens(address destination, uint256 count) external isOwner {
        _advanceMintTokens(destination, count);
    }

    function _advanceMintTokens(address destination, uint256 count) internal {
        if (0 >= count || count > MAX_RESERVE_BATCH_SIZE) revert ExceedsBatchSize();

        uint256 currentTM = _totalMinted();
        if (currentTM + count > SUPPLY_CAP) revert ExceedsSupplyCap();

        uint256 tokenId;
        for (tokenId = currentTM; tokenId < currentTM + count; tokenId++) {
            _internalMintTokens(destination, tokenId);
        }
    }

    function _internalMintTokens(address minter, uint256 tokenId) internal {
        _safeMint(minter, tokenId);
    }

    function _executeOnDestruct() internal override {
        uint256 idx;

        for (idx; idx < _totalMinted(); idx++) {
            if (_exists(idx)) {
                _burn(idx);
            }
        }
    }

    /**
     * @notice Total number of tokens that currently exist.
     */
    function totalTokensExist() external view override returns (uint256) {
        return _totalSupply();
    }
}
