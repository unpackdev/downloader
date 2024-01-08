// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./Strings.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract SimU is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdTracker;
    address private _proxyRegistryAddress;
    string private _sharedBaseURI;
    bool private _licenseChecksumLocked;
    bool private _metadataURILocked;
    bool private _delegateMinterRequired;
    // Allows more options on how metadata URI can be stored. Overrides default
    // baseURI based approach.
    mapping(uint256 => string) private _tokenMetadataURI;
    mapping(address => bool) private _delegates;

    string public metadataChecksum;
    string public license;
    uint256 public mintReserve;

    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
    {
        _sharedBaseURI = "https://www.simulateduniversenft.com/api/metadata/";
        metadataChecksum = "e0821490b282d7d1666b96f60b6fcbb31942f238c7098d4490e7c9fb111e0c9788d29ad84912f702aea48f6d928e557a1ecbf9ddfdf5c5f9ffd65ea58fb3b042";
        license = "As long as you hold the NFT, you are granted MIT license to the universe' metadata in its entirety.";
        _licenseChecksumLocked = false;
        _metadataURILocked = false;
        // Start with 1.
        _tokenIdTracker.increment();
        _delegateMinterRequired = true;
        mintReserve = 1000;
    }

    /**
     * @dev Premenately locks license and checksum updates.
     */
    function lockLicenseAndChecksum() external onlyOwner {
        _licenseChecksumLocked = true;
        emit LicenseAndChecksumLocked();
    }

    /**
     * @dev Permenantely locks metadataURI.
     */
    function lockMetadataURI() external onlyOwner {
        _metadataURILocked = true;
        emit MetadataURILocked();
    }

    /**
     * @dev Whether delegate role is required to mint.
     */
    function updateDelegateMinterRequired(bool required) external onlyOwner {
        _delegateMinterRequired = required;
    }

    /**
     * @dev Update the reserve allocation.
     */
    function updateMintReserve(uint256 reserve) external onlyOwner {
        mintReserve = reserve;
    }

    /**
     * @dev Override baseURI based metadata URI.
     */
    function updateMetadataURI(uint256 tokenId, string memory metadataURI)
        external
    {
        require(_delegates[_msgSender()] == true, "Not authorized");
        require(_metadataURILocked == false, "Operation locked");
        _tokenMetadataURI[tokenId] = metadataURI;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function updateBaseURI(string memory baseURI) external onlyOwner {
        require(_metadataURILocked == false, "Operation locked");
        _sharedBaseURI = baseURI;
    }

    /**
     * @dev Allows license polishing until functionaly is locked up.
     */
    function updateLicense(string memory theLicense) external onlyOwner {
        require(_licenseChecksumLocked == false, "Operation locked");
        license = theLicense;
    }

    /**
     * @dev Allows bug fixing until the functionality is locked up.
     */
    function updateMetadataSha512(string memory checksum) external onlyOwner {
        require(_licenseChecksumLocked == false, "Operation locked");
        metadataChecksum = checksum;
    }

    /**
     * @dev Add a delegate.
     */
    function addDelegate(address delegate) external onlyOwner {
        require(delegate != address(0), "0 address not allowed");
        _delegates[delegate] = true;
    }

    /**
     * @dev Remove a delegate.
     */
    function removeDelegate(address delegate) external onlyOwner {
        delete _delegates[delegate];
    }

    /**
     * @dev Update proxy registry address.
     */
    function updateProxyRegisteryAddress(address anAddress) external onlyOwner {
        _proxyRegistryAddress = anAddress;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");

        if (bytes(_tokenMetadataURI[tokenId]).length > 0) {
            return _tokenMetadataURI[tokenId];
        }
        return
            bytes(_sharedBaseURI).length > 0
                ? string(abi.encodePacked(_sharedBaseURI, tokenId.toString()))
                : "";
    }

    function mint(address toAddress) external {
        if (_delegateMinterRequired) {
            require(_delegates[_msgSender()] == true, "Not authorized");
        }
        require(totalSupply() < 10000 - mintReserve, "Mint cap reached");

        _mint(toAddress, _tokenIdTracker.current());
        _tokenIdTracker.increment();
    }

    /**
     * @dev Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        if (_proxyRegistryAddress != address(0)) {
            ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
            if (address(proxyRegistry.proxies(owner)) == operator) {
                return true;
            }
        }

        return super.isApprovedForAll(owner, operator);
    }

    event LicenseAndChecksumLocked();
    event MetadataURILocked();
}
