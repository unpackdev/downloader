// SPDX-License-Identifier: MIT

/**
 * ░█▄█░▄▀▄▒█▀▒▄▀▄░░░▒░░░░█▄░█▒█▀░▀█▀
 * ▒█▒█░▀▄▀░█▀░█▀█▒░░▀▀▒░░█▒▀█░█▀░▒█▒
 *
 * Made with 🧡 by Kreation.tech
 */
pragma solidity ^0.8.9;

import "./IERC2981.sol";
import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Burnable.sol";
import "./AccessControl.sol";
import "./Counters.sol";
import "./EnumerableMap.sol";
import "./EnumerableSet.sol";

/// @custom:security-contact info@kreation.tech
contract HofaNFT is ERC721, ERC721URIStorage, ERC721Burnable, IERC2981, AccessControl {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    Counters.Counter private _counter;

    mapping(uint256 => address) private _creators;
    mapping(address => EnumerableSet.UintSet) private _creatorTokens;

    // Store for hash codes of token contents: used to prevent re-issuing of the same content
    mapping(bytes32 => bool) private _contents;

    mapping(uint256 => uint16) private _royalties;

    constructor() ERC721("hofa.io", "HOFA") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    modifier onlyValidURI(string memory uri) {
        require(
            bytes(uri).length != 0,
            "Specified uri must be non-empty"
        );
        _;
    }

    function mint(string memory uri, bytes32 hash, uint16 royalties) public onlyValidURI(uri) onlyRole(MINTER_ROLE) {
        require(!_contents[hash], "Duplicated content");
        require(royalties < 10_000, "Royalties too high");
        _contents[hash] = true;
        uint256 tokenId = _counter.current();
        _counter.increment();
        _royalties[tokenId] = royalties;
        _creators[tokenId] = msg.sender;
        _creatorTokens[msg.sender].add(tokenId);
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function totalSupply() public view returns (uint256) {
        return _counter.current();
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl, IERC165) returns (bool) {
        return type(IERC2981).interfaceId == interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * ERC2981 - Gets royalty information for token
     *
     * @param tokenId the the id of the token sold
     * @param value the sale price for this token
     */
    function royaltyInfo(uint256 tokenId, uint256 value) external view override returns (address receiver, uint256 royaltyAmount) {
        require(_exists(tokenId), "ERC721: token does not exist");
        return (_creators[tokenId], (value * _royalties[tokenId]) / 10_000);
    }

    function creatorOf(uint256 tokenId) external view returns (address) {
        require(_exists(tokenId), "ERC721: token does not exist");
        return _creators[tokenId];
    }

    function creationsOf(address creator) external view returns (uint256[] memory) {
        require(_creatorTokens[creator].length() > 0, "Not a creator");
        return _creatorTokens[creator].values();
    }
}