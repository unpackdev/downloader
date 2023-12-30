// SPDX-License-Identifier: NO LICENSE
pragma solidity ^0.8.20;

import "./ERC721.sol";
import "./ERC2981.sol";
import "./Ownable.sol";
import "./LibString.sol";

contract VUNFTMainNet3 is ERC721, ERC2981, Ownable {
    struct AirdropData {
        uint id;
        string url;
        address to;
    }

    using LibString for uint;

    string public _preRevealURL;
    string private _baseURL;

    uint private _tokenCount;
    uint private _lastMintedIndex;
    uint private _airdropCount;
    uint private _revealStartTime;

    mapping(uint => string) private _tokenUri;
    mapping(address owner => mapping(uint256 index => uint256))
        private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;

    uint public maxSupply = 1000;

    constructor(
        string memory preRevealURL,
        string memory baseURL,
        address royaltyReceiver,
        uint96 royaltyFee
    ) {
        _preRevealURL = preRevealURL;
        _baseURL = baseURL;

        _initializeOwner(msg.sender);
        _setDefaultRoyalty(royaltyReceiver, royaltyFee);
    }

    function name() public pure override returns (string memory) {
        return "Very Ugly NFT MainNet 3";
    }

    function symbol() public pure override returns (string memory) {
        return "VUNFTMainNet3";
    }

    function airdrop(address[] memory users) external onlyOwner {
        uint len = users.length;
        for (uint i = 0; i < len; i++) {
            address to = users[i];
            _mintTokens(to, 1);
        }
        _airdropCount += len;
    }

    function airdropWithURL(AirdropData[] memory data) external onlyOwner {
        require(
            _tokenCount + data.length <= maxSupply,
            "NFT: exceed total counts"
        );
        for (uint i = 0; i < data.length; i++) {
            _mintToken(data[i].to, data[i].id);
            _tokenUri[data[i].id] = data[i].url;
        }
        _airdropCount += data.length;
    }

    function mint(uint count) external {
        _mintTokens(msg.sender, count);
    }

    function tokenURI(
        uint tokenId
    ) public view override returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "NFT: not minted");

        return
            isPreReveal() ? _preRevealURL : bytes(_tokenUri[tokenId]).length > 0
                ? _tokenUri[tokenId]
                : string(abi.encodePacked(_baseURL, "/", tokenId.toString()));
    }

    function totalSupply() public view returns (uint) {
        return _tokenCount;
    }

    function setMaxSupply(uint supply) external onlyOwner {
        maxSupply = supply;
    }

    function setPreRevealURL(string memory url) external onlyOwner {
        _preRevealURL = url;
    }

    function setRevealStartTime(uint date) external onlyOwner {
        require(_revealStartTime == 0, "NFT: reveal start time already set");
        _revealStartTime = date;
    }

    function revealStartTime() external view returns (uint) {
        return _revealStartTime;
    }

    function airdroppedCount() external view returns (uint) {
        return _airdropCount;
    }

    function isPreReveal() public view returns (bool) {
        return _revealStartTime == 0 || block.timestamp < _revealStartTime;
    }

    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) public view virtual returns (uint256) {
        require(
            index < balanceOf(owner),
            "ERC721Enumerable: owner index out of bounds"
        );
        return _ownedTokens[owner][index];
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _mintTokens(address to, uint count) internal {
        require(_tokenCount + count <= maxSupply, "NFT: exceeds max supply");

        uint k = _lastMintedIndex + 1;
        for (uint i = 0; i < count && k <= maxSupply; k++) {
            if (_ownerOf(k) == address(0)) {
                _mintToken(to, k);
                i += 1;
            }
        }
        _lastMintedIndex = k - 1;
    }

    function _mintToken(address to, uint tokenId) internal {
        require(_ownerOf(tokenId) == address(0), "NFT: already minted");

        _tokenCount += 1;

        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 id
    ) internal override {
        if (from != to) {
            if (to != address(0)) {
                uint256 length = balanceOf(to);
                _ownedTokens[to][length] = id;
                _ownedTokensIndex[id] = length;
            }
            if (from != address(0)) {
                uint256 lastTokenIndex = balanceOf(from) - 1;
                uint256 tokenIndex = _ownedTokensIndex[id];

                if (tokenIndex != lastTokenIndex) {
                    uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

                    _ownedTokens[from][tokenIndex] = lastTokenId;
                    _ownedTokensIndex[lastTokenId] = tokenIndex;
                }

                delete _ownedTokensIndex[id];
                delete _ownedTokens[from][lastTokenIndex];
            }
        }
    }
}
