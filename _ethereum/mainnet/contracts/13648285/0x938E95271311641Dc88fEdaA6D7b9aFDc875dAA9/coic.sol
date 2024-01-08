// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @creator: Pak
/// @author: manifold.xyz

/////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                 //
//                                                                                                 //
//      .g8"""bgd `7MM"""Mq.  `7MM"""YMM        db   MMP""MM""YMM `7MMF' .g8""8q. `7MN.   `7MF'    //
//    .dP'     `M   MM   `MM.   MM    `7       ;MM:  P'   MM   `7   MM .dP'    `YM. MMN.    M      //
//    dM'       `   MM   ,M9    MM   d        ,V^MM.      MM        MM dM'      `MM M YMb   M      //
//    MM            MMmmdM9     MMmmMM       ,M  `MM      MM        MM MM        MM M  `MN. M      //
//    MM.           MM  YM.     MM   Y  ,    AbmmmqMA     MM        MM MM.      ,MP M   `MM.M      //
//    `Mb.     ,'   MM   `Mb.   MM     ,M   A'     VML    MM        MM `Mb.    ,dP' M     YMM      //
//      `"bmmmd'  .JMML. .JMM..JMMmmmmMMM .AMA.   .AMMA..JMML.    .JMML. `"bmmd"' .JML.    YM      //
//                                                                                                 //
//                                                                                                 //
//                                                                                                 //
//                                                                                                 //
//      .g8""8q. `7MM"""Yp, `7MM"""YMM `YMM'   `MM'.M"""bgd                                        //
//    .dP'    `YM. MM    Yb   MM    `7   VMA   ,V ,MI    "Y                                        //
//    dM'      `MM MM    dP   MM   d      VMA ,V  `MMb.                                            //
//    MM        MM MM"""bg.   MMmmMM       VMMP     `YMMNq.                                        //
//    MM.      ,MP MM    `Y   MM   Y  ,     MM    .     `MM                                        //
//    `Mb.    ,dP' MM    ,9   MM     ,M     MM    Mb     dM                                        //
//      `"bmmd"' .JMMmmmd9  .JMMmmmmMMM   .JMML.  P"Ybmmd"                                         //
//                                                                                                 //
//                                                                                                 //
//                                                                                                 //
//                                                                                                 //
//    `7MMF'MMP""MM""YMM  .M"""bgd                                                                 //
//      MM  P'   MM   `7 ,MI    "Y                                                                 //
//      MM       MM      `MMb.                                                                     //
//      MM       MM        `YMMNq.                                                                 //
//      MM       MM      .     `MM                                                                 //
//      MM       MM      Mb     dM                                                                 //
//    .JMML.   .JMML.    P"Ybmmd"                                                                  //
//                                                                                                 //
//                                                                                                 //
//                                                                                                 //
//                                                                                                 //
//      .g8"""bgd `7MM"""Mq.  `7MM"""YMM        db   MMP""MM""YMM   .g8""8q. `7MM"""Mq.            //
//    .dP'     `M   MM   `MM.   MM    `7       ;MM:  P'   MM   `7 .dP'    `YM. MM   `MM.           //
//    dM'       `   MM   ,M9    MM   d        ,V^MM.      MM      dM'      `MM MM   ,M9            //
//    MM            MMmmdM9     MMmmMM       ,M  `MM      MM      MM        MM MMmmdM9             //
//    MM.           MM  YM.     MM   Y  ,    AbmmmqMA     MM      MM.      ,MP MM  YM.             //
//    `Mb.     ,'   MM   `Mb.   MM     ,M   A'     VML    MM      `Mb.    ,dP' MM   `Mb.           //
//      `"bmmmd'  .JMML. .JMM..JMMmmmmMMM .AMA.   .AMMA..JMML.      `"bmmd"' .JMML. .JMM.          //
//                                                                                                 //
//                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////

import "./AdminControl.sol";
import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./IERC721Receiver.sol";
import "./Address.sol";
import "./Strings.sol";

import "./icoic.sol";

