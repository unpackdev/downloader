// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./IERC721CreatorCore.sol";
import "./ICreatorExtensionTokenURI.sol";

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC165.sol";

/**
 * Bored Ness Ape Club
 */
contract BoredNessApeClub is Ownable, ERC165, ICreatorExtensionTokenURI {

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
        return string(abi.encodePacked('data:application/json;utf8,{"name":"Bored Ness Ape Club #',uint256(_tokenEdition[tokenId]).toString(),'","created_by":"NessGraphics","description":"NessGraphics\' Bored Ness Ape Club.\\n\\nAlthough Agent Ape #2306 may seem like he is the chimpion of the monkey business,you will come to the kongclusion that he is anything but. As he sits at his operations command center,he is solely responsible to remain bored,yet focused.\\n\\nThe mission,dubbed \'The Apes of Wrath\' was green-lighted to ensure that the coordinated gorilla warfare against the primate change deniers is strategic and successful. As he quietly types away into the wee hours of the night,he keeps close watch on his community while making certain that not even one of his tribe is caught monkeying around or going bananas. \\n\\nExtra bananas for Danny_p3d for adding some shape to the ape.","image":"https://arweave.net/WFht8dinIdS8aJW0Z8BUIXnq4tP5TVv_WxtHQwS-Sjo","image_url":"https://arweave.net/WFht8dinIdS8aJW0Z8BUIXnq4tP5TVv_WxtHQwS-Sjo","image_details":{"sha256":"cb2e100b473b6c8f099710da3b5e58be387ace6a33a065cc4f594c3cb1ce52ba","bytes":8156342,"width":2160,"height":2160,"format":"PNG"},"animation":"https://arweave.net/RdoLzk-h4hxqIyC68DbiHyNO2J-nK3TgBhTGSlrA764","animation_url":"https://arweave.net/RdoLzk-h4hxqIyC68DbiHyNO2J-nK3TgBhTGSlrA764","animation_details":{"sha256":"57125a36ba0bf0578a992b5ee092b698d613feb7cdbab7d29b9463b669f28046","bytes":58115638,"width":2160,"height":2160,"duration":26,"format":"MP4","codecs":["AAC","H.264"]},"COMMS":"INCOMING MESSAGE FROM 917-819-2193: 01010100 01001000 01000101 00100000 01000001 01010000 01000101 01010011 00100000 01001000 01000001 01010110 01000101 00100000 01010100 01000001 01001011 01000101 01001110 00100000 01001111 01010110 01000101 01010010 00100000 01010100 01001000 01000101 00100000 01001111 01010000 01000101 01010010 01000001 01010100 01001001 01001111 01001110 01010011 00100000 01000011 01001111 01001101 01001101 01000001 01001110 01000100 00100000 01000011 01000101 01001110 01010100 01000101 01010010 00101110 00100000 01001001 00100000 01010010 01000101 01010000 01000101 01000001 01010100 00100000 01010100 01001000 01000101 00100000 01000001 01010000 01000101 01010011 00100000 01001000 01000001 01010110 01000101 00100000 01010100 01000001 01001011 01000101 01001110 00100000 01001111 01010110 01000101 01010010 00100000 01010100 01001000 01000101 00100000 01001111 01010000 01000101 01010010 01000001 01010100 01001001 01001111 01001110 01010011 00100000 01000011 01001111 01001101 01001101 01000001 01001110 01000100 00100000 01000011 01000101 01001110 01010100 01000101 01010010 00101110"}'));
    }

    function mintApes(address[] calldata receivers) external onlyOwner {
        require(_minted+receivers.length <= 100, "Only 100 available");
        for (uint i = 0; i < receivers.length; i++) {
            _minted += 1;
            _tokenEdition[IERC721CreatorCore(_creator).mintExtension(receivers[i])] = _minted;
        }
    }
}
