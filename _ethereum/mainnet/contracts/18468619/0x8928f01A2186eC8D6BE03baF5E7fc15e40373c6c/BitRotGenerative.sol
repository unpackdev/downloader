//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./IBitRotRenderer.sol";
import "./ERC721GenerativeOnchain.sol";

/**
 * @title BitRotGenerative (ERC721)
 */
contract BitRotGenerative is ERC721GenerativeOnchain {
    /**
     * @notice Throw when mint details are queried for a token that hasn't been minted
     */
    error InvalidTokenId();

    /**
     * @notice Data partially used to seed outputs
     */
    struct SeedDetails {
        bytes32 previousBlockHash;
        uint256 blockTimestamp;
    }

    /**
     * @notice BitRotRenderer address
     */
    IBitRotRenderer public renderer;

    /**
     * @notice Store the block hash for every minted token batch
     */
    mapping(uint256 => SeedDetails) private _startTokenIdToSeedDetails;

    /**
     * @notice Store the first token id of each minted batch
     */
    uint256[] private _startTokenIds;

    /**
     * @notice Store the image previews base uri
     */
    string private _previewsBaseUri;

    /**
     * @notice Emit when BitRotRenderer is updated
     */
    event RendererUpdated(address indexed newRenderer);

    /* solhint-disable not-rely-on-block-hash */
    /**
     * @notice See {IERC721GeneralMint-mintOneToOneRecipient}
     * @dev Update BitRot mint details
     */
    function mintOneToOneRecipient(address recipient) external override onlyMinter nonReentrant returns (uint256) {
        if (_mintFrozen == 1) {
            _revert(MintFrozen.selector);
        }

        uint256 tempSupply = _nextTokenId();
        _requireLimitSupply(tempSupply);

        _mint(recipient, 1);

        _startTokenIds.push(tempSupply);
        _startTokenIdToSeedDetails[tempSupply] = SeedDetails(blockhash(block.number - 1), block.timestamp);

        return tempSupply;
    }

    /* solhint-enable not-rely-on-block-hash */

    /**
     * @notice See {IERC721GeneralMint-mintAmountToOneRecipient}
     * @dev Update BitRot mint details
     */
    function mintAmountToOneRecipient(address recipient, uint256 amount) external override onlyMinter nonReentrant {
        if (_mintFrozen == 1) {
            _revert(MintFrozen.selector);
        }
        uint256 tempSupply = _nextTokenId() - 1; // cache

        _mint(recipient, amount);

        _requireLimitSupply(tempSupply + amount);

        _startTokenIds.push(tempSupply + 1);
        _startTokenIdToSeedDetails[tempSupply + 1] = SeedDetails(blockhash(block.number - 1), block.timestamp);
    }

    /**
     * @notice Update BitRot renderer
     */
    function updateRenderer(address newRenderer) external onlyOwner {
        renderer = IBitRotRenderer(newRenderer);

        emit RendererUpdated(newRenderer);
    }

    /**
     * @notice Update previews base uri
     */
    function updatePreviewsBaseUri(string memory newPreviewsBaseUri) external onlyOwner {
        _previewsBaseUri = newPreviewsBaseUri;
    }

    /**
     * @notice Override tokenURI to use BitRotRenderer
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        SeedDetails memory seedDetails = getSeedDetails(tokenId);

        return
            renderer.tokenURI(
                seedDetails.previousBlockHash,
                tokenId,
                seedDetails.blockTimestamp,
                address(this),
                _previewsBaseUri
            );
    }

    function getSeedDetails(uint256 tokenId) public view returns (SeedDetails memory) {
        uint256 nextTokenId = _nextTokenId();
        uint256[] memory tempStartTokenIds = _startTokenIds;
        uint256 numBatches = tempStartTokenIds.length;

        if (numBatches == 0) {
            _revert(InvalidTokenId.selector);
        }

        uint256 previousStartTokenId = tempStartTokenIds[0];
        if (numBatches == 1) {
            if (tokenId >= previousStartTokenId && tokenId < nextTokenId) {
                return _startTokenIdToSeedDetails[previousStartTokenId];
            } else {
                _revert(InvalidTokenId.selector);
            }
        }

        for (uint256 i = 1; i < numBatches; i++) {
            if (tokenId >= previousStartTokenId && tokenId < tempStartTokenIds[i]) {
                return _startTokenIdToSeedDetails[previousStartTokenId];
            }

            previousStartTokenId = tempStartTokenIds[i];
        }

        if (tokenId >= previousStartTokenId && tokenId < nextTokenId) {
            return _startTokenIdToSeedDetails[previousStartTokenId];
        } else {
            _revert(InvalidTokenId.selector);
        }
    }
}
