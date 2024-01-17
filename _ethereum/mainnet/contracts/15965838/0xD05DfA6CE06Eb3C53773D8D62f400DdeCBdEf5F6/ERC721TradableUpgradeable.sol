// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
import "./ERC721EnumerableUpgradeable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";
import "./IOperator.sol";
import "./TimelockAccess.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title ERC721Tradable
 * ERC721Tradable - ERC721 contract that whitelists a trading address, and has minting functionality.
 */
abstract contract ERC721TradableUpgradeable is
    ContextMixin,
    ERC721EnumerableUpgradeable,
    NativeMetaTransaction,
    TimelockAccess,
    IOperator
{
    using SafeMath for uint256;

    function getProxyRegistryAddress() public virtual view returns (address);

    function burn(uint256 tokenId) external virtual {
        require(
            msg.sender == ownerOf(tokenId),
            "Caller is not owner of token id"
        );
        super._burn(tokenId);
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(getProxyRegistryAddress());
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function addOperator(address _operator) external override onlyTimelock {
        _addOperator(_operator);
    }

    function removeOperator(address _operator) external override onlyTimelock {
        _removeOperator(_operator);
    }
}
