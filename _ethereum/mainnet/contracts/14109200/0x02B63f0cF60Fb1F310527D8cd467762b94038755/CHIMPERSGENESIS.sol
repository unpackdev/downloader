// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @artist: Timpers
/// @title: Chimpers Genesis Extension
/// @author: manifold.xyz

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                                                                            //
//                                                  ▓▓                        //
//                                            ▓▓  ▓▓╬╬▓▓                      //
//                                          ██╬╬██╬╬▓▓██                      //
//                                      ████╬╬▓▓╬╬▓▓▓▓╬╬████                  //
//                        ██████████  ██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██                //
//                      ██▓▓▓▓▓▓▓▓▓▓██▓▓▓▓▓▓▓▓░░░░░░▓▓▓▓▓▓░░▓▓██████,         //
//                  ,,██▓▓╝╝░░░░░░╝╝▓▓▓▓▓▓╝╝░░======░░╝╝░░====▀▀▓▓▓▓██,,      //
//                  ██▓▓▀▀░░░░░░░░░░▀▀▓▓▓▓░░ⁿⁿ  ▄▄▄▄ⁿⁿ░░ⁿⁿ  ▄▄▄▄▀▀▀▀▓▓██▄▄    //
//                  ██▓▓░░░░░░░░░░░░░░▓▓▓▓░░    ██▀▀  ░░    ██▀▀  ░░▀▀▓▓██    //
//                  ██▓▓░░░░░░░░░░░░░░▓▓▓▓░░    ██▄▄  ░░    ██▄▄  ░░░░▓▓██    //
//                  ██▓▓▓▓░░░░░░░░░░▓▓▓▓▓▓░░≥≥  ╙╙╙╙≥≥░░≥≥  ╙╙╙╙▓▓░░░░▓▓██    //
//                  └└██▓▓▓▓░░░░░░▓▓▓▓▓▓▓▓░░░░φφφφφφ░░░░░░φφφφφφ██░░▓▓▓▓██    //
//                    ──██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░████░░▓███░░░░██▓▓▓▓██¬─    //
//            ████        ████████▓▓▓▓▓▓░│░░░░░░░░││││░░││││░░░░││████        //
//          ██▓▓▓▓██            ██▓▓▓▓▓▓░░                      ░░██          //
//        ██▓▓▓▓╬╬██              ██▓▓▓▓░░                      ░░██          //
//        ██▓▓▓▓██                ██▓▓▓▓░░                      ░░██          //
//        ██▓▓▓▓██        ▄▄▄▄▄▄▄▄██▓▓▓▓▄▄░░,,,,,,,,,,,,,,,,,,░░▄▄▀▀          //
//        ██▓▓▓▓██    ▄▄▄▄██████████▓▓▓▓▓▓▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▀▀            //
//        ██▓▓▓▓██▄▄▄▄████▓▓▓▓▓▓▓▓██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████▀▀▀▀▀▀              //
//        ████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██▓▓                  //
//      ▓▓██████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░╠╠╠╠╠╠╠▓▓▓▓▓▓▓▓▓▓▓▓▓▓██▓▓                //
//    ██▓╬╬╬▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░╚╚╚░░░░░░░░╚╚╚╚╚╚╚╚╚╚▓▓██▓▓╬╬██              //
//    ╬╬▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░▓▓██▓▓▓▓██              //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓██▓▓▓▓██              //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░░░░░░░░░░░░░░░░░▓▓▓▓██▓▓▓▓▓▓██            //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓██▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓▓▓██▓▓▓▓▓▓██            //
//    ▓▓▓▓▓▓▓▓▓▓████▓▓▓▓▒░░░░░░░░░░░░░░░░░░░░░░░░░▄▄▓▓██▓▓▓▓▓▓▓▓██            //
//    ▓▓▓▓▓▓▓▓████▓▓▓▓▀▀░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓▓▓██▓▓▓▓▓▓▓▓██▄▄          //
//    ▓▓▓▓▓▓████▓▓▓▓▀▀░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓▓▓████▓▓▓▓▓▓▓▓▓▓██          //
//                                                                            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


import "./AdminControl.sol";
import "./ICreatorExtensionTokenURI.sol";
import "./ERC721BurnRedeem.sol";
import "./Strings.sol";
import "./ERC165.sol";

contract CHIMPERSGENESIS is AdminControl, ERC721BurnRedeem, ICreatorExtensionTokenURI  {
    using Strings for uint256;

    bool private _active;
    string public API_BASE_URL = '';
    uint16 constant MAX = 100;
    uint16 public tokenCount = 0;

    // for collectibles support
    event Unveil(uint256 collectibleId, address tokenAddress, uint256 tokenId);

    constructor(address creator) ERC721BurnRedeem(creator, 1, MAX) {}

    /**
     * @dev Flip activation of the contract
     */
    function activate() public adminRequired {
        _active = !_active;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721BurnRedeem, AdminControl, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId
          || AdminControl.supportsInterface(interfaceId)
          || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Sets the API_BASE_URI used to concatenate tokenURIs
     */
    function setBaseURI(string memory baseURI) public adminRequired {
        API_BASE_URL = baseURI;
    }

    /**
     * @dev See {IRedeemBase-redeemable}.
     */
    function redeemable(address contract_, uint256 tokenId) public view virtual override returns(bool) {
        require(_active, "Inactive");
        return super.redeemable(contract_, tokenId);
    }

    /**
     * @dev override if you want to perform different mint functionality
     */
    function _mint(address to, uint16) internal virtual override returns (uint256) {
        uint256 tokenId = IERC721CreatorCore(_creator).mintExtension(to);
        tokenCount++;
        emit Unveil(tokenCount, _creator, tokenId);
        return tokenId;
    }

    /**
     * @dev See {ICreatorExtensionTokenURI-tokenURI}.
     */
    function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
        require(creator == _creator && _mintNumbers[tokenId] != 0, "Invalid token");
        return string(abi.encodePacked((API_BASE_URL), tokenId.toString()));
    }
}
