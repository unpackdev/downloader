// SPDX-License-Identifier: MIT

/**
 /$$$$$$$$ /$$   /$$  /$$$$$$ 
| $$_____/| $$  / $$ /$$__  $$
| $$      |  $$/ $$/| $$  \ $$
| $$$$$    \  $$$$/ | $$  | $$
| $$__/     >$$  $$ | $$  | $$
| $$       /$$/\  $$| $$  | $$
| $$$$$$$$| $$  \ $$|  $$$$$$/
|________/|__/  |__/ \______/ 
                              
*/

pragma solidity ^0.8.4;

import "./ERC721XUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./console.sol";

error WithdrawToZeroAddress();
error WithdrawToNonOwner();
error WithdrawZeroBalance();

contract ExoV4 is Initializable, OwnableUpgradeable, ERC721XUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    address public ownerWallet;
    uint256 internal constant MAX_SUPPLY = 10000;
    uint256 internal constant DEV_MINT = 250;
    uint256 internal constant MAX_PER_TX = 2;
    uint256 internal constant MAX_PER_WALLET = 5;
    string internal _rootURI;
    bool internal mintActive;

    mapping(address => AddressData) internal _addressData;

    struct AddressData {
        uint64 balance;
        uint64 numberMinted;
    }

    mapping(address => uint256) internal _mintBalance;

    function initialize(
        string memory name_,
        string memory symbol_,
        address ownerWallet_
    ) external initializer {
        __ERC721Psi_init(name_, symbol_);
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        ownerWallet = ownerWallet_;
        mintActive = false;
        _rootURI = "";
    }

    /* solhint-disable-next-line no-empty-blocks */
    function _authorizeUpgrade(address _newImplementation) internal override onlyOwner {}

    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function getMintStatus() public view returns (bool) {
        return mintActive;
    }

    function setMintStatus(bool _mintActive) public onlyOwner {
        mintActive = _mintActive;
    }

    function setOwnerWallet(address _ownerWallet) public onlyOwner {
        ownerWallet = _ownerWallet;
    }

    function safeMint(address to, uint256 quantity) public nonReentrant {
        if (!mintActive) revert MintIsNotActive();
        if (to == address(0)) revert MintToZeroAddress();
        if (_minted + quantity > MAX_SUPPLY) revert MintExceedsMaxSupply();
        if (quantity > MAX_PER_TX) revert MintQuantityLargerThanMaxPerTX();
        if (_mintBalance[to] + quantity > MAX_PER_WALLET) revert MintExceedsWalletAllowance();
        _safeMint(to, quantity);
        _mintBalance[to] += quantity;
    }

    function safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) public nonReentrant {
        if (!mintActive) revert MintIsNotActive();
        if (to == address(0)) revert MintToZeroAddress();
        if (_minted + quantity > MAX_SUPPLY) revert MintExceedsMaxSupply();
        if (quantity > MAX_PER_TX) revert MintQuantityLargerThanMaxPerTX();
        if (_mintBalance[to] + quantity > MAX_PER_WALLET) revert MintExceedsWalletAllowance();
        _safeMint(to, quantity, _data);
        _mintBalance[to] += quantity;
    }

    function devMint(
        address[] memory _to,
        uint256[] memory _quantity,
        uint256 _totalAmount
    ) public onlyOwner {
        if (_minted + _totalAmount > DEV_MINT) revert MintExceedsDevSupply();
        for (uint256 i = 0; i < _to.length; i++) {
            _safeMint(_to[i], _quantity[i]);
        }
    }

    function devRefund(address[] memory _to, uint256[] memory _quantity) public onlyOwner {
        for (uint256 i = 0; i < _to.length; i++) {
            _safeMint(_to[i], _quantity[i]);
        }
    }

    function getBatchHead(uint256 tokenId) public view {
        _getBatchHead(tokenId);
    }

    function getBaseURI() public view returns (string memory) {
        return _rootURI;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        _rootURI = _baseURI;
    }

    function getTokenParams(uint256 tokenId) internal pure returns (string memory) {
        return string(abi.encodePacked("?id=", tokenId.toString()));
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory tokenParams = getTokenParams(tokenId);
        return bytes(_rootURI).length > 0 ? string(abi.encodePacked(_rootURI, tokenParams)) : "";
    }

    function release() public {
        if (msg.sender == address(0)) revert WithdrawToZeroAddress();
        if (msg.sender != ownerWallet) revert WithdrawToNonOwner();
        if (balanceOf(ownerWallet) == 0) revert WithdrawZeroBalance();

        AddressUpgradeable.sendValue(payable(ownerWallet), address(this).balance);
    }

    /* solhint-disable-next-line no-empty-blocks */
    receive() external payable {}
}
