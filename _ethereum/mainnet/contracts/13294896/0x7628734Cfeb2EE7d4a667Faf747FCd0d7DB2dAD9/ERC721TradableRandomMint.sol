// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";
import "./ProxyRegistry.sol";


/**
 * @title ERC721TradableRandomMint
 * ERC721TradableRandomMint - ERC721 contract that whitelists a trading address, and has minting functionality.
 * and also has random minting functionality (VRAgent/VRPunk addition)
 */
abstract contract ERC721TradableRandomMint is ContextMixin, ERC721Enumerable, NativeMetaTransaction, Ownable {
    using SafeMath for uint256;

    address proxyRegistryAddress;

    string public baseURI;

    /**
     * @dev This is the mapping we randomly pick from. In case it is 0 it means use the index number instead.
     *      when a token is picked we take the last index and move it to the front.
     */
    mapping (uint16 => uint16) tokenPickMapping;
    uint16 tokensAvailable = 10000;

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) ERC721(_name, _symbol) {
        proxyRegistryAddress = _proxyRegistryAddress;
        _initializeEIP712(_name);
    }

    /**
     * @dev generates a random uint16 number based on block info
     */
    function randomUint16() internal view returns (uint16) {
        bytes32 randomHash = keccak256(
            abi.encode(
                block.timestamp,
                block.difficulty,
                block.coinbase,
                tx.origin
            )
        );
        return uint16(uint256(randomHash) % (type(uint16).max));
    }

    /**
     * @dev Mints a random token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     */
    function mintTo(address _to) public onlyOwner {
        require(tokensAvailable > 0, "No more tokens available.");
        uint16 randomPick = randomUint16() % tokensAvailable;
        uint16 pickedRandomToken = tokenPickMapping[randomPick];
        if (pickedRandomToken == 0) {
            pickedRandomToken = randomPick + 1;
        }
        
        // Lets mint the randomly picked token:
        uint16 newTokenId = pickedRandomToken - 1;
        _mint(_to, newTokenId);
        
        // after successfully minting we can update the tokenPickMapping
        tokensAvailable--;

        uint16 lastToken = tokenPickMapping[tokensAvailable];
        if (lastToken == 0) {
            lastToken = tokensAvailable + 1;
        }
        tokenPickMapping[randomPick] = lastToken;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
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