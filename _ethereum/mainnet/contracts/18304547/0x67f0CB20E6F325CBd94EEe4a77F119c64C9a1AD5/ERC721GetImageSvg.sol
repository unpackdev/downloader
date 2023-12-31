// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.21;

import "./Context.sol";
import "./ERC721.sol";
import "./ERC165.sol";
import "./IERC721GetImageSvg.sol";

// ref: 
abstract contract ERC721GetImageSvg is Context, ERC721, IERC721GetImageSvg {
    // Mapping for token Images
    mapping(uint256 => string) private _tokenImageSvgs;
    string constant svgPrefix = '<?xml version="1.0" encoding="UTF-8" standalone="no"?> <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd"> ';

    /*
     *     bytes4(keccak256('getTokenImageSvg(uint256)')) == 0x87d2f48c
     *
     *     => 0x87d2f48c == 0x87d2f48c
     */
    //bytes4 private constant _INTERFACE_ID_ERC721_GET_TOKEN_IMAGE_SVG = 0x87d2f48c;

    /**
     * @dev Constructor function
     */
    constructor (string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        // register the supported interfaces to conform to ERC721 via ERC165
        //_registerInterface(_INTERFACE_ID_ERC721_GET_TOKEN_IMAGE_SVG);
    }

    /**
     * @dev Returns an SVG Image for a given token ID.
     * Throws if the token ID does not exist. May return an empty string.
     * @param tokenId uint256 ID of the token to query
     */
    function getTokenImageSvg(uint256 tokenId) external override view returns (string memory) {
        require(_exists(tokenId), "ERC721GetImageSvg: SVG Image query for nonexistent token");
        string memory svg = _tokenImageSvgs[tokenId];
        require(bytes(svg).length > 10);

        return string(
            abi.encodePacked(
                svgPrefix,
                _tokenImageSvgs[tokenId]
            )
        );
    }

    /**
     * @dev Internal function to set the token SVG image for a given token.
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to set its SVG image
     * @param imagesvg string SVG  to assign
     */
    function setTokenImageSvg(uint256 tokenId, string memory imagesvg) internal {
        require(_exists(tokenId), "ERC721GetImageSvg: SVG image set of nonexistent token");
        _tokenImageSvgs[tokenId] = imagesvg;
    }

    function deleteToken(uint256 tokenId) internal returns (bool) {
        setTokenImageSvg(tokenId, "");
        delete _tokenImageSvgs[tokenId];
        return true;
    }

    function supportsInterface(bytes4 interfaceId)
        public virtual
        view
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}