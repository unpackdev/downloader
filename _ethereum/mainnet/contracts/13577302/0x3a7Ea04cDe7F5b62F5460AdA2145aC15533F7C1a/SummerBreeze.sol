// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @artist: RHYMEZLIKEDIMEZ
/// @author: manifold.xyz

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                           //
//                                                                                                     @@@@                                                  //
//                                                                                                    @(   (@                                                //
//                                                                                                    .@@@&@.                                                //
//                                                                                                                &@@@&&@@@&                                 //
//                                                                                                             /@/          *@%                              //
//                                                                                                            @@              &@                             //
//                                                                        #@&@@@@@@&@#                        @.     ........  @/                            //
//                                                                  %@@%                %@@%                  @@     ..,.,.,,./@                             //
//                                                               @@.                        .@@                .@@  ..,,.,,..@@                              //
//                                                            #@/                              #@#               .@   .&@@@@.                                //
//                                                          .@/                                  *@.              @.@@                                       //
//                                                         @@                                      @@           &@( @                                        //
//                                      @@@@@*       .#@@@@@                              .         &@@@%.           @@                                      //
//                                  @@&                                   .     .    ...    ...                         #@@,                                 //
//                               @@                                         ..    ..    . .   .  . ..      .                @@                               //
//                             @&                             .      ...   . .  ...  .. . ...  .. ... .  ...                  &@*                            //
//                           @&                                    ..  . . .... .... ....,.. ...... ........ . .     . .        @@                           //
//                          @%                                 ... ... . .  .......,.....,...,... .........,..,.... ..           *@                          //
//                         @@                    .  .     ... . ..........,..... ,,,......,..,, .......,,.....,..,,. .......      (@                         //
//                        &@                   .. .    .  .. ....,.......,....,..,.,..,,,,,,,,.,.,,.,.,.,...,.,...... .....  .     @@                        //
//                        @&              .    . ... ..............,..,..,...,,.,,*,,,,..,,,,...,.,.,,,,...,.,,.....,........      (@                        //
//                        @&                     . ...,,*,,...,.,..,.,.,,,,.,*,....,,.,,,,,,,..,,*(##%(*,,,,.,,,,..,,.,...,...... .(@                        //
//                        @@     .          . .@@@/     **.   &@@@*.,,..,..,,,,,**.,,,.,,.*@@@&   .,*((*. .@@@&.*,,.,.,..........  &&                        //
//                        *@.             .%@@ .##################%@@@.,,,,,,,,,.,,,,,,(@@  ###################%@@,.,,.,.,,....... @,                        //
//                         @@       .   .@@ /#########################@@,,**@@@@@&,,,@@. #########################&@%*,*.,..,.., .@@                         //
//                  ./@@@@/            &@ ##############################@@#        @@.(#############################&@,,,,,*,*,,..  /@@@@/                   //
//           .@@@@@@@@(               @@.################################@@@&/**/@@@ #################################@/,**.,,,,,..     #@@@@@@@@            //
//        @@@@@@@@@&                 @@(########################,   ######@@**/**(@.#######################(  ,#######.@*,.,,,.,.,.....    @@@@@@@@@@        //
//     &@@@@@@@@@&               . ..@ #######      ##########      #####( @/,*,,@@######     .##########      /####   @@**,,,,,,,,,.,..     &@@@@@@@@@#     //
//   .@@@@@@@@@@                   .*@######        %###%##.               @%,*,.@@####        %######*                %@/,,,.,,,,,,.,,.,..    @@@@@@@@@@    //
//  ,@@@@@@@@@@      .         .  ...@####          (####              ,%  @#,**.@@%#          (####                #. @@**.,,,*.,.,,,.,.,...   @@@@@@@@@@.  //
//  @@@@@@@@@@                . .....@&             ,#,                #. @@**,***@.           *%(                 ,% .@*,,.,..,,,.,,.,...,..... @@@@@@@@@@  //
//  @@@@@@@@@          .   ... .......@@                             .#. @@*/,,,.,&@                              (%  @%***,,.,.,,,,..,,***,,.... @@@@@@@@@  //
//  @@@@@@@@%           .  ...........,@@                           %&  @@*/*,.,,,**@#                          .%/ &@*/**,,,,,.,*,,,,,.,,**,,... #@@@@@@@@  //
//  @@@@@@@@        ..  .. ............,,@@    *                 &&/  @@****,,,,,,,.*@@/    ,                 %&  &@&///*,,,.*,,,,,,,*,,,*,,,,....,@@@@@@@@  //
//  @%(@@@@@.     .  .............,..,.,,,*&@@   &&@@/.   ,#@@&&   @@&/****.,...*,.,,,*/@@.   &@&@(    *%&&&*  (@@//////***,,**,,,,*,****/,*,,*,..,@@@@@%@@  //
//  @@(((@@@%    ... ..........,.,,,,..,,.,,,**@@@&.         .&@@@/*//***,.,,,,*,**,,,,*,*,#@@@*          #@@@&//////**,,,*,,,,,**,,**/*//**,**,,,%@@@%%%@@  //
//  @&((((((@@&   ........,.,...,,,,.,,,,,,,*,,,**/***((((///(////****,,*,,*,*,*,,,,*.,*,,,,***//*(/##(/**(//////*,*,,**,,,**,*********//****/,,%@@%%%&&%@@  //
//  @@#####((((#@@@*....,..,,.,,,,,,,,.*,,**,,,**,**,**,********,****,,,,,**,**,,*,*,**,,,**,**/*,*,**,**/,*********/*********///*//*//*/**/@@@&%%%@%&&&@@@  //
//  @@#########(((((#@@@&,,,*.,,,,,,,,,,.,**,,,*,**,,,**,*****,,***,,******,************,*,*************/,**,***//**/**//*/****//**/*/&@@@%%#%&%%&&@@@&@@@@  //
//  @@#######%#######(((((@@@@/,*,,,,,*,*,,*,,,*,****,*****,,**/*******,*********,*,*/********//*****/*****/*/*//*/////*//*/////(@@@@&&&%%%%%@&@@@&@@@@@@@@  //
//  ,@###%##%#%#&%##%%%&###((((%@@@@*/,************///*/**/***//*//*/**/*//*,//*/*,****/***/*///*///*///*////*//*/////////(@@@@@%%%%&%%&&&&@@@@@@@@@@@@@@@,  //
//   @@##%######%#%%#%#%&%%%%%%##((((%@@@&***//*////*/*/*//*/*/*//*/////*///*/*////////////////*/////////////////////@@@@&%%&%%%&&@&@@@@@@@@@@@@@@@@@@@@@@   //
//    @@########%%&#%%%%&&&%%%&&%&%%%##((((@@@@@*//////*/////////*////*////(////////////((/////////(/((((//////&@@@@&%&&@@&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//     @@#####%%%%#%%%%%%%&&%&&&@&&@&&&&@%%%##(##&@@@&////////////////////////////(///(//////((///////((/&@@@@&%#&%&%&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@     //
//      @@(#%###%#%%%%&%&%&%&&%&&@&&@@@&@@&@@@&@&%&&%%%&@@@@#///((///(////((/((/((///(/(//((///*(/#@@@@@%%&%%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      //
//       #@&%#%###%%%%%%%%@%&&&@&@@@@@&@@@@@@@@@@@@@@@&@&&@&@&@@@@%(/((((((((((((((////(((((#@@@@%&%&&%%&&@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%       //
//         @@%%##%#%#%&%&%@%&@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&@&&@@@@@(((((((((/(((@@@@@&%%%&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         //
//           @@&#%&%%%%&&&%&@&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&@%%&&&@@@@@@@@@&%%%&&@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@           //
//             %@@%%%%#&@%%&@@&&&@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&%%%%%&&&&@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%             //
//                @@@@@&&@&&%%&&&&@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                //
//                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                    //
//                        #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#                        //
//                                @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@                                //
//                                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

