// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./IERC721CreatorCore.sol";
import "./ICreatorExtensionTokenURI.sol";

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC165.sol";

/**
 * Last Orders!
 */
contract LastOrders is Ownable, ERC165, ICreatorExtensionTokenURI {

    using Strings for uint256;

    address private _creator;
    uint16 private _minted;
    mapping(uint256 => uint16) _tokenEdition;

    constructor(address creator) {
        _creator = creator;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || super.supportsInterface(interfaceId);
    }

    function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
        require(creator == _creator && _tokenEdition[tokenId] != 0, "Invalid token");
        return string(abi.encodePacked('data:application/json;utf8,{"name":"Last Orders! #',uint256(_tokenEdition[tokenId]).toString(),'","created_by":"Alpha Centauri Kid","description":"Drink up frens.\\n\\nAlpha Centauri Kid & XCOPY\\n","image":"https://arweave.net/8r2Nc5iczwQ75QbGE4C9PDr8hvi_yrPXOsW_BhRwB0s","image_url":"https://arweave.net/8r2Nc5iczwQ75QbGE4C9PDr8hvi_yrPXOsW_BhRwB0s","image_details":{"bytes":9072063,"format":"PNG","sha256":"e15222809ee03ea33c117cacf871208216b5d55a22a0589d6c2f525bc9626422","width":3840,"height":2160},"animation":"https://arweave.net/K54eNVwjEChreLTq3bsKZX6yN8GUEVLFzNtJH_l5g9Q","animation_url":"https://arweave.net/K54eNVwjEChreLTq3bsKZX6yN8GUEVLFzNtJH_l5g9Q","animation_details":{"bytes":66681013,"format":"MP4","duration":10,"sha256":"dc62aea0be515e1b75896d05f16b8827f4f87108c793376833c6142d16e8d4e8","width":3840,"height":2160,"codecs":["H.264","AAC"]},"attributes":[{"trait_type":"Artist","value":"Alpha Centauri Kid"},{"trait_type":"Bartender","value":"XCOPY"}]}'));
    }

    function mint(address[] calldata receivers) external onlyOwner {
        require(_minted+receivers.length <= 27, "Only 27 available");
        for (uint i = 0; i < receivers.length; i++) {
            _minted += 1;
            _tokenEdition[IERC721CreatorCore(_creator).mintExtension(receivers[i])] = _minted;
        }
    }
}
