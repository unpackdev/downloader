// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0 <0.9.0;

import "./ERC721.sol";

import "./Ownable.sol";

/**
 * @title DougTag
 * @dev DougTag NFT
 */
contract DougTag is Ownable, ERC721 {
    string private _uri;
    mapping(uint256 => uint8) private _types;
    mapping(uint256 => uint8) private _ranks;
    mapping(uint256 => uint8) private _sequenceNumbers;
    uint256 private _tokenCounter;
    address private _doug;

    constructor(address _owner) ERC721("DougTag", "DOUG_TAG") Ownable(_owner) {
        _doug = msg.sender;
    }

    function getDougType(uint256 tokenId) public view returns (uint8) {
        require(_exists(tokenId), "DougTag: token doesn't exist");
        return _types[tokenId];
    }

    function mint(
        address to,
        uint8 dougType,
        uint8 dougRank,
        uint8 sequenceNumber
    ) public {
        require(msg.sender == _doug, "DougTag: Not Doug");
        _tokenCounter++;
        _types[_tokenCounter] = dougType;
        _ranks[_tokenCounter] = dougRank;
        _sequenceNumbers[_tokenCounter] = sequenceNumber;

        _safeMint(to, _tokenCounter);
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function reveal(string memory baseURI) public {
        require(msg.sender == _doug, "DougTag: Not Doug");
        _uri = baseURI;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();

        string memory dougType = Strings.toString(_types[tokenId]);
        string memory rank = Strings.toString(_ranks[tokenId]);
        string memory sequenceNumber = Strings.toString(_ranks[tokenId]);
        bytes memory fullUri = abi.encodePacked(
            baseURI,
            "doug_tag_",
            dougType,
            "_",
            rank,
            "_",
            sequenceNumber,
            ".json"
        );
        return string(fullUri);
    }
}