import "./IERC721CreatorCore.sol";
import "./ICreatorExtensionTokenURI.sol";
import "./ERC721BurnRedeemSet.sol";

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC165.sol";

/**
 * Summer Breeze
 */
contract SummerBreeze is Ownable, ERC721BurnRedeemSet, ICreatorExtensionTokenURI {

    using Strings for uint256;

    string constant private _EDITION_TAG = '<EDITION>';
    string[] private _uriParts;
    bool private _active;

    constructor(address creator, RedemptionItem[] memory redemptionSet) ERC721BurnRedeemSet(creator, redemptionSet, 100) {
        _uriParts.push('data:application/json;utf8,{"name":"Summer Breeze #');
        _uriParts.push('<EDITION>');
        _uriParts.push('/100", "created_by":"RHYMEZLIKEDIMEZ", ');
        _uriParts.push('"description":"This past year, I\'ve been creating more than ever, focussing on the expansion of the Rhymez universe. \\"Summer Breeze\\" is the first ever of a series I\'m working on with Puff as the main character. This art piece is very special to me, as it\'s the first of many.", ');
        _uriParts.push('"image":"https://arweave.net/CufU-P9bL0F3v21yaiU3oZAnJBFi92rCuBxhKQ0ROQI","image_url":"https://arweave.net/CufU-P9bL0F3v21yaiU3oZAnJBFi92rCuBxhKQ0ROQI","image_details":{"sha256":"944b187a3eb86bc1f451d42fc4b1e14ffe1b4ffe16543c0b9d4c1b486991b902","bytes":549121,"width":1080,"height":1739,"format":"JPEG"},');
        _uriParts.push('"animation":"https://arweave.net/8m1-Ga3DRn7fkxHZ23ANATKL6dEXP0k40o9OaYPffuI","animation_url":"https://arweave.net/8m1-Ga3DRn7fkxHZ23ANATKL6dEXP0k40o9OaYPffuI","animation_details":{"sha256":"4bde85c794b620d8eaebe419b67d0ec06694db0d97a03e6b551316ca1f4c6126","bytes":36312053,"width":1080,"height":1700,"duration":25,"format":"MP4","codecs":["H.264","AAC"]},');
        _uriParts.push('"attributes":[{"trait_type":"Artist","value":"RHYMEZLIKEDIMEZ"},{"trait_type":"Collection","value":"Summer Breeze"},{"display_type":"number","trait_type":"Edition","value":');
        _uriParts.push('<EDITION>');
        _uriParts.push(',"max_value":100}]}');

    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721BurnRedeemSet, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Activate the contract and mint the first token
     */
    function activate() public onlyOwner {
        // Mint the first one to the owner
        require(!_active, "Already active");
        _active = true;
    }

    /**
     * @dev update the URI data
     */
    function updateURIParts(string[] memory uriParts) public onlyOwner {
        _uriParts = uriParts;
    }

    /**
     ^ @dev See {RedeemSetBase-_validateCompleteSet}
     */
    function _validateCompleteSet(address[] memory contracts, uint256[] memory tokenIds) internal override view returns (bool) {
        require(_active, "Redemption not active");
        return super._validateCompleteSet(contracts, tokenIds);
    }

    /**
     * @dev Generate uri
     */
    function _generateURI(uint256 tokenId) private view returns(string memory) {
        bytes memory byteString;
        for (uint i = 0; i < _uriParts.length; i++) {
            if (_checkTag(_uriParts[i], _EDITION_TAG)) {
               byteString = abi.encodePacked(byteString, _mintNumbers[tokenId].toString());
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
     * @dev See {ICreatorExtensionTokenURI-tokenURI}.
     */
    function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
        require(creator == _creator && _mintNumbers[tokenId] != 0, "Invalid token");
        return _generateURI(tokenId);
    }
}
