// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @artist: Karsen Daily
/// @author: manifold.xyz

import "./AdminControl.sol";
import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./IERC721Receiver.sol";
import "./Address.sol";
import "./Strings.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//    /\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\|‾‾‾\      |      //
//    |___________________________________________________________________________|    \     |      //
//    |                                                                           |     \    |      //
//    |                ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥      |      \   |      //
//    |                                                                           |       \  |      //
//    |                                                                           |_________\       //
//    |      /$$$$$$  /$$$$$$$$       /$$$$$$$$ /$$$$$$ /$$      /$$ /$$$$$$$$  /$$$$$$      |      //
//    |     /$$__  $$|_____ $$/      |__  $$__/|_  $$_/| $$$    /$$$| $$_____/ /$$__  $$     |      //
//    |    |__/  \ $$     /$$/          | $$     | $$  | $$$$  /$$$$| $$      | $$  \__/     |      //
//    |      /$$$$$$/    /$$/           | $$     | $$  | $$ $$/$$ $$| $$$$$   |  $$$$$$      |      //
//    |     /$$____/    /$$/            | $$     | $$  | $$  $$$| $$| $$__/    \____  $$     |      //
//    |    | $$        /$$/             | $$     | $$  | $$\  $ | $$| $$       /$$  \ $$     |      //
//    |    | $$$$$$$$ /$$/              | $$    /$$$$$$| $$ \/  | $$| $$$$$$$$|  $$$$$$/     |      //
//    |    |________/|__/               |__/   |______/|__/     |__/|________/ \______/      |      //
//    |                                                                                      |      //
//    |                                                                                      |      //
//    |                         a heartcoded crypto art experience                           |      //
//    |                                  by karsen daily                                     |      //
//    |                                                                                      |      //
//    |                ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥                 |      //
//    |                                                                                      |      //
//    |                                                                                      |      //
//    |                __                             __  __                                 |      //
//    |               / /_  ___     ____ ____  ____  / /_/ /__                               |      //
//    |              / __ \/ _ \   / __ `/ _ \/ __ \/ __/ / _ \                              |      //
//    |             / /_/ /  __/  / /_/ /  __/ / / / /_/ /  __/                              |      //
//    |            /_.___/\___/   \__, /\___/_/ /_/\__/_/\___/                               |      //
//    |                          /____/                                                      |      //
//    |                                         _ __  __                                     |      //
//    |                               _      __(_) /_/ /_     ____ ___  ___                  |      //
//    |                              | | /| / / / __/ __ \   / __ `__ \/ _ \                 |      //
//    |                              | |/ |/ / / /_/ / / /  / / / / / /  __/                 |      //
//    |                              |__/|__/_/\__/_/ /_/  /_/ /_/ /_/\___/                  |      //
//    |                                                                                      |      //
//    |                                                                                      |      //
//    |                                                                                      |      //
//    |                                                                                      |      //
//    |______________________________________________________________________________________|      //
//    \/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/      //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////
contract TwentySevenTimes is ReentrancyGuard, AdminControl, ERC721 {

    using Address for address;
    using Strings for uint256;

    string private _name;
    string private _symbol;

    uint256 private _royaltyBps;
    address payable private _royaltyRecipient;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_CREATORCORE = 0xbb3bafd6;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;

    uint256 _tokenIndex;
    mapping(uint256 => string) private _tokenURIs;
    uint[] _dates;
    bool _datesLocked;

    constructor() ERC721("27 Times by Karsen Daily", "27TIMES") {
        _name = "27 Times by Karsen Daily";
        _symbol = "27TIMES";
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, ERC721) returns (bool) {
        return interfaceId == type(IERC721).interfaceId || AdminControl.supportsInterface(interfaceId) ||
            ERC721.supportsInterface(interfaceId) || interfaceId == type(IERC721Metadata).interfaceId || interfaceId == _INTERFACE_ID_ROYALTIES_CREATORCORE || 
            interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981 || interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

    function _beforeTokenTransfer(address, address, uint256) internal virtual override {
        uint timeNow = block.timestamp;
        bool transferrable = false;
        for (uint i = 0; i < _dates.length; i++) {
            uint max = _dates[i] + 24 hours;
            uint min = _dates[i];
            if (timeNow < max && timeNow > min) {
                transferrable = true;
            }
        }
        require(transferrable || !_datesLocked, "Cannot transfer today.");
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view override returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (isAdmin(spender) || spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev uint epoch timestamp during that day. Put in midnight of that day
     */
    function setDates(uint[] memory dates) public adminRequired {
        _dates = dates;
    }

    function toggleDatesLocked() public adminRequired {
        _datesLocked = !_datesLocked;
    }

    function updateTokenURIs(uint[] memory _tokenIds, string[] memory _newTokenURIs) public adminRequired {
        for (uint i = 0; i < _tokenIds.length; i++) {
            _tokenURIs[_tokenIds[i]] = _newTokenURIs[i];
        }
    }

    function mint(address to, string[] memory uris) public adminRequired {
        for (uint i = 0; i < uris.length; i++) {
            _tokenIndex++;
            _tokenURIs[_tokenIndex] = uris[i];
            _mint(to, _tokenIndex);
        }
    }

    /**
     * ROYALTY FUNCTIONS
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
        return (_royaltyRecipient, value*_royaltyBps/10000);
    }
}