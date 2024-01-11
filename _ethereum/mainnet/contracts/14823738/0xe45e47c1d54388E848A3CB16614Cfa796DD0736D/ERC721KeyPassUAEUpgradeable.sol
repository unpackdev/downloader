// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./ContextUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./ERC721PausableUpgradeable.sol";

contract ERC721KeyPassUAEUpgradeable is Initializable, ContextUpgradeable, OwnableUpgradeable, ERC721EnumerableUpgradeable, ERC721BurnableUpgradeable, ERC721PausableUpgradeable {
    using StringsUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // ERC2981 interface id
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    // Nft base uri
    string private _baseUri;
    // Nft tokens max total supply
    uint256 private constant _MAX_TOTAL_SUPPLY = 1971;
    // Nft token id tracker
    CountersUpgradeable.Counter private _tokenIdTracker;

    // Nft token collection royalty params
    address private _royaltyAddress;
    uint256 private _royaltyPercent;
    uint256 private constant _100_PERCENT = 10000; // 10000 equal 100%

    // Mapping for nft token trusted minters
    mapping(address => bool) private _trustedMinterList;

    // Emitted when base uri update
    event BaseUriUpdated(string baseUri);

    // Emitted when royalty params updated
    event RoyaltyParamsUpdated(address account, uint256 percent);

    // Emitted when `account` added to trusted minter list.
    event AddToTrustedMinterList(address account);
    // Emitted when `account` removed from trusted minter list.
    event RemoveFromTrustedMinterList(address account);

    modifier onlyTrustedMinter(address account_) {
        require(_trustedMinterList[account_], "ERC721KeyPassUAE: caller is not trusted minter");
        _;
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        string memory baseUri_
    ) public virtual initializer {
        __ERC721KeyPassUAE_init(name_, symbol_, baseUri_);
    }

    function __ERC721KeyPassUAE_init(
        string memory name_,
        string memory symbol_,
        string memory baseUri_
    ) internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
        __ERC721Enumerable_init_unchained();
        __ERC721Burnable_init_unchained();
        __Pausable_init_unchained();
        __ERC721Pausable_init_unchained();
        __ERC721KeyPassUAE_init_unchained(baseUri_);
    }

    function __ERC721KeyPassUAE_init_unchained(string memory baseUri_) internal initializer {
        require(bytes(baseUri_).length != 0, "ERC721KeyPassUAE: invalid base uri");
        _baseUri = baseUri_;
    }

    function getOwner() external view virtual returns (address) {
        return owner();
    }

    function getMaxTotalSupply() public pure virtual returns (uint256) {
        return _MAX_TOTAL_SUPPLY;
    }

    function getTotalSupply() public view virtual returns (uint256) {
        return _tokenIdTracker.current();
    }

    function stats() external view virtual returns (uint256 maxTotalSupply, uint256 totalSupply, uint256 supplyLeft) {
        maxTotalSupply = getMaxTotalSupply();
        totalSupply = getTotalSupply();
        return (
            maxTotalSupply,
            totalSupply,
            maxTotalSupply - totalSupply
        );
    }

    function exists(uint256 tokenId_) external view virtual returns (bool) {
        return _exists(tokenId_);
    }

    function tokenURI(uint256 tokenId_) public view virtual override returns (string memory) {
        require(_exists(tokenId_), "ERC721KeyPassUAE: URI query for nonexistent token");
        return string(abi.encodePacked(_baseUri, tokenId_.toString(), ".json"));
    }

    function isTrustedMinter(address account_) external view virtual returns (bool) {
        return _trustedMinterList[account_];
    }

    function supportsInterface(bytes4 interfaceId_) public view virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable) returns (bool) {
        return interfaceId_ == _INTERFACE_ID_ERC2981 || super.supportsInterface(interfaceId_);
    }

    function royaltyParams() external view virtual returns (address royaltyAddress, uint256 royaltyPercent) {
        return (
            _royaltyAddress,
            _royaltyPercent
        );
    }

    function royaltyInfo(
        uint256 /*tokenId_*/,
        uint256 salePrice_
    ) external view virtual returns (
        address receiver,
        uint256 royaltyAmount
    ) {
        receiver = _royaltyAddress;
        royaltyAmount = salePrice_ * _royaltyPercent / _100_PERCENT;
        return (
            receiver,
            royaltyAmount
        );
    }

    function pause() external virtual onlyOwner {
        _pause();
    }

    function unpause() external virtual onlyOwner {
        _unpause();
    }

    function updateBaseUri(string memory baseUri_) external virtual onlyOwner {
        require(bytes(baseUri_).length != 0, "ERC721KeyPassUAE: invalid base uri");
        _baseUri = baseUri_;
        emit BaseUriUpdated(baseUri_);
    }

    function addToTrustedMinterList(address account_) external virtual onlyOwner {
        require(account_ != address(0), "ERC721KeyPassUAE: invalid address");
        _trustedMinterList[account_] = true;
        emit AddToTrustedMinterList(account_);
    }

    function removeFromTrustedMinterList(address account_) external virtual onlyOwner {
        require(account_ != address(0), "ERC721KeyPassUAE: invalid address");
        _trustedMinterList[account_] = false;
        emit RemoveFromTrustedMinterList(account_);
    }

    function updateRoyaltyParams(address account_, uint256 percent_) external virtual onlyOwner {
        require(account_ != address(0), "ERC721KeyPassUAE: invalid address");
        require(percent_ <= _100_PERCENT, "ERC721KeyPassUAE: invalid percent");
        _royaltyAddress = account_;
        _royaltyPercent = percent_;
        emit RoyaltyParamsUpdated(account_, percent_);
    }

    function mintTokenBatch(address recipient_, uint256 tokenCount_) external virtual onlyTrustedMinter(_msgSender()) {
        _mintTokenBatch(recipient_, tokenCount_);
    }

    function _mintTokenBatch(address recipient_, uint256 tokenCount_) internal virtual {
        require(recipient_ != address(0), "ERC721KeyPassUAE: invalid address");
        require(tokenCount_ != 0, "ERC721KeyPassUAE: invalid token count");
        require((tokenCount_ + getTotalSupply()) <= getMaxTotalSupply(), "ERC721KeyPassUAE: Max total supply limit reached");
        for (uint256 i = 0; i < tokenCount_; ++i) {
            _tokenIdTracker.increment();
            _mint(recipient_, _tokenIdTracker.current());
        }
    }

    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 tokenId_
    ) internal virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721PausableUpgradeable) {
        super._beforeTokenTransfer(from_, to_, tokenId_);
    }
}
