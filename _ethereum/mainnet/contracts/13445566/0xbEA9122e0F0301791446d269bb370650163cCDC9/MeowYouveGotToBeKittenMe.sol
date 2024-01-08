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
 * Meow - You've got to be kitten me
 */
contract MeowYouveGotToBeKittenMe is Ownable, ERC721BurnRedeem, ICreatorExtensionTokenURI {

    using Strings for uint256;

    string constant private _EDITION_TAG = '<EDITION>';
    string[] private _uriParts;
    bool private _active;

    constructor(address creator) ERC721BurnRedeem(creator, 1, 99) {
        _uriParts.push('data:application/json;utf8,{"name":"You\'ve got to be kitten me. #');
        _uriParts.push('<EDITION>');
        _uriParts.push('/99", "created_by":"Mad Dog Jones", ');
        _uriParts.push('"description":"Meow.\\n\\nMichah Dowbak aka Mad Dog Jones (b. 1985)\\n\\nYou\'ve got to be kitten me., 2021", ');
        _uriParts.push('"image":"https://arweave.net/zTjMK4iDPgxc3F8CNCnBQODAojJ4ACQaKTPWE2EkgvM","image_url":"https://arweave.net/zTjMK4iDPgxc3F8CNCnBQODAojJ4ACQaKTPWE2EkgvM","image_details":{"bytes":17834328,"format":"PNG","sha256":"87dc8fce3d63cf4ecfd58635ef64524f909fb98d8a8f4091333726d2c2038d7f","width":4800,"height":6000},');
        _uriParts.push('"animation":"https://arweave.net/nvbcYKRxVRxYIG4QAff5Xk0hrMOT6-vhkGhEPGX0Va8","animation_url":"https://arweave.net/nvbcYKRxVRxYIG4QAff5Xk0hrMOT6-vhkGhEPGX0Va8","animation_details":{"bytes":38964665,"format":"MP4","duration":30,"sha256":"f6445179bb6d89569a9906625f1a5abb45027ac1eedfe2592a92279334929486","width":4800,"height":6000,"codecs":["H.264","AAC"]},');
        _uriParts.push('"attributes":[{"trait_type":"Artist","value":"Mad Dog Jones"},{"trait_type":"Collection","value":"Meow"},{"trait_type":"Edition","value":"C"},{"display_type":"number","trait_type":"Edition","value":');
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
