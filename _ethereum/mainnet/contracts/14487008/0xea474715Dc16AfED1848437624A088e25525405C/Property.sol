// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./IBooty.sol";
import "./errors.sol";

// solhint-disable not-rely-on-time

abstract contract Property is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using AddressUpgradeable for address;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    struct Tier {
        uint256 mintPrice;
        uint16 maxSupply;
        uint176 totalSupply;
        uint64 launchDelay;
    }

    uint64 private _launchDate;
    uint256 internal _nonce;

    mapping(uint256 => Tier) private _tiers;

    IBooty private _booty;
    CountersUpgradeable.Counter private _tokenIdCounter;

    modifier onlyEOA() {
        // solhint-disable-next-line avoid-tx-origin
        if (msg.sender.isContract() || msg.sender != tx.origin) {
            revert CallerNotEOA();
        }

        _;
    }

    // solhint-disable-next-line func-name-mixedcase
    function __Property_init(
        string memory name_,
        string memory symbol_,
        Tier[5] calldata tiers
    ) internal onlyInitializing {
        __ERC721_init(name_, symbol_);
        __ERC721Enumerable_init();
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        __Property_init_unchained(tiers);
    }

    // solhint-disable-next-line func-name-mixedcase
    function __Property_init_unchained(Tier[5] calldata tiers) internal onlyInitializing {
        for (uint256 i; i < tiers.length; i++) {
            _tiers[i + 1] = tiers[i];
        }

        _nonce = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender)));
    }

    function mint(address to) external whenNotPaused onlyEOA {
        if (_launchDate + _tiers[1].launchDelay >= block.timestamp) {
            revert MintingUnavailable();
        }

        if (_booty.balanceOf(msg.sender) < _tiers[1].mintPrice) {
            revert InsufficientFunds();
        }

        _booty.burnFrom(msg.sender, _tiers[1].mintPrice);

        _tokenIdCounter.increment();

        uint256 tokenId = _tokenIdCounter.current();

        _tiers[1].totalSupply++;

        _mintCore(tokenId);
        _safeMint(to, tokenId);
        _updateNonce();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function setBooty(address address_) external onlyOwner {
        _booty = IBooty(address_);
    }

    function setLaunchDate(uint64 timestamp) external onlyOwner {
        _launchDate = timestamp;
    }

    function setURIBuilder(address address_) external virtual;

    function totalSupply(uint256 tier) external view returns (uint256) {
        if (tier < 1 || tier > 5) {
            revert OutOfRange(1, 5);
        }

        return _tiers[tier].totalSupply;
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function upgrade(uint256[] calldata tokenIds, uint256[] calldata tiers) public virtual whenNotPaused onlyEOA {
        if (tokenIds.length != tiers.length) {
            revert ArgumentMismatch();
        }

        uint256 totalPrice;

        for (uint256 i; i < tokenIds.length; i++) {
            uint256 toTier = tiers[i];
            uint256 tokenId = tokenIds[i];

            if (_launchDate + _tiers[toTier].launchDelay > block.timestamp) {
                revert TierUnavailable(toTier);
            }

            if (msg.sender != ownerOf(tokenId)) {
                revert Unauthorized();
            }

            if (toTier < 2 || toTier > 5) {
                revert OutOfRange(2, 5);
            }

            if (toTier >= 3 && _tiers[toTier].totalSupply >= _tiers[toTier].maxSupply) {
                revert SoldOut();
            }

            uint256 fromTier = _tierOf(tokenId);

            for (uint256 t = fromTier + 1; t <= toTier; t++) {
                totalPrice += _tiers[t].mintPrice;
            }

            _tiers[fromTier].totalSupply--;
            _tiers[toTier].totalSupply++;
        }

        if (_booty.balanceOf(msg.sender) < totalPrice) {
            revert InsufficientFunds();
        }

        _booty.burnFrom(msg.sender, totalPrice);
    }

    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _ensureExists(uint256 tokenId) internal view {
        if (!_exists(tokenId)) {
            revert TokenNotFound(tokenId);
        }
    }

    function _mintCore(uint256 tokenId) internal virtual;

    function _tierOf(uint256 tokenId) internal view virtual returns (uint256);

    function _updateNonce() internal {
        _nonce = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _nonce)));
    }

    // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    uint256[32] private __gap;
}
