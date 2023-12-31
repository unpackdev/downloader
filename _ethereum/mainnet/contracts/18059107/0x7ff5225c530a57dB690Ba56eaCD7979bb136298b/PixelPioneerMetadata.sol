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
    string private constant GENERIC_TOKEN_DESCRIPTION =
        'Keith Haring: Pixel Pioneer series one of five unique digital drawings created on an Amiga computer in the mid-1980s. To accurately preserve the natively digital material created on a now-vintage computer system the Keith Haring Foundation has minted these five Amiga artworks - previously only viewable via floppy disks - on the Ethereum blockchain. [Keith Haring Foundation](https://www.haring.com/) | [NFT Ownership License](https://www.haring.com/!/nft-ownership-license)';
    string private constant TOKEN_EXTERNAL_URL = 'https://www.haring.com/';
    string private constant VIEWER_URL =
        'https://nftc-media.mypinata.cloud/ipfs/QmTUQZD3wxNZ23mQ9k69mWQU3eNmMg3Kf3d1djCiw45UUe';
    uint256 private constant NUMBER_OF_TOKEN_TYPES_ALLOWED = 5; // Max of 5 tokens.

    constructor()
        SimpleChainNativeArtConsumer(COMPANION_ART_CONTRACT)
        TokenMetadataManager(NUMBER_OF_TOKEN_TYPES_ALLOWED)
        CollectionMetadataManager('', TOKEN_EXTERNAL_URL)
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
        tokenTwoValues[0] = 'Keith Haring';
        tokenTwoValues[1] = 'New York City, New York';
        tokenTwoValues[2] = '1987';
        tokenTwoValues[3] = 'PICT, PNG, SVG';

        string[] memory tokenThreeValues = new string[](4);
        tokenThreeValues[0] = 'Keith Haring';
        tokenThreeValues[1] = 'New York City, New York';
        tokenThreeValues[2] = '1987';
        tokenThreeValues[3] = 'PICT, PNG, SVG';

        string[] memory tokenFourValues = new string[](4);
        tokenFourValues[0] = 'Keith Haring';
        tokenFourValues[1] = 'New York City, New York';
        tokenFourValues[2] = '1987';
        tokenFourValues[3] = 'PICT, PNG, SVG';

        string[] memory tokenFiveValues = new string[](4);
        tokenFiveValues[0] = 'Keith Haring';
        tokenFiveValues[1] = 'New York City, New York';
        tokenFiveValues[2] = '1987';
        tokenFiveValues[3] = 'PICT, PNG, SVG';

        DynamicAttributesV1[] memory initialAttributesDefinitions = new DynamicAttributesV1[](5);

        initialAttributesDefinitions[0] = DynamicAttributesV1(
            1,
            false,
            false,
            true,
            'Untitled (April 14, 1987)',
            string.concat(GENERIC_TOKEN_DESCRIPTION, ' | [View Full Screen](', VIEWER_URL, '?tokenType=1)'),
            attributeFieldNames,
            tokenOneValues
        );
        initialAttributesDefinitions[1] = DynamicAttributesV1(
            2,
            false,
            false,
            true,
            'Untitled #1 (April 16, 1987)',
            string.concat(GENERIC_TOKEN_DESCRIPTION, ' | [View Full Screen](', VIEWER_URL, '?tokenType=2)'),
            attributeFieldNames,
            tokenTwoValues
        );
        initialAttributesDefinitions[2] = DynamicAttributesV1(
            3,
            false,
            false,
            true,
            'Untitled #2 (April 16, 1987)',
            string.concat(GENERIC_TOKEN_DESCRIPTION, ' | [View Full Screen](', VIEWER_URL, '?tokenType=3)'),
            attributeFieldNames,
            tokenThreeValues
        );
        initialAttributesDefinitions[3] = DynamicAttributesV1(
            4,
            false,
            false,
            true,
            'Untitled (Feb 2, 1987)',
            string.concat(GENERIC_TOKEN_DESCRIPTION, ' | [View Full Screen](', VIEWER_URL, '?tokenType=4)'),
            attributeFieldNames,
            tokenFourValues
        );
        initialAttributesDefinitions[4] = DynamicAttributesV1(
            5,
            false,
            false,
            true,
            'Untitled (Feb 3, 1987)',
            string.concat(GENERIC_TOKEN_DESCRIPTION, ' | [View Full Screen](', VIEWER_URL, '?tokenType=5)'),
            attributeFieldNames,
            tokenFiveValues
        );

        return initialAttributesDefinitions;
    }
}
