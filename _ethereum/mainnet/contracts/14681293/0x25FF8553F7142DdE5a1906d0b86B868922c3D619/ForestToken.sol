/**
 * @authors
    Arvind Kalra <kalarvind97@gmail.com>
    Pranav Singhal <pranavsinghal96@gmail.com>
 * @date 30/04/2022
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155Upgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ERC1155SupplyUpgradeable.sol";
import "./Initializable.sol";
import "./CountersUpgradeable.sol";
import "./PausableUpgradeable.sol";

contract ForestToken is Initializable, ERC1155Upgradeable, AccessControlUpgradeable,
    PausableUpgradeable, ERC1155SupplyUpgradeable {

    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;

    struct TokenMetadata {
        string unit_size;
        uint256 conservation_time_months;
        string monitoring_frequency;
        string monitoring_provider;
        string asset_type;
        string pyt_conservation_token_type;
        string total_conservation_area;
        string artist_name;
    }

    // Mapping to store token uri (basically ipfs url for each token that stores all the metadata)
    mapping(uint256 => string) private _tokenURIs;

    // Mapping to store contract level token metadata
    mapping(uint256 => TokenMetadata) public TOKEN_DETAILS;

    address private _owner;

    // Will store collection's ipfs url
    string private _contractUri;

    // All the collection's metadata to be stored on the chain itself
    string public name;
    string public symbol;
    string public description;
    string public total_area_size;
    string public unit_size;
    string public property_name;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __ERC1155_init("");
        __AccessControl_init();
        __ERC1155Supply_init();
        __Pausable_init();

        _grantRole(DEPLOYER_ROLE, msg.sender);
        _grantRole(PYT_ADMIN_ROLE, msg.sender);

        _owner = msg.sender;

        name = "Surui - Reserva 7 de Setembro";
        symbol = "PSR";
        description = "Help conserve the Surui 7 de Setembro Reserve! The 7 de Setembro Reserve is the traditional home of the Paiter Surui people. It occupies an area of 248,147 hectares in the heart of the Amazon and is home to 5000 Paiter Suruis. The 7 de Setembro Collection offers a unique opportunity for the public to directly engage in the conservation of a socially and culturally significant area of the Amazon Rainforest. Proceeds from token sales go directly to the Paiter Surui.";
        total_area_size = "248146.92 ha";
        unit_size = "1 ha";
        property_name = "Reserva 7 de Setembro";
        _contractUri = "https://ipfs.plantyourtree.com/ipfs/QmXSZgYosyqLEmXnAtBgCQhHdehAf4BUJUu5sTmU2At3WE";
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function setContractURI(string memory newuri) public {
        require(hasRole(PYT_ADMIN_ROLE, _msgSender()), 'Access Control: You do not have the required role for this function');

        _contractUri = newuri;
    }

    function contractURI() public view returns (string memory) {
        return _contractUri;
    }

    function uri(uint256 tokenId) public view virtual returns (string memory) {
        require(exists(tokenId), "ERC1155URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        return _tokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        require(exists(tokenId), "ERC1155URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        return _tokenURI;
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     * Requirements:
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        _tokenURIs[tokenId] = _tokenURI;
    }

    function mint(
        address account,
        uint256 amount,
        string memory _uri,
        string memory _unit_size,
        uint256 _conservation_time_months,
        string memory _monitoring_frequency,
        string memory _monitoring_provider,
        string memory _asset_type,
        string memory _pyt_token_type,
        string memory _total_conservation_area,
        string memory _artist_name
    )
        public
        returns (uint)
    {
        require(hasRole(PYT_ADMIN_ROLE, _msgSender()) || hasRole(LAND_OWNER_ROLE, _msgSender()), 'Access Control: You do not have the required role for this function');

        // Generating new tokenId using auto increment
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _setTokenURI(tokenId, _uri);
        _mint(account, tokenId, amount, '');

        TOKEN_DETAILS[tokenId] = TokenMetadata(
            _unit_size,
            _conservation_time_months,
            _monitoring_frequency,
            _monitoring_provider,
            _asset_type,
            _pyt_token_type,
            _total_conservation_area,
            _artist_name
        );

        return tokenId;
    }

    function pause() public {
        require(hasRole(PYT_ADMIN_ROLE, _msgSender()), 'Access Control: You do not have the required role for this function');

        _pause();
    }

    function unpause() public {
        require(hasRole(PYT_ADMIN_ROLE, _msgSender()), 'Access Control: You do not have the required role for this function');

        _unpause();
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155Upgradeable, ERC1155SupplyUpgradeable)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
