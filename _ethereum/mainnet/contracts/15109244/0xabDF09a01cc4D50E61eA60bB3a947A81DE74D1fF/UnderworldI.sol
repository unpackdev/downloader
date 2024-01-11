// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @creator: Gunnar Magnus & White Lights
/// @title:   Underworld I
/// @author:  manifold.xyz

import "./AdminControl.sol";
import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./ERC721Burnable.sol";

//////////////////////////////////////////////////////////////////
//                                                              //
//                                                              //
//                               ,▄▄▄▄▄,                        //
//                           ,▄▄▓██████████▄                    //
//                        ╓▓█████▀▀╙└   ╙▀███▄                  //
//                      ▄████╙      ▓▄    └███▄                 //
//                   ╓▓████         █▌      ███▄                //
//                 ▄█████▀        ╓▄██▄      ███⌐               //
//                ███████          ╙█▌╙      ╙███               //
//               ╟███▐██⌐    ,▄▄,        ▄▄▄  ███               //
//               ╟██▌███    ██████     █████  ╟██▌              //
//               ╟██▌██▌    ╙▀███▀     ╙██▀   ▐██▌              //
//               ╟██▒██▌,                    ▄████              //
//          ▄█▌  ╫██░████████▓██Q▄███▓██▄█████████              //
//          ╟██⌐ ▓██j██╩██████j███ ╫██ ▓██⌐▄██▀███   ,          //
//           ██▌ ███▐██⌐ █████▓███▄███▓███████ ███ ████         //
//           ╙██████╟██   ╙██╫██▀██████▄███▄██ ╟█████           //
//  .▓▓▄,  ▓█▓██████▓██    ▓████████████▀████▀ ╟████⌐ ,▄█▌      //
//  `▀████Q╙███████████     └▀▀'╙╙╙▀▀╙▀   ╙└   ╫████▄████▀      //
//      ▀███▄██████████                ,,╓▄▄▄▄████████▀         //
//      ╙█████████████████████████████████████████████████╓,    //
//         ╙▓██████▀▀▀█▀▀▀▀▀▀▀▀▀▀▀╙╙╙╙╙└└      ╫█████████████   //
//     ▓████████████                               ███▀▀▀╙'     //
//                                                              //
//                                                              //
//                ╦ ╦╔╗╔╔╦╗╔═╗╦═╗╦ ╦╔═╗╦═╗╦  ╔╦╗  ╦             //
//                ║ ║║║║ ║║║╣ ╠╦╝║║║║ ║╠╦╝║   ║║  ║             //
//                ╚═╝╝╚╝═╩╝╚═╝╩╚═╚╩╝╚═╝╩╚═╩═╝═╩╝  ╩             //
//                                                              //
//                                                              //
//////////////////////////////////////////////////////////////////


contract UnderworldI is ReentrancyGuard, AdminControl, ERC721, ERC721Burnable {
  uint256 private _royaltyBps;
  address payable private _royaltyRecipient;
  bytes4 private constant _INTERFACE_ID_ROYALTIES_CREATORCORE = 0xbb3bafd6;
  bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;
  bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;
  string[] private assetURIs = new string[](3);
  bool private locked;

  bool private initialized;

  constructor() ERC721("Underworld I", "Underworld I") {}

  function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, ERC721) returns (bool) {
    return interfaceId == type(IERC721).interfaceId ||
      AdminControl.supportsInterface(interfaceId) ||
      ERC721.supportsInterface(interfaceId) ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      interfaceId == _INTERFACE_ID_ROYALTIES_CREATORCORE ||
      interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981 ||
      interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE;
  }

  /*
   * Can only be called once.
   * Creates the three, and only three, tokens this contract controls.
   */
  function initialize() public adminRequired {
    require(!initialized, "Initialized");

    // forge three completely separate tokens that this contract can handle
    _safeMint(msg.sender, 1);
    _safeMint(msg.sender, 2);
    _safeMint(msg.sender, 3);

    // flipped after minting to avoid triggering triptych behavior too early
    initialized = true;
  }

  /*
   * Sets the URIs for the triptych
   */
  function setAssetURIs(string memory uri1, string memory uri2, string memory uri3) public adminRequired {
    assetURIs[0] = uri1;
    assetURIs[1] = uri2;
    assetURIs[2] = uri3;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(tokenId >= 1 && tokenId <= 3, "Invalid token");
    return assetURIs[tokenId - 1];
  }

  /*
   * This forces all 3 tokens this contract controls to always transfer together.
   * Requires two locks. One allowing us to mint all 3 tokens before the triptych
   * behavior engages. The other avoids recursion while we attempt to transfer
   * the two other tokens inside of this pretransfer hook.
   */
  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
    // avoids attempting to transfer tokens before they've been minted
    // note: calling _exists() cost more gas than this approach
    if (!initialized) {
      return;
    }

    // avoids recursively calling transferFrom below infinitely
    if(locked) {
      return;
    }

    // so that the next two transferFrom calls don't cause recursion
    locked = true;

    // @dev: we do not use safeTransferFrom to allow for custodial marketplace contract usage
    if (tokenId == 1) {
      transferFrom(from, to, 2);
      transferFrom(from, to, 3);
    } else if (tokenId == 2) {
      transferFrom(from, to, 1);
      transferFrom(from, to, 3);
    } else if (tokenId == 3) {
      transferFrom(from, to, 1);
      transferFrom(from, to, 2);
    }

    // re-engage triptych behavior now that we've avoided recursion
    locked = false;
  }

  function _isApprovedOrOwner(address spender, uint256 tokenId) internal view override returns (bool) {
    require(_exists(tokenId), "ERC721: operator query for nonexistent token");
    address owner = ERC721.ownerOf(tokenId);
    return (
      msg.sender == address(this) || // this is key
      spender == owner ||
      getApproved(tokenId) == spender ||
      isApprovedForAll(owner, spender)
    );
  }

  /*
   * ROYALTIES
   */

  function updateRoyalties(address payable recipient, uint256 bps) external adminRequired {
    _royaltyRecipient = recipient;
    _royaltyBps = bps;
  }

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
    return (_royaltyRecipient, value * _royaltyBps / 10000);
  }
}
