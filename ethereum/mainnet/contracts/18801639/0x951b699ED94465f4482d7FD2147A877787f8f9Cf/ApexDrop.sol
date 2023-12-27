// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;
import "./ERC721Enumerable.sol";
import "./ERC2981.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

/**
 *   __ _ _ __   _____  ____      ____ _| |_ ___| |__   ___| |_   _| |__  
 *  / _` | '_ \ / _ \ \/ /\ \ /\ / / _` | __/ __| '_ \ / __| | | | | '_ \ 
 * | (_| | |_) |  __/>  <  \ V  V / (_| | || (__| | | | (__| | |_| | |_) |
 *  \__,_| .__/ \___/_/\_\  \_/\_/ \__,_|\__\___|_| |_|\___|_|\__,_|_.__/ 
 *       |_|                                                              
 *
 * @title ApexDrop
 *
 * @dev This contract is specifically built for Apex Watch Club
 */
contract ApexDrop is ERC721Enumerable, ERC2981, Ownable, ReentrancyGuard {
    // ========== STRUCTS ==========

    struct DropCandidate {
        address user;
        uint256 count;
    }

    // ========== CONSTANTS ==========

    uint96 constant _INITIAL_ROYALTY = 500;

    // ========== VARIABLES ==========

	uint256 _tokenId;
    string _apexBaseURI = "https://nftstorage.link/ipfs/bafybeihyb4t4lsxcfgznv2zbscjtwdj7sbictmkpdn2hc2gfddrg2myofy/";

    // ========== EVENTS ==========

    event Minted(address to, uint256 tokenId); 
    event SetBaseURI(string baseURI); 
    event SetRoyalty(address receiver, uint96 royalty); 

	constructor() ERC721('Apex Watch Club', 'AWC') Ownable(msg.sender) {
        // set Owner as the receiver of royalties too
        _setDefaultRoyalty(msg.sender, _INITIAL_ROYALTY);
    }

    // ========== WRITE ==========

	function mint(address to) internal onlyOwner {
		_tokenId++;
		_safeMint(to, _tokenId);

        emit Minted(to, _tokenId);
	}


    function drop(DropCandidate[] memory list) public onlyOwner nonReentrant {
        uint256 length = list.length;
        for (uint256 i = 0; i < length; i++) {
            for (uint256 j = 0; j < list[i].count; j++) {
                mint(list[i].user);
            }
        }
    }

    /**
     * @dev Mainly used for delayed reveal
     */
    function setBaseURI(string memory newBaseUri) public onlyOwner nonReentrant {
        _apexBaseURI = newBaseUri;

        emit SetBaseURI(newBaseUri);
    }

    /**
     * @dev Set royalty as desired
     * @param feeNumerator is in basis points (e.g. 500 = 5%)
     */
    function setRoyalty(address receiver, uint96 feeNumerator) public onlyOwner nonReentrant {
        _setDefaultRoyalty(receiver, feeNumerator);

        emit SetRoyalty(receiver, feeNumerator);
    }

    // ========== READ ==========

    function _baseURI() internal view override returns (string memory) {
        return _apexBaseURI;
    }

    function getBaseURI() public view returns (string memory) {
        return _apexBaseURI;
    }

    function getTokenId() public view returns (uint256)  {
        return _tokenId;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, ERC2981) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId
            || interfaceId == type(IERC2981).interfaceId
            || super.supportsInterface(interfaceId);
    }
}
