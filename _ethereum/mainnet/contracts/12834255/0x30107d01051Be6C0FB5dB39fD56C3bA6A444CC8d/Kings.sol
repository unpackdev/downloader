// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @artist: Sacramento Kings
/// @author: manifold.xyz

import "./AdminControl.sol";
import "./IERC721CreatorCore.sol";
import "./ICreatorExtensionTokenURI.sol";
import "./IFontWOFF.sol";

import "./IERC721.sol";
import "./Strings.sol";
import "./ERC165.sol";

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
//                           ╦                                             //
//                         ╔╬╬                                             //
//                        ╔╬╣  ╔╗                   ╔╗  ╦╦╦    ╔╬╬╗        //
//                ╔╦╬   ╔╬╬╬╬  ╬╬         ╔╬╬╗   ╔╬╬╬╬╬╬╬╣   ╔╬╬╬╬╬        //
//            ╔╦╬╬╬╬╝  ╔╬╬╬╬╝       ╔╦╬╦╬╬╬╬╬╣  ╔╬╬╩  ╬╬╬╝ ╦╬╬╩ ╠╬╬╣       //
//           ╠╬╬╬╬╬╬  ╬╬╬╬╩   ╔╦╬   ╬╬╬╬╝ ╠╬╬  ╔╬╬╣  ╬╬╬╣╔╬╬╩   ╠╬╬╣       //
//           ╚╩╩╬╬╬╬╦╬╬╬╩     ╠╬╬  ╠╬╬╝   ╬╬╣ ╔╬╬╬╬╦╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬    //
//              ╬╬╬╬╬╬╝      ╠╬╬╝  ╬╬╣   ╠╬╬╬╬╩╩╬╬╬╩╬╬╬╬╩   ╚╩╩╩╩╩  ╬╬╬╬   //
//              ╬╬╬╬╬╣       ╠╬╬   ╬╬╣   ╚╬╩╩      ╬╬╬╬╗      ╔╦╦╦╬╬╬╝╙    //
//             ╬╬╬╣╬╬╬╬╦    ╔╦╬╬╦╦╦╬╬╝      ╔╦╦╬╬╬╬╬╬╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩       //
//             ╠╬╬╝ ╬╬╬╬╬╦╦╬╬╩╬╬╬╩╩╩   ╔╦╬╬╩╩╬╬╬╬╝╠╬╬⌐                     //
//             ╬╬╬   ╙╬╬╬╬╬╬╝     ╔╦╦╬╬╬╩╝ ╔╬╬╬╩╝╔╬╬╝                      //
//            ╬╬╬╣           ╔╦╦╬╬╬╬╩╝    ╔╬╬╬╝ ╔╬╬╩                       //
//      ╬    ╬╬╬╬╝        ╔╦╬╬╬╬╬╬╩      ╔╬╬╬╬╦╦╬╬╩                        //
//      ╬╦╦╦╬╬╬╬╝     ╔╦╬╬╬╬╬╬╬╩╩        ╬╬╬╬╬╬╬╬╝                         //
//      ╚╬╬╬╬╬╬╩    ╔╬╬╬╬╬╬╬╬╩            ╚╩╩╩╝                            //
//       ╚╩╩╩╩╝   ╔╦╬╬╬╬╬╬╬╝                                               //
//             ╔╬╬╬╬╬╬╬╬╬╬╩                                                //
//           ╔╬╬╬╬╬╬╬╬╩╩╩╝                                                 //
//         ╔╬╬╬╬╬╩╩╝                                                       //
//       ╔╬╬╬╩╩                                                            //
//      ╬╬╩╝                                                               //
//    ╩╩╝                                                                  //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////

/**
 * 1985 Inaugural Season Opening Night Pin – Rare Edition
 */
