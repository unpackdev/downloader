// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Strings.sol";
import "./EnumerableSet.sol";
import "./AccessControl.sol";
import "./ERC2981.sol";
import "./ERC721BONonburnable.sol";
import "./ITokenUriProvider.sol";
import "./IDaisy.sol";

contract Daisy is ERC721BONonburnable, ERC2981, AccessControl, IDaisy {
    using Strings for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    address private _owner;
    bytes32 public constant CHANGE_ROYALTY_ROLE = keccak256("CHANGE_ROYALTY_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PROVIDER_ADMIN_ROLE = keccak256("PROVIDER_ADMIN_ROLE");
    bytes32 public constant OWNER_ADMIN_ROLE = keccak256("OWNER_ADMIN_ROLE");

    EnumerableSet.AddressSet private _uriProviders;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(string memory name,
        string memory symbol,
        uint96 feeNumerator,
        address payee,
        address defaultProvider) ERC721BO(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PROVIDER_ADMIN_ROLE, msg.sender);
        _setupRole(OWNER_ADMIN_ROLE, msg.sender);
        _setupRole(CHANGE_ROYALTY_ROLE, msg.sender);

        _setDefaultRoyalty(payee, feeNumerator);
        addUriProvider(defaultProvider);
    }

    function setDefaultRoyalty(uint96 feeNumerator, address payee) public virtual onlyRole(CHANGE_ROYALTY_ROLE) {
        _setDefaultRoyalty(payee, feeNumerator);
    }

    function changeOwnership(address newOwner) public virtual onlyRole(OWNER_ADMIN_ROLE) {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721BO, ERC2981, AccessControl, IERC165) returns (bool) {
        return interfaceId == type(IDaisy).interfaceId || super.supportsInterface(interfaceId);
    }

    function addUriProvider(address provider) public virtual onlyRole(PROVIDER_ADMIN_ROLE) {
        require(provider != address(0), "Daisy: provider is the zero address");

        uint256 providerCount = _uriProviders.length();
        if (providerCount > 0)
        {
            address p = _uriProviders.at(providerCount - 1);
            uint256 startId = ITokenUriProvider(p).startId();
            uint256 maxSupply = ITokenUriProvider(p).maxSupply();
            require(startId + maxSupply == totalMinted(), "Daisy: invalid start id");
        }

        _uriProviders.add(provider);
    }

    function uriProvider(uint256 index) public view virtual returns (address) {
        return address(uint160(_uriProviders.at(index)));
    }

    function uriProviderCount() public view virtual returns (uint256) {
        return _uriProviders.length();
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Daisy: URI query for nonexistent token");

        uint256 count;
        uint256 providerCount = _uriProviders.length();
        for (uint256 i = 0; i < providerCount; i++) {
            ITokenUriProvider provider = ITokenUriProvider(_uriProviders.at(i));
            uint256 a = count + provider.maxSupply();
            if (tokenId < a)
                return provider.tokenURI(tokenId);

            count = a;
        }

        revert("ERC721URIStorage: URI query for nonexistent token");
    }

    function safeMint(address to, uint256 count, bytes memory data) external onlyRole(MINTER_ROLE) {
        uint256 start = totalSupply();

        uint256 providerCount = _uriProviders.length();
        require(providerCount > 0, "Daisy: no uri provider");
        address provider = _uriProviders.at(providerCount - 1);
        require(provider != address(0), "Daisy: provider is the zero address");

        uint256 startId = ITokenUriProvider(provider).startId();
        uint256 maxSupply = ITokenUriProvider(provider).maxSupply();
        require(startId <= start && start + count <= startId + maxSupply, "Daisy: invalid count");

        _safeMint(to, count, data);
    }
}