contract coic is ReentrancyGuard, AdminControl, ERC721, icoic {

    using Address for address;
    using Strings for uint256;

    uint256 _tokenIndex;
    mapping(uint256 => string) private _tokenURIs;
    string private _commonURI;
    string private _prefixURI;
    string private _name;
    string private _symbol;

    // Transfer locks
    mapping(uint256 => bool) private _transferLocks;    

    uint256 private _royaltyBps;
    address payable private _royaltyRecipient;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_CREATORCORE = 0xbb3bafd6;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;

    constructor() ERC721("Hate", "HATE") {
        _name = "Hate";
        _symbol = "HATE";
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, ERC721) returns (bool) {
        return interfaceId == type(icoic).interfaceId || interfaceId == type(IERC721).interfaceId || AdminControl.supportsInterface(interfaceId) ||
            ERC721.supportsInterface(interfaceId) || interfaceId == type(IERC721Metadata).interfaceId || interfaceId == _INTERFACE_ID_ROYALTIES_CREATORCORE || 
            interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981 || interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            return _tokenURIs[tokenId];
        }
        if (bytes(_commonURI).length != 0) {
            return _commonURI;
        }
        return string(abi.encodePacked(_prefixURI, tokenId.toString()));
    }

    /**
     * @dev See {ERC721-_beforeTokenTranfser}.
     */
    function _beforeTokenTransfer(address, address, uint256 tokenId) internal view override {
        require(isAdmin(msg.sender) || !_transferLocks[tokenId], "ERC721: transfer not permitted");
    }

    /**
     * @dev See {ERC721-_isApprovedOrOwner}.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view override returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (isAdmin(spender) || spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }


    /**
     * @dev See {icoic-mint}.
     */
    function mint(address[] calldata receivers, string[] calldata uris) public override adminRequired nonReentrant {
        require(uris.length == 0 || receivers.length == uris.length, "Invalid input");
        bool setURIs = uris.length > 0;
        for (uint i = 0; i < receivers.length; i++) {
            _tokenIndex++;
            _mint(receivers[i], _tokenIndex);
            _transferLocks[_tokenIndex] = true;
            if (setURIs) {
                _tokenURIs[_tokenIndex] = uris[i];
            }
        }
    }

    /**
     * @dev See {icoic-setTransferLock}.
     */
    function setTransferLock(uint256[] calldata tokenIds, bool lock) public override adminRequired nonReentrant {
        if (tokenIds.length == 0) {
            for (uint i = 1; i <= _tokenIndex; i++) {
                _transferLocks[i] = lock;
            }
        } else {
            for (uint i = 0; i < tokenIds.length; i++) {
                _transferLocks[tokenIds[i]] = lock;
            }
        }
    }

    /**
     * @dev See {icoic-burn}.
     */
    function burn() public override adminRequired nonReentrant adminRequired {
        for (uint i = 1; i <= _tokenIndex; i++) {
            _transfer(ownerOf(i), address(0xdead), i);
        }
    }

    /**
     * @dev See {icoic-move}.
     */
    function move(uint256[] calldata tokenIds, address[] calldata recipients) public override adminRequired nonReentrant {
        require(recipients.length == 1 || recipients.length == tokenIds.length, "Invalid input");

        if (recipients.length > 1) {
            // Multiple recipients
            for (uint i = 0; i < tokenIds.length; i++) {
                address recipient = recipients[i];
                if (ownerOf(tokenIds[i]) != recipient) {
                    _transfer(ownerOf(tokenIds[i]), recipient, tokenIds[i]);
                }
            }
        } else {
            // Single Recipient
            address recipient = recipients[0];
            if (tokenIds.length > 0) {
                for (uint i = 0; i < tokenIds.length; i++) {
                    if (ownerOf(tokenIds[i]) != recipient) {
                        _transfer(ownerOf(tokenIds[i]), recipient, tokenIds[i]);
                    }
                }
            } else {
                for (uint i = 1; i <= _tokenIndex; i++) {
                    if (ownerOf(i) != recipient) {
                        _transfer(ownerOf(i), recipient, i);
                    }
                }
            }
        }
    }

    /**
     * @dev See {icoic-setInfo}.
     */
    function setInfo(string calldata name_, string calldata symbol_) external override adminRequired {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {icoic-setPrefixURI}.
     */
    function setPrefixURI(string calldata uri) external override adminRequired {
        _commonURI = '';
        _prefixURI = uri;
    }

    /**
     * @dev See {icoic-setCommonURI}.
     */
    function setCommonURI(string calldata uri) external override adminRequired {
        _commonURI = uri;
        _prefixURI = '';
    }

    /**
     * @dev See {icoic-setTokenURIs}.
     */
    function setTokenURIs(uint256[] calldata tokenIds, string[] calldata uris) external override adminRequired {
        require(tokenIds.length == uris.length, "Invalid input");
        for (uint i = 0; i < tokenIds.length; i++) {
            _tokenURIs[tokenIds[i]] = uris[i];
        }
    }

    /**
     * @dev See {icoic-updateRoyalties}.
     */
    function updateRoyalties(address payable recipient, uint256 bps) external override adminRequired {
        _royaltyRecipient = recipient;
        _royaltyBps = bps;
    }

    /**
     * ROYALTY FUNCTIONS
     */
    function getRoyalties(uint256) external view override returns (address payable[] memory recipients, uint256[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return (recipients, bps);
    }

    function getFeeRecipients(uint256) external view override returns (address payable[] memory recipients) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
        }
        return recipients;
    }

    function getFeeBps(uint256) external view override returns (uint[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return bps;
    }

    function royaltyInfo(uint256, uint256 value) external view override returns (address, uint256) {
        return (_royaltyRecipient, value*_royaltyBps/10000);
    }



}