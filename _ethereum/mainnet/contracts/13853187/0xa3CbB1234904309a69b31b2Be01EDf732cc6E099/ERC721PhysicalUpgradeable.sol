// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Upgradeable.sol";
import "./Initializable.sol";

/**
 * @dev ERC721 upgradeable token linked to a physical asset,
 */
abstract contract ERC721PhysicalUpgradeable is Initializable, ERC721Upgradeable {
    function __ERC721Physical_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721Physical_init_unchained();
    }

    function __ERC721Physical_init_unchained() internal initializer {
    }
    using StringsUpgradeable for uint256;    

    // Struct for minimum device information. String vars in struct are legacy and only for backwards compatibility.
    struct Device { 
       string publicKeyHash;
       string merkleRoot;
       bytes32 publicKeyHashBytes;
       bytes32 merkleRootBytes;
    }

    // The device registry.
    address public _registryAddress;

    // Optional mapping for device IDs and and device roots.
    mapping(uint256 => Device) private _devices;

    event UpdateRegistry(address registryAddress);
    event DeviceSet(
        uint256 tokenId,
        bytes32 publicKeyHash,
        bytes32 merkleRoot
    );

    /**
     * @dev Get a deviceId for a given tokenId.
     */
    function deviceId(uint256 tokenId) public view virtual returns(bytes32) {
        require(_exists(tokenId), "Device ID query for nonexistant token");

        bytes32 _deviceId = _devices[tokenId].publicKeyHashBytes;
        return _deviceId;
    }

    /**
     * @dev Get a deviceRoot for a given tokenId.
     */
    function deviceRoot(uint256 tokenId) public view virtual returns(bytes32) {
        require(_exists(tokenId), "Device root query for nonexistant token");

        bytes32 _deviceRoot = _devices[tokenId].merkleRootBytes;
        return _deviceRoot;
    }

    /**
     * @dev Optional: Get a tokenId for a given publicKeyHash.
     */
    function tokenByDevice(bytes32 publicKeyHash) public view virtual returns(uint256) {
        require(_exists(_tokensWithDevices[publicKeyHash]), "Token query for nonexistant device");

        uint256 tokenId = _tokensWithDevices[publicKeyHash];
        return tokenId;
    }

    /**
     * @dev Set token-wide registry address.
     */
    function _setRegistryAddress(address registryAddress) internal virtual {
         _registryAddress = registryAddress;
        emit UpdateRegistry(_registryAddress);
    }

    /**
     * @dev Set a deviceRoot for a given tokenId.
     */
    function _setDevice(uint256 tokenId, bytes32 publicKeyHash, bytes32 merkleRoot) internal virtual {
        require(_exists(tokenId), "Device set called for nonexistant token");
        require(_tokensWithDevices[publicKeyHash] == 0 || _tokensWithDevices[publicKeyHash] == tokenId, "Device already set for another token");
        _devices[tokenId].publicKeyHashBytes = publicKeyHash;
        _devices[tokenId].merkleRootBytes = merkleRoot;
        _tokensWithDevices[publicKeyHash] = tokenId;
        emit DeviceSet(tokenId, publicKeyHash, merkleRoot);
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (_devices[tokenId].publicKeyHashBytes.length != 0) {
            delete _devices[tokenId];
            delete _tokensWithDevices[_devices[tokenId].publicKeyHashBytes];
        }
    }
    // Verify gap?
    uint256[46] private __gap;

    // Optional mapping from token ID to device publicKeyHashes
    mapping(bytes32 => uint256) private _tokensWithDevices;    
}