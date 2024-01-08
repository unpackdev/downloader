// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @artist: Mad Dog Jones
/// @author: manifold.xyz

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                        //
//                                                                                                                                                        //
//      ####    ####    ####################### ######          #######   ##################                 ###### ###############    ####    ####       //
//      ####    ####    ###################### #######        ########   ####################               ###### ################    ####    ####       //
//  ####    ####    ####    ################# ########      #########   ######         ######              ###### #############    ####    ####    ####   //
//  ####    ####    ####    ################ #########    ##########   ######         ######              ###### ##############    ####    ####    ####   //
//      ####    ####    ################### ##########  ###########   ######         ######              ###### ###################    ####    ####       //
//      ####    ####    ################## ########### ###########   ######         ######              ###### ####################    ####    ####       //
//  ####    ####    ####    ############# #######################   ######         ######   ######     ###### #################    ####    ####    ####   //
//  ####    ####    ####    ############ ######  #######  ######   ######         ######   ######     ###### ##################    ####    ####    ####   //
//      ####    ####    ####    ####### ######   #####   ######   ####################    ################# ###############    ####    ####    ####       //
//      ####    ####    ####    ###### ######           ######   ##################       ############### #################    ####    ####    ####       //
//                                                                                                                                                        //
//                                                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

import "./IERC721CreatorCore.sol";
import "./ICreatorExtensionTokenURI.sol";
import "./ERC721BurnRedeem.sol";

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC165.sol";

/**
 * Meow - New information has come to light.
 */
contract MeowNewInformationHasComeToLight is Ownable, ERC721BurnRedeem, ICreatorExtensionTokenURI {

    using Strings for uint256;

    string constant private _EDITION_TAG = '<EDITION>';
    string[] private _uriParts;
    bool private _active;

    constructor(address creator) ERC721BurnRedeem(creator, 1, 99) {
        _uriParts.push('data:application/json;utf8,{"name":"New information has come to light. #');
        _uriParts.push('<EDITION>');
        _uriParts.push('/99", "created_by":"Mad Dog Jones", ');
        _uriParts.push('"description":"Meow.\\n\\nMichah Dowbak aka Mad Dog Jones (b. 1985)\\n\\nNew information has come to light., 2021", ');
        _uriParts.push('"image":"https://arweave.net/XRefVklT1k3whHPEPIMccGr6QoEQtKJAL4yH5lWa7X8","image_url":"https://arweave.net/XRefVklT1k3whHPEPIMccGr6QoEQtKJAL4yH5lWa7X8","image_details":{"sha256":"dc00ae1bc6c55488e76014569419c8461c9fd8f99a8bc1d61e219f9b5894d6b6","bytes":19825623,"width":4800,"height":6000,"format":"PNG"},');
        _uriParts.push('"animation":"https://arweave.net/N7teql3oh6UfjvA5SFqcPnUOJuGUX0gZW-hYazg0WuA","animation_url":"https://arweave.net/N7teql3oh6UfjvA5SFqcPnUOJuGUX0gZW-hYazg0WuA","animation_details":{"sha256":"1882bcc83e553c115fea27076adeb874ce12062efcb353467c83954c8e595ca5","bytes":27273362,"width":4800,"height":6000,"duration":21,"format":"MP4","codecs":["H.264","AAC"]},');
        _uriParts.push('"attributes":[{"trait_type":"Artist","value":"Mad Dog Jones"},{"trait_type":"Collection","value":"Meow"},{"trait_type":"Edition","value":"B"},{"display_type":"number","trait_type":"Edition","value":');
        _uriParts.push('<EDITION>');
        _uriParts.push(',"max_value":99}]}');

    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721BurnRedeem, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Activate the contract and mint the first token
     */
    function activate() public onlyOwner {
        // Mint the first one to the owner
        require(!_active, "Already active");
        _active = true;
        _mintRedemption(owner());
    }

    /**
     * @dev update the URI data
     */
    function updateURIParts(string[] memory uriParts) public onlyOwner {
        _uriParts = uriParts;
    }

    /**
     * @dev Generate uri
     */
    function _generateURI(uint256 tokenId) private view returns(string memory) {
        bytes memory byteString;
        for (uint i = 0; i < _uriParts.length; i++) {
            if (_checkTag(_uriParts[i], _EDITION_TAG)) {
               byteString = abi.encodePacked(byteString, (100-_mintNumbers[tokenId]).toString());
            } else {
              byteString = abi.encodePacked(byteString, _uriParts[i]);
            }
        }
        return string(byteString);
    }

    function _checkTag(string storage a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    /**
     * @dev See {IERC721RedeemBase-mintNumber}.
     * Override for reverse numbering
     */
    function mintNumber(uint256 tokenId) external view override returns(uint256) {
        require(_mintNumbers[tokenId] != 0, "Invalid token");
        return 100-_mintNumbers[tokenId];
    }

    /**
     * @dev See {IRedeemBase-redeemable}.
     */
    function redeemable(address contract_, uint256 tokenId) public view virtual override returns(bool) {
        require(_active, "Inactive");
        return super.redeemable(contract_, tokenId);
    }

    /**
     * @dev See {ICreatorExtensionTokenURI-tokenURI}.
     */
    function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
        require(creator == _creator && _mintNumbers[tokenId] != 0, "Invalid token");
        return _generateURI(tokenId);
    }
    

}
