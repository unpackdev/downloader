// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./CountersUpgradeable.sol";
import "./StringsUpgradeable.sol";

contract NFGC is
    Initializable,
    ERC721Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using StringsUpgradeable for uint256;

    CountersUpgradeable.Counter private _tokenIdsCounter;
    mapping(address => uint256) _mintsPerWallet;

    string public baseURI;
    address public metakitAdmin;

    event BaseURIChanged(string indexed uri);
    event NFTMinted(address indexed account, uint256 amount);
    event Paused();
    event Unpaused();
    event Withdrawn(address indexed account, uint256 amount);

    error InvalidPaymentAmount(uint256 price, uint256 payment);
    error MaxNFTSupplyReached();
    error MaxMintPerWalletReached(address account, uint256 amount);
    error NotMetakitAdmin();
    error ZeroAddress();
    error ZeroAmount();

    modifier onlyMetakit() {
        if (_msgSender() != metakitAdmin) {
            revert NotMetakitAdmin();
        }

        _;
    }

    function initialize(string calldata baseURI_, address metakitAdmin_)
        public
        initializer
    {
        __ERC721_init("Automata x No Fear Genesis Cap", "GC");
        __Ownable_init();

        _tokenIdsCounter.increment(); // starts from 1

        baseURI = baseURI_;

        if (metakitAdmin_ == address(0)) {
            revert ZeroAddress();
        }

        metakitAdmin = metakitAdmin_;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _checkMint(uint256 amount, uint256 payment) internal view {
        uint256 price = nftPrice() * amount;
        if (price != payment) {
            revert InvalidPaymentAmount(price, payment);
        }

        uint256 toMint = _mintsPerWallet[_msgSender()] + amount;
        if (toMint > maxMintPerWallet()) {
            revert MaxMintPerWalletReached(_msgSender(), toMint);
        }

        if (amount + tokenIdsCounter() > maxNFTSupply()) {
            revert MaxNFTSupplyReached();
        }
    }

    function mintNFT(uint256 amount) external payable nonReentrant {
        _checkMint(amount, msg.value);

        unchecked {
            for (uint256 i; i < amount; i++) {
                _safeMint(_msgSender(), tokenIdsCounter());
                _tokenIdsCounter.increment();
            }
        }

        _mintsPerWallet[_msgSender()] += amount;

        emit NFTMinted(_msgSender(), amount);
    }

    function pause() external onlyOwner {
        _pause();

        emit Paused();
    }

    function unpause() external onlyOwner {
        _unpause();

        emit Unpaused();
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        baseURI = uri;

        emit BaseURIChanged(uri);
    }

    function withdrawETH(address account_) external onlyOwner {
        if (account_ == address(0)) {
            revert ZeroAddress();
        }

        uint256 amount = address(this).balance;
        if (amount == 0) {
            revert ZeroAmount();
        }

        payable(account_).transfer(amount);

        emit Withdrawn(_msgSender(), amount);
    }

    function maxNFTSupply() public pure returns (uint256) {
        return 1000;
    }

    function maxMintPerWallet() public pure returns (uint256) {
        return 10;
    }

    function nftPrice() public pure returns (uint256) {
        return 50_000_000_000_000_000; // 0.05 ETH
    }

    function tokenIdsCounter() public view returns (uint256) {
        return _tokenIdsCounter.current();
    }

    function tokenURI(uint256 tokenId_)
        public
        view
        override
        returns (string memory)
    {
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, tokenId_.toString(), ".json")
                )
                : "";
    }

    function exportItem(
        address account_,
        string calldata,
        uint256 tokenId_
    ) public onlyMetakit returns (uint256) {
        if (ownerOf(tokenId_) == address(this)) {
            super._transfer(address(this), account_, tokenId_);
            return tokenId_;
        }

        uint256 tokenId = tokenIdsCounter();
        _safeMint(_msgSender(), tokenId);
        _tokenIdsCounter.increment();

        return tokenId;
    }

    function importItem(
        address account_,
        address target_,
        uint256 tokenId_
    ) public onlyMetakit returns (bool) {
        _transfer(account_, target_, tokenId_);

        return true;
    }

    function changeAdmin(address metakitAdmin_) public onlyOwner {
        if (metakitAdmin_ == address(0)) {
            revert ZeroAddress();
        }

        metakitAdmin = metakitAdmin_;
    }
}
