// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "./ERC721AQueryableUpgradeable.sol";
import "./Strings.sol";

import "./ITradeWinnerNFT.sol";
import "./DCSStructs.sol";
import "./Structs.sol";
import "./IDCSProductEntry.sol";
import "./IVaultViewEntry.sol";
import "./IProductViewEntry.sol";
import "./Errors.sol";

contract TradeWinnerNFT is ITradeWinnerNFT, ERC721AQueryableUpgradeable {
    using Strings for uint256;

    address public immutable cegaEntry;

    uint256 public immutable startTokenId;

    mapping(uint256 => MMNFTMetadata) public tokensMetadata;

    modifier onlyCegaEntry() {
        require(msg.sender == cegaEntry, Errors.NOT_CEGA_ENTRY);
        _;
    }

    constructor(address _cegaEntry, uint256 __startTokenId) {
        cegaEntry = _cegaEntry;
        startTokenId = __startTokenId;
    }

    function initialize() external initializerERC721A {
        __ERC721A_init("CegaMakers", "CGM");
    }

    function mint(
        address to,
        MMNFTMetadata calldata _tokenMetadata
    ) external onlyCegaEntry returns (uint256) {
        uint256 nextTokenId = _nextTokenId();
        tokensMetadata[nextTokenId] = _tokenMetadata;

        _mint(to, 1);

        return nextTokenId;
    }

    function mintBatch(
        address to,
        MMNFTMetadata[] calldata _tokensMetadata
    ) external onlyCegaEntry returns (uint256[] memory) {
        uint256 firstTokenId = _nextTokenId();
        uint256 tokenCount = _tokensMetadata.length;

        uint256[] memory tokenIds = new uint256[](tokenCount);

        for (uint256 index = 0; index < tokenCount; index++) {
            uint256 nextToken = firstTokenId + index;
            tokenIds[index] = nextToken;
            tokensMetadata[nextToken] = _tokensMetadata[index];
        }

        _mint(to, tokenCount);

        return tokenIds;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return startTokenId;
    }

    function tokenURI(
        uint256 tokenId
    )
        public
        view
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        MMNFTMetadata memory metadata = tokensMetadata[tokenId];
        uint32 productId = IVaultViewEntry(cegaEntry).getVaultProductId(
            metadata.vaultAddress
        );

        ProductMetadata memory productMetadata = IProductViewEntry(cegaEntry)
            .getProductMetadata(productId);
        DCSProduct memory product = IDCSProductEntry(cegaEntry).dcsGetProduct(
            productId
        );

        string memory json = string.concat(
            "{",
            '"name": "Token #',
            tokenId.toString(),
            '",',
            '"description": "Cega Trade Winner NFT",',
            '"attributes": [',
            '{ "trait_type": "ProductName", "value": "',
            productMetadata.name,
            '" },',
            buildBaseMetadata(metadata),
            '{ "trait_type": "BaseAsset", "value": "',
            Strings.toHexString(uint160(product.baseAssetAddress), 20),
            '" },',
            '{ "trait_type": "QuoteAsset", "value": "',
            Strings.toHexString(uint160(product.quoteAssetAddress), 20),
            '" }',
            "],",
            '"image": "',
            productMetadata.tradeWinnerNftImage,
            '" }'
        );

        return string(abi.encodePacked("data:application/json;utf8,", json));
    }

    function buildBaseMetadata(
        MMNFTMetadata memory metadata
    ) internal pure returns (string memory) {
        return
            string.concat(
                '{ "trait_type": "VaultAddress", "value": "',
                Strings.toHexString(uint160(metadata.vaultAddress), 20),
                '" },',
                '{ "trait_type": "TradeStartDate", "value": "',
                uint256(metadata.tradeStartDate).toString(),
                '" },',
                '{ "trait_type": "TradeEndDate", "value": "',
                uint256(metadata.tradeEndDate).toString(),
                '" },',
                '{ "trait_type": "AprBps", "value": "',
                uint256(metadata.aprBps).toString(),
                '" },',
                '{ "trait_type": "Notional", "value": "',
                uint256(metadata.notional).toString(),
                '" },',
                '{ "trait_type": "InitialSpotPrice", "value": "',
                uint256(metadata.initialSpotPrice).toString(),
                '" },',
                '{ "trait_type": "StrikePrice", "value": "',
                uint256(metadata.strikePrice).toString(),
                '" },'
            );
    }
}
