// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/// @title OneInTenThousand
/// @author jpegmint.xyz

import "./Strings.sol";
import "./Ownable.sol";
import "./ERC2309.sol";

/**
 ██╗        ██╗     ██╗ ██████╗     ██████╗  ██████╗  ██████╗ 
███║       ██╔╝    ███║██╔═████╗   ██╔═████╗██╔═████╗██╔═████╗
╚██║      ██╔╝     ╚██║██║██╔██║   ██║██╔██║██║██╔██║██║██╔██║
 ██║     ██╔╝       ██║████╔╝██║   ████╔╝██║████╔╝██║████╔╝██║
 ██║    ██╔╝        ██║╚██████╔╝▄█╗╚██████╔╝╚██████╔╝╚██████╔╝
 ╚═╝    ╚═╝         ╚═╝ ╚═════╝ ╚═╝ ╚═════╝  ╚═════╝  ╚═════╝ 
*/                                                                                      
contract OneInTenThousand is ERC2309, Ownable {
    using Strings for uint256;

    uint256 public constant TOKEN_MAX_SUPPLY = 10000;
    bytes16 private constant _HEX_SYMBOLS = "0123456789ABCDEF";

    address private _initialOwner;

    error AlreadyMinted();
    error URIQueryForNonexistentToken();

    constructor() ERC2309("OneInTenThousand", "ONEINTENK") {}

    function mint() external onlyOwner {
        if (totalSupply() > 0) revert AlreadyMinted();

        _initialOwner = msg.sender;
        _mint(msg.sender, uint128(TOKEN_MAX_SUPPLY));
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert OwnerQueryForNonexistentToken();
        return _owners[tokenId] == address(0) ? _initialOwner : _owners[tokenId];
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        bytes memory tokenName = abi.encodePacked('#', tokenId.toString(), '/', TOKEN_MAX_SUPPLY.toString());

        bytes memory byteString;
        byteString = abi.encodePacked(byteString, 'data:application/json;utf8,{');
        byteString = abi.encodePacked(byteString, '"name": "', tokenName, '",');
        byteString = abi.encodePacked(byteString, '"description": '
            ,'"**One in Ten Thousand** (b. 2022)\\n\\n', tokenName, '\\n\\n*Hand crafted SVG, 1000 x 1000 pixels*",'
        );
        byteString = abi.encodePacked(byteString, '"image": "data:image/svg+xml;utf8,' ,_generateSvg(tokenId), '"');
        byteString = abi.encodePacked(byteString, '}');
        
        return string(byteString);
    }

    function _generateColorHexCode(uint256 tokenId) private pure returns (bytes memory) {
        
        bytes32 random = keccak256(abi.encodePacked(tokenId));
        uint8 r = uint8(random[0]);
        uint8 g = uint8(random[1]);
        uint8 b = uint8(random[2]);

        bytes memory buffer = new bytes(6);
        buffer[0] = _HEX_SYMBOLS[r >> 4 & 0xf];
        buffer[1] = _HEX_SYMBOLS[r & 0xf];
        buffer[2] = _HEX_SYMBOLS[g >> 4 & 0xf];
        buffer[3] = _HEX_SYMBOLS[g & 0xf];
        buffer[4] = _HEX_SYMBOLS[b >> 4 & 0xf];
        buffer[5] = _HEX_SYMBOLS[b & 0xf];
        return buffer;
    }

    function _generateSvg(uint256 tokenId) private pure returns (bytes memory svg) {

        uint256 x = (tokenId - 1) % 100 * 10;
        uint256 y = (tokenId - 1) / 100 * 10;

        svg = abi.encodePacked("<svg xmlns='http://www.w3.org/2000/svg' width='1000' height='1000'>"
            ,"<defs><pattern id='g' width='20' height='20' patternUnits='userSpaceOnUse'>"
            ,"<rect x='0' y='0' width='10' height='10' opacity='0.1'/><rect fill='white' x='10' y='0' width='10' height='10'/>"
            ,"<rect x='10' y='10' width='10' height='10' opacity='0.1'/><rect fill='white' x='0' y='10' width='10' height='10'/>"
            ,"</pattern></defs><rect fill='url(#g)' x='0' y='0' width='100%' height='100%'/>"
        );

        svg = abi.encodePacked(svg
            ,"<rect fill='#", _generateColorHexCode(tokenId), "' x='", x.toString(), "' y='", y.toString(), "' width='10' height='10'/>"
            ,'</svg>'
        );

        return svg;
    }
}
