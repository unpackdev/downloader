// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./SafeMath.sol";

import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";

contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title SWAGverseERC721
 * SWAGverseERC721 - ERC721 contract that whitelists a trading address, and has minting functionality.
 */
contract SWAGverseERC721 is ERC721, ContextMixin, NativeMetaTransaction, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    /**
     * We rely on the OZ Counter util to keep track of the next available ID.
     * We track the nextTokenId instead of the currentTokenId to save users on gas costs. 
     * Read more about it here: https://shiny.mirror.xyz/OUampBbIz9ebEicfGnQf5At_ReMHlZy0tB4glb9xQ0E
     */ 
    Counters.Counter private _nextTokenId;
    address proxyRegistryAddress;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    mapping(address => bool) private _minters;

    string private _contractURI;
    string private _baseTokenURI;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory contractURI_,
        string memory baseTokenURI_,
        address _proxyRegistryAddress
    ) ERC721(_name, _symbol) {
        _contractURI = contractURI_;
        _baseTokenURI = baseTokenURI_;
        _minters[msgSender()] = true;

        proxyRegistryAddress = _proxyRegistryAddress;
        // nextTokenId is initialized to 1, since starting at 0 leads to higher gas cost for the first minter
        _nextTokenId.increment();
        _initializeEIP712(_name);
    }

    /**
    * returns uri of metadata for this contract
    * see: https://docs.opensea.io/docs/contract-level-metadata
    */
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /**
        @dev Returns the total tokens minted so far.
        1 is always subtracted from the Counter since it tracks the next available tokenId.
     */
    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current() - 1;
    }

    function baseTokenURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    function canMint(address operator) public view returns (bool) {
        return _minters[operator];
    }

    /**
    * returns uri of metadata for given token
    * see: https://docs.opensea.io/docs/metadata-standards
    */
    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        require(_exists(_tokenId), "SWAGverseERC721: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[_tokenId];
        
        // If _tokenURI presents, returns it.
        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }

        // returns `{baseTokenURI()}/{_tokenId}`
        return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId)));
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator) override public view returns (bool)
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
    function _msgSender() internal override view returns (address sender)
    {
        return ContextMixin.msgSender();
    }

    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     */
    function mintTo(address _to) public {
        require(canMint(msgSender()), "Caller is not minter");
        uint256 currentTokenId = _nextTokenId.current();
        _nextTokenId.increment();
        _safeMint(_to, currentTokenId);
    }

    // ***** Owner only interfaces starts from here ***** 

    function setMinter(address operator, bool _canMint) public onlyOwner {
        _minters[operator] = _canMint;
    }

    function setContractURI(string calldata newContractURI) public onlyOwner {
        _contractURI = newContractURI;
    }

    function setBaseTokenURI(string calldata baseTokenURI_) public onlyOwner {
        _baseTokenURI = baseTokenURI_;
    }
    
    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOwner {
        require(_exists(tokenId), "SWAGverseERC721: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }
}
