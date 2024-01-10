// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./SafeMath.sol";

import "./ERC721A.sol";
import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";

contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract YakuzaKumiai is ERC721A, ContextMixin, NativeMetaTransaction, Ownable {
    using SafeMath for uint256;
    address proxyRegistryAddress;

    string private baseTokenURI_;

    constructor(
        address _proxyRegistryAddress,
        string memory _baseTokenURI
    ) ERC721A("YakuzaKumiai", "YK") {
        proxyRegistryAddress = _proxyRegistryAddress;
        _initializeEIP712("YakuzaKumiai");
        baseTokenURI_ = _baseTokenURI;
    }

    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     * @param count the count of token to mint
     */
    function mintTo(address _to, uint256 count) public onlyOwner {
        _safeMint(_to, count);
    }

    function baseTokenURI() virtual public view returns (string memory) {
        return baseTokenURI_;
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI_ = _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId)));
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }
}
