// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./ILand.sol";

contract Land is
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    ILand
{
    using StringsUpgradeable for uint256;
    // current genesis token id, default: 0, the first token will have ID of 1
    uint256 public override currentId;
    string public override baseURI;

    mapping (address => bool) public override genesisMinter;

    function initialize(
        string memory name_,
        string memory symbol_
    ) external initializer {
        __ERC721_init(name_, symbol_);
        __ERC721Enumerable_init();
        __Pausable_init();
        __Ownable_init();
    }

    modifier onlyGenesisMinter() {
        require(
            genesisMinter[_msgSender()],
            "caller is not genesis minter"
        );
        _;
    }

    function setGenesisMinter(address minter, bool state) external onlyOwner {
        genesisMinter[minter] = state;
    }

    function setBaseURI(string calldata _uri) external onlyOwner {
        baseURI = _uri;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);
        string memory baseuri = _baseURI();
        return bytes(baseuri).length > 0 ? string(abi.encodePacked(baseuri, tokenId.toString())) : "";
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function mintToken(address to, bool isClaim, uint256 nekoId) external override onlyGenesisMinter nonReentrant whenNotPaused {
        currentId += 1;
        _safeMint(to, currentId);
        uint256[] memory ids = new uint256[](1);
        ids[0] = currentId;
        emit NFTMinted(to, ids);
        if (isClaim) {
            emit NFTClaimed(to, currentId, nekoId);
        } 
    }

    function mintBatchToken(address to, uint256 amount, address owner, bytes32 nonce) external override onlyGenesisMinter nonReentrant whenNotPaused {
        uint256 id = currentId + 1;
        currentId += amount;
        uint256[] memory ids = new uint256[](amount);
        for (uint256 i = 0; i < amount; i++) {
            ids[i] = id + i;
            _safeMint(to, id + i);
        }
        emit NFTMinted(to, ids);
        if (to != owner) {
            emit NFTMintedAndDeposited(owner, to, ids, nonce);
        }
    }

    function ownerOf(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, IERC721Upgradeable)
        returns (address)
    {
        require(
            tokenId > 0,
            "invalid token id"
        );
        return _ownerOf(tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setCurrentId(uint256 id) external onlyOwner {
        currentId = id;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    uint256[47] private __gap;
}