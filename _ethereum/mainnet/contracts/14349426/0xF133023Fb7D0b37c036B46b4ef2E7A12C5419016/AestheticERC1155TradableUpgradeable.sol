// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155Upgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ERC1155BurnableUpgradeable.sol";
import "./ERC1155SupplyUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./AestheticERC1155Upgradeable.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract AestheticERC1155TradableUpgradeable is AestheticERC1155Upgradeable {

    address proxyRegistryAddress;

    // /// @custom:oz-upgrades-unsafe-allow constructor
    // constructor() initializer {}

    function initialize(
      address _proxyRegistryAddress,
      string memory _baseTokenURI,
      string memory _name,
      string memory _symbol,
      string memory _contractURI
    ) initializer public {
        __AestheticERC1155Upgradeable_init(_baseTokenURI, _name, _symbol, _contractURI);

        proxyRegistryAddress = _proxyRegistryAddress;
    }

    /**
    * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings.
    */
    function isApprovedForAll(address _owner, address _operator) public view override returns (bool isOperator) {
        if(proxyRegistryAddress != address(0)) {
            // Whitelist OpenSea proxy contract for easy trading.
            ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
            if (address(proxyRegistry.proxies(_owner)) == _operator) {
                return true;
            }
        }
        return ERC1155Upgradeable.isApprovedForAll(_owner, _operator);
    }

    uint256[49] private __gap;
}