contract Kings is AdminControl, ICreatorExtensionTokenURI {

    using Strings for uint256;

    // The creator mint contract
    address private _creator;

    // URI Tags
    string constant private _BANNER_TAG = '<BANNER>';

    // Banner Tags
    string constant private _FONT_TAG = '<FONT>';
    string constant private _FONT_NAME_ONLY_TAG = '<FONT_NAME_ONLY>';
    string constant private _NAME_FONT_SIZE_TAG = '<SIZENAME>';
    string constant private _KINGS_FONT_SIZE_TAG = '<SIZEKINGS>';
    string constant private _FIRST_NAME_TAG = '<FIRSTNAME>';
    string constant private _LAST_NAME_TAG = '<LASTNAME>';
    string constant private _NUMBER_TAG = '<NUMBER>';
    string constant private _KINGS_TEXT1_TAG = '<KINGSTEXT1>';
    string constant private _KINGS_TEXT2_TAG = '<KINGSTEXT2>';

    uint256 private _changeInterval = 604800;
    
    // Dynamic construction data
    string[] private _uriParts;
    string[] private _bannerParts;

    // Owner updates submitted for approval
    bool private _pending;
    string private _pendingFirstName;
    string private _pendingLastName;
    uint256 private _pendingNumber;
    uint256 private _pendingNameFontSize;
    bool private _pendingRejected;
    string private _pendingRejectedReason;

    // Dynamic variables for banner construction
    string private _firstName;
    string private _lastName;
    uint256 private _number;
    uint256 private _nameFontSize;
    address private _font;
    address private _fontNameOnly;
    string private _kingsText1;
    string private _kingsText2;
    uint256 private _kingsFontSize;
    uint256 private _lastChangeRequest;

    uint256 private _tokenId;

    uint256[] public restrictedNumbers;

    event ChangeOwnerInfo(address sender, string firstName, string lastName, uint256 number, uint256 nameFontSize);
    event ApproveOwnerInfo(address sender, string firstName, string lastName, uint256 number, uint256 nameFontSize);
    event RejectOwnerInfo(address sender, string firstName, string lastName, uint256 number, uint256 nameFontSize, string reason);
    event ChangeOwnerInfoRequest(address sender, string firstName, string lastName, uint256 number, uint256 nameFontSize);

    constructor() {
        _bannerParts = [
          "<svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' width='1170' height='1450' viewBox='0 0 1170 1450'>",
            "<defs>",
              "<style type='text/css'>",
                "@font-face {font-family: 'Kings';src: url(","<FONT>",") format('woff');}",
                "@font-face {font-family: 'KingsName';src: url(","<FONT_NAME_ONLY>",") format('woff');}",
              "</style>",
              "<linearGradient id='lg1' x1='0' x2='100%'><stop offset='0' style='stop-color:#D5D5D5'/><stop offset='33%' style='stop-color:white'/><stop offset='66%' style='stop-color:white'/><stop offset='100%' style='stop-color:#D5D5D5'/></linearGradient><linearGradient id='lg2' x1='0' y1='100%' x2='0' y2='0'><stop offset='0' style='stop-color:#13171B'/><stop offset='0.0547' style='stop-color:#0E1114'/><stop offset='0.2045' style='stop-color:#060709'/><stop offset='0.4149' style='stop-color:#010202'/><stop offset='1' style='stop-color:black'/></linearGradient>",
              "<linearGradient id='flg1' gradientUnits='userSpaceOnUse'><stop offset='0.0956' style='stop-color:#EFB927'/><stop offset='0.1014' style='stop-color:#C99C25'/><stop offset='0.1079' style='stop-color:#A68224'/><stop offset='0.1151' style='stop-color:#896C22'/><stop offset='0.123' style='stop-color:#715921'/><stop offset='0.1318' style='stop-color:#5E4B20'/><stop offset='0.1423' style='stop-color:#51411F'/><stop offset='0.1558' style='stop-color:#493C1F'/><stop offset='0.1834' style='stop-color:#473A1F'/><stop offset='0.2657' style='stop-color:#D2C7B2'/><stop offset='0.3686' style='stop-color:#F6DF8C'/><stop offset='0.6245' style='stop-color:#3C2F0D'/><stop offset='0.8151' style='stop-color:#BF9C1C'/></linearGradient><linearGradient id='flg2' gradientUnits='userSpaceOnUse'><stop offset='0' style='stop-color:white'/><stop offset='0.3729' style='stop-color:#FDFDFD;stop-opacity:0.6274'/><stop offset='0.5071' style='stop-color:#F6F6F6;stop-opacity:0.4931'/><stop offset='0.6027' style='stop-color:#EBEBEB;stop-opacity:0.3974'/><stop offset='0.6801' style='stop-color:#DADADA;stop-opacity:0.32'/><stop offset='0.7464' style='stop-color:#C4C4C4;stop-opacity:0.2537'/><stop offset='0.8051' style='stop-color:#A8A8A8;stop-opacity:0.195'/><stop offset='0.8582' style='stop-color:#888888;stop-opacity:0.1419'/><stop offset='0.9069' style='stop-color:#626262;stop-opacity:0.0931'/><stop offset='0.9523' style='stop-color:#373737;stop-opacity:0.0477'/><stop offset='1' style='stop-color:black;stop-opacity:0'/></linearGradient><linearGradient id='tfg1' href='#flg1' x1='0' y1='98' x2='0' y2='76'/><linearGradient id='bfg1' href='#flg1' x1='0' y1='1166' x2='0' y2='1190'/><linearGradient id='lfg1' href='#flg1' x1='98' y1='0' x2='122' y2='0'/><linearGradient id='rfg1' href='#flg1' x1='1044' y1='0' x2='1068' y2='0'/><linearGradient id='tfg2a' href='#flg2' x1='123' y1='89' x2='1041' y2='89'/><linearGradient id='tfg2b' href='#flg2' x1='128' y1='0' x2='592' y2='0'/><linearGradient id='bfg2a' href='#flg2' x1='123' y1='0' x2='1047' y2='0'/><linearGradient id='bfg2b' href='#flg2' x1='495' y1='0' x2='1036' y2='0'/><linearGradient id='sfg2' href='#flg2'  x1='0' y1='960' x2='0' y2='96'/>",
              "<g id='bolt'><path fill='#141414' d='M3.8,0h-6.27l-3.58,4.06l2.7,4.07h6.29l3.57-4.07L3.8,0z M0,6.18c-1.56,0-2.73-0.95-2.6-2.11c0.13-1.17,1.49-2.11,3.05-2.11c1.56,0,2.72,0.95,2.6,2.11C2.93,5.23,1.56,6.18,0,6.18z'/><path d='M0.46,1.95c-1.56,0-2.93,0.95-3.05,2.11c-0.13,1.17,1.04,2.11,2.6,2.11s2.93-0.95,3.05-2.11C3.18,2.89,2.02,1.95,0.45,1.95z'/></g>",
              "<g id='logo'><rect width='86' height='51' fill='black'/><path d='M56.47,23.69H53.64l6-5.06-4.39-4.71-6.64,5.54-5.49-5.54L33.42,23.7H30.75l5.49-5.59-4.15-4.19-6.15,6-9.59-5,5.23,18.31a90.79,90.79,0,0,1,21.33-3,81.66,81.66,0,0,1,20.68,3l5.4-19Z' fill='#fff'/><path d='M63.14,34.72A79.33,79.33,0,0,0,43,31.87,86.17,86.17,0,0,0,22,34.7l.75,2.76A85.28,85.28,0,0,1,43,34.83,81.47,81.47,0,0,1,62.4,37.38Z' fill='#fff'/><path d='M86,50.81H0V0H86Zm-84-2H84V2H2Z' fill='#fff'/></g>",
              "<linearGradient id='seatlg' x1='0' y1='60.43' x2='0' y2='1.25' gradientTransform='matrix(1, 0, 0, -1, 0, 60.43)' gradientUnits='userSpaceOnUse'><stop offset='0' stop-color='#414142' stop-opacity='0.8'/><stop offset='0.09' stop-color='#323233' stop-opacity='0.73'/><stop offset='0.27' stop-color='#1c1c1c' stop-opacity='0.58'/><stop offset='0.47' stop-color='#0d0e0e' stop-opacity='0.42'/><stop offset='0.7' stop-color='#040404' stop-opacity='0.24'/><stop offset='1' stop-color='#010101' stop-opacity='0'/></linearGradient><path id='seat' d='M34.86,59.18H7.6A7.6,7.6,0,0,1,0,51.58V7.6A7.6,7.6,0,0,1,7.6,0H34.86a7.6,7.6,0,0,1,7.6,7.6v44A7.61,7.61,0,0,1,34.86,59.18Z' fill='url(#seatlg)'/><pattern id='seatp1' x='0' y='0' width='50' height='35' patternUnits='userSpaceOnUse'><use href='#seat'/></pattern><pattern id='seatp2' x='25' y='0' width='50' height='35' patternUnits='userSpaceOnUse'><use href='#seat'/></pattern>",
              "<linearGradient id='raftlg' gradientUnits='userSpaceOnUse'><stop offset='0' style='stop-color:white'/><stop offset='1' style='stop-color:black'/></linearGradient><linearGradient id='raft1' href='#raftlg' x1='0' y1='144' x2='0' y2='102'/><linearGradient id='raft2' href='#raftlg' x1='0' y1='200' x2='0' y2='159'/>",
              "<linearGradient id='burn1' x1='-25%' y1='0' x2='125%' y2='0'><stop offset='-1' style='stop-color:#F1A958'><animate attributeName='offset' values='-1;-0.75;-0.5;-0.25;0' dur='3s' repeatCount='indefinite'/></stop><stop offset='-0.75' style='stop-color:#F9F9A3'><animate attributeName='offset' values='-0.75;-0.5;-0.25;0;0.25' dur='3s' repeatCount='indefinite'/></stop><stop offset='-0.25' style='stop-color:#F9F9A3'><animate attributeName='offset' values='-0.25;0;0.25;0.5;0.75' dur='3s' repeatCount='indefinite'/></stop><stop offset='0' style='stop-color:#F1A958'><animate attributeName='offset' values='0;0.25;0.5;0.75;1' dur='3s' repeatCount='indefinite'/></stop><stop offset='0.25' style='stop-color:#F9F9A3'><animate attributeName='offset' values='0.25;0.5;0.75;1;1.25' dur='3s' repeatCount='indefinite'/></stop><stop offset='0.75' style='stop-color:#F9F9A3'><animate attributeName='offset' values='0.75;1;1.25;1.5;1.75' dur='3s' repeatCount='indefinite'/></stop><stop offset='1' style='stop-color:#F1A958'><animate attributeName='offset' values='1;1.25;1.5;.75;2' dur='3s' repeatCount='indefinite'/></stop></linearGradient><linearGradient id='burn2' x1='-25%' y1='0' x2='125%' y2='0'><stop offset='0' style='stop-color:#F9F9A3'><animate attributeName='offset' values='-1;-1;0;' dur='3s' repeatCount='indefinite'/></stop><stop offset='0' style='stop-color:#F1A958'><animate attributeName='offset' values='-1;0;1' dur='3s' repeatCount='indefinite'/></stop><stop offset='0' style='stop-color:#F9F9A3'><animate attributeName='offset' values='0;1;1;' dur='3s' repeatCount='indefinite'/></stop></linearGradient>",
            "</defs>",
            "<rect width='1170' height='1450'/>",
            "<rect x='98' y='76' width='968' height='22' fill='url(#tfg1)'/><polygon points='98,1166 1067,1166 1067,1190 98,1190' fill='url(#bfg1)'/><polygon points='98,1190 98,76 122,76 122,1190' fill='url(#lfg1)'/><polygon points='1044,1190 1044,76 1068,76 1068,1190' fill='url(#rfg1)'/>",
            "<g opacity='0.8'><polygon points='1041,95 123,89 1041,84' fill='url(#tfg2a)'/><polygon points='592,87 128,82 592,76' fill='url(#tfg2b)'/><polygon points='1047,1177 123,1170 1047,1165' fill='url(#bfg2a)'/><polygon points='1037,1189 496,1183 1037,1178' fill='url(#bfg2b)'/><polygon points='124,96 117,960 112,96' fill='url(#sfg2)'/><polygon points='1055,76 1049,941 1043,76' fill='url(#sfg2)'/></g>",
            "<rect x='122' y='100' width='922' height='1068' fill='url(#lg2)'/>",
            "<g opacity='0.4'><rect x='122.25' y='99.25' width='921.5' height='4' fill='#282828'/><rect x='122.25' y='100' width='921.5' height='42.25' fill='url(#raft1)' opacity='0.1'/><rect x='122.25' y='145' width='921.5' height='5' fill='#282828'/><rect x='122.25' y='150' width='921.5' height='18.75' fill='#3A3A3A'/></g>",
            "<g opacity='0.1'><rect x='122.25' y='159' width='921.5' height='42.25' fill='url(#raft2)' opacity='0.1'/><rect x='122.25' y='200' width='921.5' height='5' fill='#282828'/><rect x='122.25' y='205' width='921.5' height='18.75' fill='#3A3A3A'/></g>",
            "<g opacity='0.4'><use href='#bolt' x='152.65' y='186.78'/><use href='#bolt' x='385.99' y='186.78'/><use href='#bolt' x='584.34' y='186.78'/><use href='#bolt' x='780.18' y='186.78'/><use href='#bolt' x='1016.02' y='186.78'/></g>",
            "<use href='#bolt' x='152.65' y='109.15'/><use href='#bolt' x='154.95' y='130.71'/><use href='#bolt' x='385.99' y='109.15'/><use href='#bolt' x='384.85' y='130.71'/><use href='#bolt' x='584.34' y='109.15'/><use href='#bolt' x='584.34' y='130.71'/><use href='#bolt' x='780.18' y='109.15'/><use href='#bolt' x='781.32' y='130.71'/><use href='#bolt' x='1016.02' y='109.15'/><use href='#bolt' x='1013.72' y='130.71'/>",
            "<rect x='122' y='875' width='922' height='35' fill='url(#seatp2)' opacity='0.2'/><rect x='122' y='910' width='922' height='35' fill='url(#seatp1)' opacity='0.3'/><rect x='122' y='945' width='922' height='35' fill='url(#seatp2)' opacity='0.4'/><rect x='122' y='980' width='922' height='35' fill='url(#seatp1)' opacity='0.5'/><rect x='122' y='1015' width='922' height='35' fill='url(#seatp2)' opacity='0.6'/><rect x='122' y='1050' width='922' height='35' fill='url(#seatp1)' opacity='0.7'/><rect x='122' y='1085' width='922' height='35' fill='url(#seatp2)' opacity='0.8'/><rect x='122' y='1120' width='922' height='35' fill='url(#seatp1)' opacity='0.9'/>",
            "<rect x='359.5' y='99.25' width='1.13' height='167' fill='#939393'/><rect x='808' y='99.25' width='1.13' height='167' fill='#939393'/><rect width='595' height='805' x='287.5' y='275' stroke='#0678A7' stroke-width='17.5'/><rect width='560' height='770' x='305' y='292.5' stroke='#EE1E3A' stroke-width='17.5' fill='url(#lg1)'/>",
            "<use href='#logo' x='542.5' y='160'/>",
            "<svg width='538.75' height='752.5' x='313.25' y='300.25' font-family='Kings' stroke='#EE1E3A' fill='#0678A7'>",
                "<path id='curve' d='M 0 140 Q 264.25 80.5 528.5 140' stroke-width='0' fill='transparent'/>",
                "<svg x='7' y='0' width='524.75'><text id='first_name' font-size='","<SIZENAME>","px' stroke-width='1.2' letter-spacing='1.8'><textPath xlink:href='#curve' text-anchor='middle' startOffset='50%'>","<FIRSTNAME>","</textPath></text></svg>",
                "<svg x='7' y='87.5' width='524.75'><text id='last_name' font-size='","<SIZENAME>","px' stroke-width='1.2' letter-spacing='1.8'><textPath xlink:href='#curve' text-anchor='middle' startOffset='50%'>","<LASTNAME>","</textPath></text></svg>",
                "<text id='number' x='50%' y='472.5' font-size='280px' text-anchor='middle' stroke-width='5.4'>","<NUMBER>","</text>",
                "<text id='kings_text1' x='50%' y='612.5' font-size='","<SIZEKINGS>","px' text-anchor='middle' stroke-width='1.2' letter-spacing='1.8'>","<KINGSTEXT1>","</text>",
                "<text id='kings_text2' x='50%' y='700' font-size='","<SIZEKINGS>","px' text-anchor='middle' stroke-width='1.2' letter-spacing='1.8'>","<KINGSTEXT2>","</text>",
            "</svg>",
            "<text font-size='17' font-family='KingsName' letter-spacing='4' fill='white' x='125' y='1252.5'>SACRAMENTO KINGS</text><rect x='125' y='1275' width='55' height='5' fill='white'/><g font-family='Kings' letter-spacing='3'><text x='125' y='1330' font-family='Kings' font-size='40px' fill='url(#burn1)'>COMMEMORATIVE NFT BANNER</text></g><text x='885' y='1255' font-family='Kings' font-size='20px' letter-spacing='2.5' fill='url(#burn1)'>RARE EDITION</text><rect x='885' y='1265' width='160' height='110' stroke-width='3' stroke='white'/><svg x='885' y='1265' width='160' height='110'><text x='50%' y='80' font-family='Kings' font-size='70px' letter-spacing='17.5' text-anchor='middle' fill='url(#burn1)'>1 1</text><text x='50%' y='70' font-family='Kings' font-size='40px' text-anchor='middle' fill='url(#burn2)'>/</text></svg>",
            "<filter id='glow' x='-50%' y='-50%' width='200%' height='200%'><feGaussianBlur in='SourceGraphic' stdDeviation='5'/></filter><circle cx='885' cy='1265' r='7' fill='white' filter='url(#glow)'><animate attributeName='cx' values='885;1045;1045' dur='6s' repeatCount='indefinite'/><animate attributeName='cy' values='1265;1265;1375' dur='6s' repeatCount='indefinite'/></circle><circle cx='885' cy='1265' r='2' fill='white'><animate attributeName='cx' values='885;1045;1045' dur='6s' repeatCount='indefinite'/><animate attributeName='cy' values='1265;1265;1375' dur='6s' repeatCount='indefinite'/></circle><circle cx='1045' cy='1375' r='7' fill='white' filter='url(#glow)'><animate attributeName='cx' values='1045;885;885' dur='6s' repeatCount='indefinite'/><animate attributeName='cy' values='1375;1375;1265' dur='6s' repeatCount='indefinite'/></circle><circle cx='1045' cy='1375' r='2' fill='white'><animate attributeName='cx' values='1045;885;885' dur='6s' repeatCount='indefinite'/><animate attributeName='cy' values='1375;1375;1265' dur='6s' repeatCount='indefinite'/></circle>",
          "</svg>"];

    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Activate the contract and mint the token
     */
    function activate(address creator_) public adminRequired {
        // Mint the first one to the owner
        require(_tokenId == 0, "Already active");
        _creator = creator_;

        _uriParts = ['data:application/json;utf8,{"name":"1985 Inaugural Season Opening Night Pin - Rare Edition","created_by":"Sacramento Kings","description":"Be part of Kings history with the franchise\'s first-ever NFTs commemorating the inaugural season in Sacramento. This is the rarest NFT in the 1985 Inaugural Pin Collection, allowing the owner to make their mark on Golden 1 Center, the home of the Sacramento Kings.\\n\\nThe owner of this NFT can customize the name and number on the banner, reflected on the NFT itself as well as the Kings website and inside Golden 1 Center.\\n\\nThe original owner of this NFT will also receive a physical replica of the 1985 inaugural season pin as well as a pair of tickets to the 2021-22 Opening Night game, with seats guaranteed in the first three rows.","image":"data:image/svg+xml;utf8,','<BANNER>','","animation":"https://arweave.net/4BZpgaPIVBQQaLLhJU3fx-F3LtvWDEeqd_9lxlUd7ws","animation_url":"https://arweave.net/4BZpgaPIVBQQaLLhJU3fx-F3LtvWDEeqd_9lxlUd7ws","animation_details":{"sha256":"d8613f014931da7fa04ee4c87b3db1b53a83d636c1aea1ac43740b05cbf1cd6a","bytes":18733746,"width":2500,"height":3100,"duration":14,"format":"MP4","codecs":["H.264","AAC"]},"attributes":[{"trait_type":"Team","value":"Sacramento Kings"},{"trait_type":"Collection","value":"Sacramento Kings 1985 Inaugural Pin"},{"trait_type":"Year","value":"2021"}]}'];

        _nameFontSize = 80;
        _kingsFontSize = 80;
        _firstName = "FIRST NAME";
        _lastName = "LAST NAME";
        _number = 1;
        _kingsText1 = "NFT";
        _kingsText2 = "OWNER";

        _tokenId = IERC721CreatorCore(_creator).mintExtension(owner());
    }

    /**
     * @dev Get the creator contract
     */
    function creator() public view returns(address) {
        return _creator;
    }

    /**
     * @dev Get owner info
     */
    function ownerInfo() public view returns(string memory, string memory, uint256, uint256) {
        return (_firstName, _lastName, _number, _nameFontSize);
    }

    /**
     * @dev Get kings text
     */
    function kingsText() public view returns(string memory, string memory, uint256) {
       return (_kingsText1, _kingsText2, _kingsFontSize);
    }

    /**
     * @dev update the URI data
     */
    function updateURIParts(string[] memory uriParts) public adminRequired {
        _uriParts = uriParts;
    }

    /**
     * @dev update the banner data
     */
    function updateBannerParts(string[] memory bannerParts) public adminRequired {
        _bannerParts = bannerParts;
    }

    /**
     * @dev add banner parts data
     */
    function addBannerParts(string[] memory bannerParts) public adminRequired {
        for (uint i = 0; i < bannerParts.length; i++) {
            _bannerParts.push(bannerParts[i]);
        }
    }

    /**
     * @dev update the font
     */
    function updateFont(address font, address fontNameOnly) public adminRequired {
        _font = font;
        _fontNameOnly = fontNameOnly;
    }

    /**
     * @dev update Kings text
     */
    function updateKingsText(string memory text1, string memory text2, uint256 fontSize) public adminRequired {
        _kingsText1 = upper(text1);
        _kingsText2 = upper(text2);
        _kingsFontSize = fontSize;
    }

    /**
     * @dev update Kings restricted numbers
     */
    function updateRestrictedNumbers(uint256[] memory numbers) public adminRequired {
        restrictedNumbers = numbers;
    }

    /**
     * @dev update owner information
     */
    function changeOwnerInfo(string memory firstName, string memory lastName, uint256 number, uint256 nameFontSize) public {
        require(IERC721(_creator).ownerOf(_tokenId) == msg.sender, "Only owner can update info");
        require(!_pending, "You already have a pending request");
        require(block.timestamp > _lastChangeRequest+_changeInterval, "You must wait to request another change");

        for (uint i = 0; i < restrictedNumbers.length; i++) {
            if (number == restrictedNumbers[i]) revert("Restricted number");
        }
        _pendingFirstName = upper(firstName);
        _pendingLastName = upper(lastName);
        _pendingNumber = number;
        _pendingNameFontSize = nameFontSize;
        _pendingRejected = false;
        _pendingRejectedReason = '';
        _lastChangeRequest = block.timestamp;
        _pending = true;

        emit ChangeOwnerInfoRequest(msg.sender, firstName, lastName, number, nameFontSize);
    }

    /**
     * @dev returns amount of time you need to wait until you can make another change request
     */
    function timeToNextChange() public view returns(uint256) {
        if (block.timestamp < _lastChangeRequest+_changeInterval) return _lastChangeRequest+_changeInterval-block.timestamp;
        return 0;
    }

    /**
     * @dev get pending owner info
     */
    function pendingOwnerInfo() public view returns(bool, string memory, string memory, uint256, uint256, bool, string memory) {
        return (_pending, _pendingFirstName, _pendingLastName, _pendingNumber, _pendingNameFontSize, _pendingRejected, _pendingRejectedReason);
    }

    /**
     * @dev approve owner info
     */
    function approveOwnerInfo() public adminRequired {
         require(_pending, "No requests pending");

         _firstName = _pendingFirstName;
         _lastName = _pendingLastName;
         _number = _pendingNumber;
         _nameFontSize = _pendingNameFontSize;

         _pending = false;
         _pendingFirstName = '';
         _pendingLastName = '';
         _pendingNumber = 0;
         _pendingNameFontSize = 0;
         _pendingRejected = false;
         _pendingRejectedReason = '';

         emit ApproveOwnerInfo(msg.sender, _firstName, _lastName, _number, _nameFontSize);
     }

    /**
     * @dev reject owner info
     */
    function rejectOwnerInfo(string memory reason, bool resetChangeTime) public adminRequired {
         _pending = false;
         _pendingRejected = true;
         _pendingRejectedReason = reason;
         if (resetChangeTime) _lastChangeRequest = 0;

         emit RejectOwnerInfo(msg.sender, _firstName, _lastName, _number, _nameFontSize, reason);
     }

    /**
     * @dev override owner info
     */
    function overrideOwnerInfo(string memory firstName, string memory lastName, uint256 number, uint256 nameFontSize) public adminRequired {
         _firstName = upper(firstName);
         _lastName = upper(lastName);
         _number = number;
         _nameFontSize = nameFontSize;
         
         emit ChangeOwnerInfo(msg.sender, firstName, lastName, number, nameFontSize);
     }

    /**
     * @dev Generate uri
     */
    function _generateURI() private view returns(string memory) {
        bytes memory byteString;
        for (uint i = 0; i < _uriParts.length; i++) {
            if (_checkTag(_uriParts[i], _BANNER_TAG)) {
               byteString = abi.encodePacked(byteString, bannerSVG());
            } else {
              byteString = abi.encodePacked(byteString, _uriParts[i]);
            }
        }
        return string(byteString);
    }

    /**
     * @dev get banner SVG
     */
    function bannerSVG() public view returns(string memory) {
        bytes memory byteString;
        for (uint i = 0; i < _bannerParts.length; i++) {
            if (_checkTag(_bannerParts[i], _FONT_TAG)) {
               byteString = abi.encodePacked(byteString, IFontWOFF(_font).woff());
            } else if (_checkTag(_bannerParts[i], _FONT_NAME_ONLY_TAG)) {
               byteString = abi.encodePacked(byteString, IFontWOFF(_fontNameOnly).woff());
            } else if (_checkTag(_bannerParts[i], _NAME_FONT_SIZE_TAG)) {
               byteString = abi.encodePacked(byteString, _nameFontSize.toString());
            } else if (_checkTag(_bannerParts[i], _KINGS_FONT_SIZE_TAG)) {
               byteString = abi.encodePacked(byteString, _kingsFontSize.toString());
            } else if (_checkTag(_bannerParts[i], _FIRST_NAME_TAG)) {
               byteString = abi.encodePacked(byteString, _firstName);
            } else if (_checkTag(_bannerParts[i], _LAST_NAME_TAG)) {
               byteString = abi.encodePacked(byteString, _lastName);
            } else if (_checkTag(_bannerParts[i], _NUMBER_TAG)) {
               byteString = abi.encodePacked(byteString, _number.toString());
            } else if (_checkTag(_bannerParts[i], _KINGS_TEXT1_TAG)) {
               byteString = abi.encodePacked(byteString, _kingsText1);
            } else if (_checkTag(_bannerParts[i], _KINGS_TEXT2_TAG)) {
               byteString = abi.encodePacked(byteString, _kingsText2);
            } else {
              byteString = abi.encodePacked(byteString, _bannerParts[i]);
            }
        }
        return string(byteString);
    }

    function _checkTag(string storage a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    /**
     * @dev See {ICreatorExtensionTokenURI-tokenURI}.
     */
    function tokenURI(address creator_, uint256 tokenId) external view override returns (string memory) {
        require(creator_ == _creator && tokenId == _tokenId, "Invalid token");
        return _generateURI();
    }

    /**
     * Lower
     * 
     * Converts all the values of a string to their corresponding lower case
     * value.
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string base to convert to lower case
     * @return string 
     */    
    function upper(string memory _base)
        internal
        pure
        returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _upper(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    /**
     * Upper
     * 
     * Convert an alphabetic character to upper case and return the original
     * value when not alphabetic
     * 
     * @param _b1 The byte to be converted to upper case
     * @return bytes1 The converted value if the passed value was alphabetic
     *                and in a lower case otherwise returns the original value
     */
    function _upper(bytes1 _b1)
        private
        pure
        returns (bytes1) {

        if (_b1 >= 0x61 && _b1 <= 0x7A) {
            return bytes1(uint8(_b1) - 32);
        }

        return _b1;
    }
}
