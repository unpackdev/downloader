// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// Local References
import "./PixelPioneerMetadataBase.sol";

/**
 * @title PixelPioneerMetadata.
 *                            .+.
 *             -:       .:    :+.
 *    --      :=.       :+    -=                                         .     ..                     .:-:
 *    .+.    --         :+    =-   .:.                                 :++-.  .++=: ..              :==:-++==:
 *     =-  .=:          :=    +.  -=::.:.               -.        .==..+=-+=  =+:+-.=====:         -+:  =+:.-+.
 *     =-:=-       :.   ==----+  :+   =+:.-+-   ..                 ++..++++:  =++=-+:   -+:      .++=--=++=-++.
 *     -=--==-.    :.   +-::.=-  +- .=-+:=::+. -+=     .:-.        =+.  .+=   :+=.=+:   -+:       +=:::=+..-+:
 *     --    .--       .+.  .+:  ==-=: -+:  ===:.======-::+-       =+.  :+:   =+:-+-   :+=       .+=  .+--+-.
 *     .-              .+.  :+.   :.                      :+.      .-    .    .-=-.    =+.        :==-=+=:.
 *                      +:  .+                            :-                           ..            ..
 *
 *                                                On-Chain Metadata
 */
contract PixelPioneerMetadata is PixelPioneerMetadataBase {
    address private constant COMPANION_ART_CONTRACT = 0x8abC21a84992b8C50c086D5133D6B428b8FC7439; // PixelPioneerArtwork V1
    string private constant GENERIC_TOKEN_DESCRIPTION = 'Pixel Pioneer [Keith Haring Foundation](https://www.haring.com/) | [NFT Usage License](https://www.haring.com/!/nft-ownership-license)';
    string private constant TOKEN_EXTERNAL_URL = 'https://www.haring.com/';
    uint256 private constant NUMBER_OF_TOKEN_TYPES_ALLOWED = 5; // Max of 5 tokens.

    constructor()
        SimpleChainNativeArtConsumer(COMPANION_ART_CONTRACT)
        TokenMetadataManager(NUMBER_OF_TOKEN_TYPES_ALLOWED)
        CollectionMetadataManager(GENERIC_TOKEN_DESCRIPTION, TOKEN_EXTERNAL_URL)
    {
        // Implementation version: v1.0.0
    }

    /**
     *  struct DynamicAttributes {
     *     uint256 tokenType;
     *     bool isSerialized;
     *     bool isAnimated;
     *     bool hasTokenDescription;
     *     string title;
     *     string tokenDescription;
     *     string[] attributeNames;
     *     string[] attributeValues;
     *  }
     */
    function _getInitialDefinitions() internal pure override returns (DynamicAttributesV1[] memory) {
        string[] memory attributeFieldNames = new string[](4);
        attributeFieldNames[0] = 'ARTIST';
        attributeFieldNames[1] = 'LOCATION';
        attributeFieldNames[2] = 'YEAR';
        attributeFieldNames[3] = 'FILE FORMATS';

        string[] memory tokenOneValues = new string[](4);
        tokenOneValues[0] = 'Keith Haring';
        tokenOneValues[1] = 'New York City, New York';
        tokenOneValues[2] = '1987';
        tokenOneValues[3] = 'PICT, PNG, SVG';

        string[] memory tokenTwoValues = new string[](4);
        tokenOneValues[0] = 'Keith Haring';
        tokenOneValues[1] = 'New York City, New York';
        tokenOneValues[2] = '1987';
        tokenOneValues[3] = 'PICT, PNG, SVG';

        string[] memory tokenThreeValues = new string[](4);
        tokenOneValues[0] = 'Keith Haring';
        tokenOneValues[1] = 'New York City, New York';
        tokenOneValues[2] = '1987';
        tokenOneValues[3] = 'PICT, PNG, SVG';

        string[] memory tokenFourValues = new string[](4);
        tokenOneValues[0] = 'Keith Haring';
        tokenOneValues[1] = 'New York City, New York';
        tokenOneValues[2] = '1987';
        tokenOneValues[3] = 'PICT, PNG, SVG';

        string[] memory tokenFiveValues = new string[](4);
        tokenOneValues[0] = 'Keith Haring';
        tokenOneValues[1] = 'New York City, New York';
        tokenOneValues[2] = '1987';
        tokenOneValues[3] = 'PICT, PNG, SVG';

        DynamicAttributesV1[] memory initialAttributesDefinitions = new DynamicAttributesV1[](5);

        initialAttributesDefinitions[0] = DynamicAttributesV1(
            1,
            false,
            false,
            false,
            'Untitled (April 14, 1987)',
            '',
            attributeFieldNames,
            tokenOneValues
        );
        initialAttributesDefinitions[1] = DynamicAttributesV1(
            2,
            false,
            false,
            false,
            'Untitled #1 (April 16, 1987)',
            '',
            attributeFieldNames,
            tokenTwoValues
        );
        initialAttributesDefinitions[2] = DynamicAttributesV1(
            3,
            false,
            false,
            false,
            'Untitled #2 (April 16, 1987)',
            '',
            attributeFieldNames,
            tokenThreeValues
        );
        initialAttributesDefinitions[3] = DynamicAttributesV1(
            4,
            false,
            false,
            false,
            'Untitled (Feb 2, 1987)',
            '',
            attributeFieldNames,
            tokenFourValues
        );
        initialAttributesDefinitions[4] = DynamicAttributesV1(
            5,
            false,
            false,
            false,
            'Untitled (Feb 3, 1987)',
            '',
            attributeFieldNames,
            tokenFiveValues
        );

        return initialAttributesDefinitions;
    }
}
