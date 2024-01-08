// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @artist: Drue Kataoka
/// @author: manifold.xyz

import "./AdminControl.sol";
import "./ERC721.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                      //
//                                                                                                                                      //
//                                                                                         ..                                           //
//                                                                                       ,l;                                            //
//                                                                                     'lc.                                             //
//                         .'''....                                                  .cl.                                               //
//                         ......,oo;;,.                                            ;o,                                                 //
//                              .od' .;cc,                                        .lc.                                                  //
//                            .cxc.     .lo.                                     ;o,          ..                        .               //
//                          .cxl.         lx.                                  .lc.   ..      .c.                     ,c'               //
//                         ;xo.           .kl                                 ;l,   ';,.      .:.                   .c;.                //
//                       .od,             .kl    .                          .lc.   .'.       .'lc.                 ;c.                  //
//                      :x:              .ok.  .oc,:.  ''...   '::.        :d,         ....   .c:.               .c:                    //
//                     ,c.              ,dd.  'o:...  .d:cl   :d;,.     .col.   ..     .:;,.   :,  .,'.  .;c.   .c;..    .'..           //
//                                   .cxx;    '.       '',:.  'cc,     ;do,     .,;.     .'    ;,  .;;'  .oc,. .l;'l:.   .;;,.          //
//                    .....'',,;:cloddl,                             .lo.         .,;'         ,,  .';'.  ....'l, .,,''   .;,,,''...    //
//            .';:ccccclllllllllc:;'.                               ;d;             .,;'       ,;            .;.      .      ....''.    //
//       .','',,,...                                              'oo.                 ';,.    ..                                       //
//    .',,..                                                    .cx;                     .,,'                                           //
//    .                                                        ;xl.                        .',,.                                        //
//                                                           ,do,                             .','.                                     //
//                                                         ,dd,                                  .'....                                 //
//                                                       ,oo,                                        ...                                //
//                                                    .;oo,                                                                             //
//                                                  .,c:.                                                                               //
//                                                  ..                                                                                  //
//                                                                                                                                      //
//                                                     ..     ...              ..             ..       ..                               //
//                                                   .ll;'   'oo;.  :,  ,d:  .cl;:;.  ':.  .::;;::.   cl:'                              //
//                                                   .;c:'    :l    l:  :0l. .o;  ll  ,o. .oc    ll   ,c:,                              //
//                                                   .,'lx'   :l    cl..l0c  .dl.,o;  ,o.  :o,..,o;  .,,:x;                             //
//                                                    ,::,    .'    .,;;,'.   ,:;;.   .'    .;;;;.    '::,.                             //
//                                                                                                                                      //
//                                                                                                                                      //
//                                                                                                                                      //
//                                                                                                                                      //
//                                                               ..................''..                                                 //
//                                                              .'.       ..'...,,'''...                                                //
//                                                              .'        .'...'......''.                                               //
//                                                              ..         ..'.....'...'.                                               //
//                                                              ..         .''. ....''...                                               //
//                                                              ..        ............''.                                               //
//                                                              .'...     .... ..........                                               //
//                                                              .',,,'...''... ........,.                                               //
//                                                              .'',.......... ..........                                               //
//                                                              .',,'.... . .. .  ...  ..                                               //
//                                                               '',...     ..      .....                                               //
//                                                               .......         .......                                                //
//                                                                                                                                      //
//                                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract Heart is ERC721, AdminControl {

    string private _uri;

    uint256 private _royaltyBps;
    address payable private _royaltyRecipient;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_CREATORCORE = 0xbb3bafd6;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;

    constructor() ERC721("Will Your Heart Pass the Test?", "HEART") {
        _mint(msg.sender, 1);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, ERC721) returns (bool) {
        return ERC721.supportsInterface(interfaceId) || AdminControl.supportsInterface(interfaceId) 
            || interfaceId == _INTERFACE_ID_ROYALTIES_CREATORCORE || interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981 
            || interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE;
    }

    /**
     * @dev Update uri.
     */
    function setURI(string calldata uri) external adminRequired {
        _uri = uri;
    }

    function tokenURI(uint256 tokenId) public view override returns(string memory) {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");
        return _uri;
    }

    /**
     * @dev See {ILostPoets-updateRoyalties}.
     */
    function updateRoyalties(address payable recipient, uint256 bps) external adminRequired {
        _royaltyRecipient = recipient;
        _royaltyBps = bps;
    }

    /**
     * ROYALTY FUNCTIONS
     */
    function getRoyalties(uint256) external view returns (address payable[] memory recipients, uint256[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return (recipients, bps);
    }

    function getFeeRecipients(uint256) external view returns (address payable[] memory recipients) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
        }
        return recipients;
    }

    function getFeeBps(uint256) external view returns (uint[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return bps;
    }

    function royaltyInfo(uint256, uint256 value) external view returns (address, uint256) {
        return (_royaltyRecipient, value*_royaltyBps/10000);
    }

}