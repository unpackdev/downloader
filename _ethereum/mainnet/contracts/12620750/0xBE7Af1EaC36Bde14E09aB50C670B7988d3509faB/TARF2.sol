// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./IERC721CreatorCore.sol";
import "./ICreatorExtensionTokenURI.sol";

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC165.sol";

/**
 * Todd and Rahul's Angel Fund 2
 */
contract TARF2 is Ownable, ERC165, ICreatorExtensionTokenURI {

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
        return string(abi.encodePacked('data:application/json;utf8,{"name":"A Day in the Life: Inside T&R Laboratories", "created_by":"Todd and Rahul\'s Angel Fund", "description":"Dear esteemed guest, it is our great pleasure to welcome you to an exclusive, never-before-seen tour of T&R Laboratories. For legal reasons, the date and location cannot be disclosed at this time, but we encourage you to walk about the space and take in the wonderful innovations we have prepared for you today. Please take care not to disturb our teammates as they are engaged in serious play at this time.\\n\\n(Designed by Ahmet iltas)", "image":"https://arweave.net/nw_wDxs8FKdGazqSabJZi3c-sRB93Zgvd8t0kAkl_AM","image_url":"https://arweave.net/nw_wDxs8FKdGazqSabJZi3c-sRB93Zgvd8t0kAkl_AM","image_details":{"sha256":"cd16d45362cf5c2898c96cf6516e6bcfd480820dd2030a71e18a117fa12ed684","bytes":35330157,"width":7000,"height":3938,"format":"PNG"},"animation":"https://arweave.net/9rEmzBl6HyXRD2BRQemCyrW4QGH7KT4RXVaMhK5PCvw","animation_url":"https://arweave.net/9rEmzBl6HyXRD2BRQemCyrW4QGH7KT4RXVaMhK5PCvw","animation_details":{"sha256":"dae73763274f08569685732cc0f225c8b4d36227ae771a1fa2b5cdeb0af37a6e","bytes":30535535,"width":3840,"height":2160,"duration":8,"format":"MP4","codecs":["H.264"]},"attributes":[{"trait_type":"Artist","value":"Todd and Rahul\'s Angel Fund"},{"display_type":"number","trait_type":"Edition","value":',uint256(_tokenEdition[tokenId]).toString(),',"max_value":500}]}'));
        
    }

    function airdrop(address[] calldata receivers) external onlyOwner {
        require(_minted+receivers.length <= 500, "Only 500 available");
        for (uint i = 0; i < receivers.length; i++) {
            _minted += 1;
            _tokenEdition[IERC721CreatorCore(_creator).mintExtension(receivers[i])] = _minted;
        }
    }
}
