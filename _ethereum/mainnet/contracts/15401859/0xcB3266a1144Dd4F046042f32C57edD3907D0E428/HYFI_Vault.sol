// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./IHYFI_Vault.sol";
import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./Initializable.sol";
import "./CountersUpgradeable.sol";
import "./SafeMath.sol";

contract HYFI_Vault is
    Initializable,
    IHYFI_Vault,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    ERC721BurnableUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeMath for uint256;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    CountersUpgradeable.Counter private _tokenIdCounter;

    uint256 private _supplyLimit; // Total number of tokens todo: check if it should be changable
    string private _baseTokenURI; // URI pointing to the folder IPFS containing all the art

    modifier enoughTokens(uint256 amount) {
        require(
            totalSupply().add(amount) <= _supplyLimit,
            "Not enough tokens."
        );
        _;
    }

    event BaseURIChanged(string _baseURI);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 supplyLimit
    ) public initializer {
        __ERC721_init(tokenName, tokenSymbol);
        __ERC721Enumerable_init();
        __Pausable_init();
        __AccessControl_init();
        __ERC721Burnable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        _supplyLimit = supplyLimit;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function safeMint(address to, uint256 amount)
        public
        onlyRole(MINTER_ROLE)
        enoughTokens(amount)
    {
        uint256 tokenId;
        for (uint256 i = 0; i < amount; i++) {
            tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(to, tokenId);
        }
    }

    function burn(uint256 tokenId)
        public
        override(ERC721BurnableUpgradeable)
        onlyRole(BURNER_ROLE)
    {
        _burn(tokenId);
    }

    // Sets the URI pointing to the folder containing the art. Should NOT be used after reveal.
    function setBaseURI(string memory baseTokenURI)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _baseTokenURI = baseTokenURI;
        emit BaseURIChanged(_baseTokenURI);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function getSupplyLimit() public view returns (uint256) {
        return _supplyLimit;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable,
            AccessControlUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId) internal override(ERC721Upgradeable) {
        super._burn(tokenId);
    }

    function _baseURI()
        internal
        view
        override(ERC721Upgradeable)
        returns (string memory)
    {
        return _baseTokenURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
