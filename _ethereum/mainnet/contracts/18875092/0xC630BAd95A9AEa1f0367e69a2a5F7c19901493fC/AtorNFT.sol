// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";

/**
 * @title Ator NFT Contract
 * @author chainpioneer1
 * @notice
 */
contract AtorNFT is
    Ownable,
    ERC721Enumerable,
    ERC721URIStorage,
    ReentrancyGuard
{
    // Variables
    bool private _bActiveMint;
    uint256 private _mintFee;
    address private _mintFeeAddress;
    uint256 private _maxSupply;
    uint256 private _limitPerUser;
    bool private _bActiveWhitelistMint;
    string private _tokenBaseURI;
    // The internal token ID tracker
    uint256 private _currentId;
    // ATOR token address
    IERC20 public immutable atorToken;
    mapping(address => bool) private _whitelist;
    mapping(address => uint256) private _mintedCounts;
    // Minimum holding ATOR token amount to mint nft
    uint256 private _atorGateAmount;

    // Events
    event Minted(uint256 indexed tokenId);
    event AddToWhitelist(address[] indexed users);
    event RemoveFromWhitelist(address[] indexed users);
    event UpdateMintFee(uint256 indexed mintFee);

    constructor(
        uint256 initialSupply,
        address _atorToken
    ) ERC721("Atornauts", "RELAY") {
        _mintFee = 0.1 ether;
        _maxSupply = initialSupply;
        _limitPerUser = 1;
        _mintFeeAddress = msg.sender;
        atorToken = IERC20(_atorToken);
        _atorGateAmount = 250 * 1e18;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721Enumerable, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(
        uint256 index
    ) public view override returns (uint256) {
        require(
            index < _currentId,
            "ERC721Enumerable: global index out of bounds"
        );
        return index + 1;
    }

    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _tokenBaseURI;
    }

    /**
     * @notice Mint a nft to sender and sender pay ether to mint
     * @dev Call _mintTo with the to address.
     */
    function mint(address to) external payable nonReentrant returns (uint256) {
        uint256 mintCount = _mintedCounts[msg.sender];
        require(
            atorToken.balanceOf(msg.sender) >= _atorGateAmount,
            "holding requirement active"
        );
        require(
            _bActiveMint ||
                (_bActiveWhitelistMint &&
                    _whitelist[msg.sender] &&
                    mintCount == 0),
            "mint was disabled!"
        );
        require(++_currentId <= _maxSupply, "all nfts were minted!");
        require(++mintCount <= _limitPerUser, "exceed limit!");
        _mintedCounts[msg.sender] = mintCount;
        (bool success, ) = payable(msg.sender).call{
            value: msg.value - _mintFee
        }("");
        (bool feeSucess, ) = payable(_mintFeeAddress).call{value: _mintFee}("");
        require(success && feeSucess, "failed to pay fee!");
        return _mintTo(to, _currentId);
    }

    function mintedCount(address user) external view returns (uint256) {
        return _mintedCounts[user];
    }

    function isWhitelist(address user) external view returns (bool) {
        return _whitelist[user];
    }

    function maxSupply() external view returns (uint256) {
        return _maxSupply;
    }

    /**
     * @dev See {ERC721Enumerable-totalSupply} of OpenZeppline.
     */
    function totalSupply() external view returns (uint256) {
        return _currentId;
    }

    function getMintFee() external view returns (uint256) {
        return _mintFee;
    }

    function getLimitPerUser() external view returns (uint256) {
        return _limitPerUser;
    }

    function isEnableMint() external view returns (bool) {
        return _bActiveMint;
    }

    function isEnableWhitelistMint() external view returns (bool) {
        return _bActiveWhitelistMint;
    }

    function tokensByOwner(
        address user
    ) external view returns (uint256[] memory tokenIds) {
        uint256 count = balanceOf(user);
        tokenIds = new uint256[](count);
        for (uint256 i; i < count; ) {
            uint256 tokenId = tokenOfOwnerByIndex(user, i);
            tokenIds[i] = tokenId;
            unchecked {
                ++i;
            }
        }
    }

    function activateMint() external onlyOwner {
        _bActiveMint = true;
    }

    function deactivateMint() external onlyOwner {
        _bActiveMint = false;
    }

    function updateMintFee(uint256 newMintFee) external onlyOwner {
        require(!_bActiveMint, "Mint is active!");
        _mintFee = newMintFee;
        emit UpdateMintFee(newMintFee);
    }

    function increaseMaxSupply(uint256 newMaxSupply) external onlyOwner {
        require(newMaxSupply > _maxSupply, "Less than old supply!");
        _maxSupply = newMaxSupply;
    }

    function updateWalletLimit(uint256 limit) external onlyOwner {
        _limitPerUser = limit;
    }

    function updateFeeAddress(address newFeeAddress) external onlyOwner {
        _mintFeeAddress = newFeeAddress;
    }

    function updateTokenGateAmount(uint256 amount) external onlyOwner {
        _atorGateAmount = amount;
    }

    function addWhitelist(address[] calldata users) external onlyOwner {
        for (uint256 i; i < users.length; ) {
            _whitelist[users[i]] = true;
            unchecked {
                ++i;
            }
        }
        emit AddToWhitelist(users);
    }

    function removeWhitelist(address[] calldata users) external onlyOwner {
        for (uint256 i; i < users.length; ) {
            _whitelist[users[i]] = false;
            unchecked {
                ++i;
            }
        }
        emit RemoveFromWhitelist(users);
    }

    function whitelistMintEnable(bool bEnable) external onlyOwner {
        _bActiveWhitelistMint = bEnable;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        _tokenBaseURI = uri;
    }

    function setTokenURI(
        uint256 tokenId,
        string memory uri
    ) external onlyOwner {
        super._setTokenURI(tokenId, uri);
    }

    /**
     * @notice Mint a Ator NFT with `tokenId` to the provided `to` address.
     */
    function _mintTo(address to, uint256 tokenId) internal returns (uint256) {
        _safeMint(to, tokenId);
        emit Minted(tokenId);
        return tokenId;
    }

    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    receive() external payable {}
}
