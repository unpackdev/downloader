// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

import "./ERC721Upgradeable.sol";

import "./EIP712MetaTxUpgradeable.sol";
import "./OpenseaProxyRegistry.sol";

/**
 * @title OpenseaERC721Upgradeable
 * @dev ERC721 contract that whitelists a trading address, and has minting functionality.
 *      Refer to https://github.com/ProjectOpenSea/opensea-creatures/blob/master/contracts/ERC721Tradable.sol
 */
contract OpenseaERC721Upgradeable is ERC721Upgradeable, EIP712MetaTxUpgradeable {

    address public proxyRegistryAddress;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __OpenseaERC721_init_unchained(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) internal initializer {
		__ERC721_init(_name, _symbol);
        __EIP712MetaTx_init_unchained(_name, "1");
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address tokenOwner, address operator) override public view returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        if (proxyRegistryAddress != address(0)) {
            OpenseaProxyRegistry proxyRegistry = OpenseaProxyRegistry(proxyRegistryAddress);
            if (address(proxyRegistry.proxies(tokenOwner)) == operator) {
                return true;
            }
        }

        return super.isApprovedForAll(tokenOwner, operator);
    }

    uint256[49] private __gap;
}
