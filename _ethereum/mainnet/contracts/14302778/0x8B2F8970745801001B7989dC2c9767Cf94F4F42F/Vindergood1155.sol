// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma abicoder v2;

import "./ERC1155Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC1155.sol";
import "./SafeMath.sol";
import "./Strings.sol";

import "./LibPart.sol";
import "./RoyaltiesV2Impl.sol";
import "./Store.sol";

/**
 * @title ERC1155Tradable
 * ERC1155Tradable - ERC1155 contract that whitelists a trading address, and has minting functionality.
 */
contract Vindergood1155 is
    RoyaltiesV2Impl,
    ERC1155Upgradeable,
    OwnableUpgradeable
{
    using SafeMath for uint256;

    address public exchangeAddress;
    address public proxyRegistryAddress;
    uint256 private _currentTokenId = 0;
    string private _extendedTokenURI;

    function initialize(
        string memory _tokenURI,
        address _proxyRegistryAddress,
        address _exchangeAddress
    ) external initializer {
        __Ownable_init();
        __ERC1155_init(_tokenURI);
        proxyRegistryAddress = _proxyRegistryAddress;
        _extendedTokenURI = _tokenURI;
        exchangeAddress = _exchangeAddress;

        transferOwnership(tx.origin);
    }

    function mintTo(
        address _to,
        uint256 amount,
        bytes memory data,
        LibPart.Part memory _royalty
    ) public returns (uint256) {
        require(
            ProxyRegistry(proxyRegistryAddress).contracts(_msgSender()) ||
                _msgSender() == owner(),
            "ERC1155Tradable::sender is not owner or approved!"
        );
        uint256 newTokenId = _getNextTokenId();

        _mint(_to, newTokenId, amount, data);
        _saveRoyalties(newTokenId, _royalty);
        _incrementTokenId();
        return newTokenId;
    }

    function transfer(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 amount,
        bytes memory data
    ) external returns (uint256) {
        if (balanceOf(_from, _tokenId) > 0) {
            require(
                isApprovedForAll(_from, _msgSender()),
                "ERC1155Tradable::sender is not approved!"
            );
            safeTransferFrom(_from, _to, _tokenId, amount, data);
        }

        return _tokenId;
    }

    /**
     * @dev calculates the next token ID based on value of _currentTokenId
     * @return uint256 for the next token ID
     */
    function _getNextTokenId() private view returns (uint256) {
        return _currentTokenId.add(1);
    }

    /**
     * @dev increments the value of _currentTokenId
     */
    function _incrementTokenId() private {
        _currentTokenId++;
    }

    function baseTokenURI() public view virtual returns (string memory) {
        return _extendedTokenURI;
    }

    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        return
            string(
                abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId))
            );
    }

    function modifyExtendedURI(string memory extendedTokenURI_)
        external
        onlyOwner
    {
        _extendedTokenURI = extendedTokenURI_;
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
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }
}
