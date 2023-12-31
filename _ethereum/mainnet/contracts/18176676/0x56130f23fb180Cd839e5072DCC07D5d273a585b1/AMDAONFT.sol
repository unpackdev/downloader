// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";

contract AMDAONFT is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    ERC721BurnableUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    uint256 public maxMintCount;
    uint256 public paymentPrice;
    address public paymentToken;
    address public treasury;
    string public baseTokenURI;
    mapping(address => uint256) public whitelist;
    mapping(address => bool) public isWhitelist;
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    CountersUpgradeable.Counter _tokenIdCounter;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ERC721_init("The Great Migration of Literature and Art", "GMLA");
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __Pausable_init();
        __AccessControl_init();
        __ERC721Burnable_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);

        maxMintCount = 20;
        paymentPrice = 15000000000;
        paymentToken = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
        baseTokenURI = "https://amdao.mypinata.cloud/ipfs/QmePaSLnbbcrVRwHE74334sSBt8oeT1QLpLhWcivZ9NfLM/";
        treasury = 0xc81F491feF03c72075d4c68049B1cAbCd062D1a1;
    }

    function setMaxMintCount(uint256 _count) external onlyRole(MANAGER_ROLE) {
        maxMintCount = _count;
    }

    function setPaymentPrice(uint256 _price) external onlyRole(MANAGER_ROLE) {
        paymentPrice = _price;
    }

    function setPaymentToken(address _address) external onlyRole(MANAGER_ROLE) {
        paymentToken = _address;
    }

    function setBaseURI(string calldata baseUri) external onlyRole(MANAGER_ROLE) {
        baseTokenURI = baseUri;
    }

    function setTreasury(address _treasury) external onlyRole(MANAGER_ROLE) {
        treasury = _treasury;
    }

    function safeMint(address to) public virtual onlyRole(MANAGER_ROLE) {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId <= maxMintCount, "Mint upper limit exceeded");
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, string(abi.encodePacked(baseTokenURI, StringsUpgradeable.toString(tokenId))));
    }

    function whitelistMint() public virtual {
        require(IERC20Upgradeable(paymentToken).balanceOf(msg.sender) >= paymentPrice, "Your USDT balance is insufficient");
        require((whitelist[msg.sender] >= 1), "whitelisting for external users is disabled");
        whitelist[msg.sender] = whitelist[msg.sender] - 1;
        IERC20Upgradeable(paymentToken).safeTransferFrom(msg.sender, treasury, paymentPrice);
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId <= maxMintCount, "Mint upper limit exceeded");
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, string(abi.encodePacked(baseTokenURI, StringsUpgradeable.toString(tokenId))));
    }

    function setWhitelist(address _whitelistAddress) public virtual onlyRole(MANAGER_ROLE) whenNotPaused {
        require(!isWhitelist[_whitelistAddress], "This address has been whitelisted");
        isWhitelist[_whitelistAddress] = true;
        whitelist[_whitelistAddress] = 2;
    }

    function setWhitelistBatch(address[] calldata _whitelistAddresses) public virtual onlyRole(MANAGER_ROLE) whenNotPaused {
        for (uint256 i = 0; i < _whitelistAddresses.length; i++) {
            require(!isWhitelist[_whitelistAddresses[i]], "There are whitelists that have been set up in these addresses");
            isWhitelist[_whitelistAddresses[i]] = true;
            whitelist[_whitelistAddresses[i]] = 2;
        }
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
