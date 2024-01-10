// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// NFTC Open Source Libraries See: https://github.com/NFTCulture/nftc-open-contracts
import "./OnChainEncoding.sol";

// OZ Libraries
import "./Ownable.sol";

/**
 * @title SolidarityMetadataBase
 * @author @NiftyMike, NFT Culture
 * @dev Companion contract to SolidarityNFTProjectForUkraine.
 *
 * Responsible for returning on-chain metadata. Built as a separate contract to allow
 * for corrections or improvements to the metadata.
 */
contract SolidarityMetadataBase is Ownable {
    using OnChainEncoding for uint8;

    uint256 public version;

    uint256 private constant TOKEN_TYPE_ONE = 1;
    uint256 private constant TOKEN_TYPE_TWO = 2;

    string private baseURI;
    string private tokenTypeOneURIPart;
    string private tokenTypeTwoURIPart;

    constructor(
        string memory __baseURI,
        string memory __tokenTypeOneURIPart,
        string memory __tokenTypeTwoURIPart
    ) {
        baseURI = __baseURI;
        tokenTypeOneURIPart = __tokenTypeOneURIPart;
        tokenTypeTwoURIPart = __tokenTypeTwoURIPart;
    }

    function setBaseURI(string memory __baseUri) external onlyOwner {
        baseURI = __baseUri;
    }

    function setTokenTypeURIs(
        string memory __tokenTypeOneURIPart,
        string memory __tokenTypeTwoURIPart
    ) external onlyOwner {
        tokenTypeOneURIPart = __tokenTypeOneURIPart;
        tokenTypeTwoURIPart = __tokenTypeTwoURIPart;
    }

    function getAsString(uint256 tokenId, uint256 tokenType) external view returns (string memory) {
        require(tokenType == TOKEN_TYPE_ONE || tokenType == TOKEN_TYPE_TWO, 'Invalid token type');

        if (tokenType == TOKEN_TYPE_ONE) {
            return _videoMetadataString(tokenId);
        } else if (tokenType == TOKEN_TYPE_TWO) {
            return _photoMetadataString(tokenId);
        }

        // unreachable.
        return '';
    }

    function getAsEncodedString(uint256 tokenId, uint256 tokenType)
        external
        view
        returns (string memory)
    {
        require(tokenType == TOKEN_TYPE_ONE || tokenType == TOKEN_TYPE_TWO, 'Invalid token type');

        if (tokenType == TOKEN_TYPE_ONE) {
            return _encode(_videoMetadataString(tokenId));
        } else if (tokenType == TOKEN_TYPE_TWO) {
            return _encode(_photoMetadataString(tokenId));
        }

        // unreachable.
        return '';
    }

    function _encode(string memory stringToEncode) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    OnChainEncoding.encode(bytes(stringToEncode))
                )
            );
    }

    function _photoMetadataString(uint256 tokenId) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '{"name": "Valeriia #',
                    OnChainEncoding.toString(tokenId),
                    '", "description": "This image was taken in March 2022 in Lviv, Ukraine.  It represents Valeriia, a 5-year-old refugee fleeing the war and it was on the cover of Time Magazine.", "image": "',
                    _photoAsset(),
                    '","attributes": [',
                    _photoAttributes(),
                    '], "external_url": "https://jr-art.io/"}'
                )
            );
    }

    function _videoMetadataString(uint256 tokenId) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '{"name": "Valeriia Unfurling #',
                    OnChainEncoding.toString(tokenId),
                    '", "description": "This video was taken in March 2022 in Lviv, Ukraine.  It represents Valeriia, a 5-year-old refugee fleeing the war and it was featured on Time.com.", "image": "',
                    _videoAsset(),
                    '","attributes": [',
                    _videoAttributes(),
                    '], "external_url": "https://jr-art.io/"}'
                )
            );
    }

    function _photoAttributes() internal pure virtual returns (string memory) {
        return
            '{"trait_type": "ARTIST", "value": "JR"}, {"trait_type": "FORMAT", "value": "Photo"}, {"trait_type": "LOCATION", "value": "Lviv, Ukraine"}, {"trait_type": "YEAR", "value": "2022"}';
    }

    function _photoAsset() internal view virtual returns (bytes memory) {
        require(bytes(baseURI).length > 0, 'Base unset');
        require(bytes(tokenTypeTwoURIPart).length > 0, 'Type2 unset');

        return abi.encodePacked(baseURI, tokenTypeTwoURIPart);
    }

    function _videoAttributes() internal pure virtual returns (string memory) {
        return
            '{"trait_type": "ARTIST", "value": "JR"}, {"trait_type": "FORMAT", "value": "Video"}, {"trait_type": "LOCATION", "value": "Lviv, Ukraine"}, {"trait_type": "YEAR", "value": "2022"}';
    }

    function _videoAsset() internal view virtual returns (bytes memory) {
        require(bytes(baseURI).length > 0, 'Base unset');
        require(bytes(tokenTypeOneURIPart).length > 0, 'Type1 unset');

        return abi.encodePacked(baseURI, tokenTypeOneURIPart);
    }
}
