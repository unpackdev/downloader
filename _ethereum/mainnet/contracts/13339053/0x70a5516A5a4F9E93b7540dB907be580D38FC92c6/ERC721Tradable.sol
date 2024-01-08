// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title ERC721Tradable
 * ERC721Tradable - ERC721 contract that whitelists a trading address, and has minting functionality.
 */
abstract contract ERC721Tradable is ContextMixin, ERC721Enumerable, NativeMetaTransaction, Ownable {
    using SafeMath for uint256;
	
	address private nftSpecialMintAddress;
    address proxyRegistryAddress;
    uint256 private _currentTokenId = 0;
	uint256 private MAX_SUPPLY;
	string private baseMetadataURI;
	string private baseAPI;

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress,
		uint256 _MAX_SUPPLY,
		string memory _api
    ) ERC721(_name, _symbol) {
        proxyRegistryAddress = _proxyRegistryAddress;
        _initializeEIP712(_name);
		nftSpecialMintAddress = address(0);
		MAX_SUPPLY = _MAX_SUPPLY;
		baseAPI = _api;
		baseMetadataURI = "https://pygoogle-xno2aym5xq-nw.a.run.app/";
    }
	
	  /**
   * @dev Will update the base URL of token's URI
   * @param _newBaseMetadataURI New base URL of token's URI
   */
	function setBaseMetadataURI(string memory _newBaseMetadataURI) public onlyOwner {
		baseMetadataURI = _newBaseMetadataURI;
	}
	function getBaseMetadataURI() public view onlyOwner returns(string memory){
		return baseMetadataURI;
	}
	
	function setSpecialMintAddress(address _nftSpecialMintAddress) public onlyOwner{
		
		nftSpecialMintAddress = _nftSpecialMintAddress;
	
	}

	function getSpecialMintAddress() public view returns (address){	
		return nftSpecialMintAddress;
	}
	
	function factoryMintNFT(address _toAddress) public {
		require(msg.sender == nftSpecialMintAddress, "Wrong address used, use the factory one");
		require(_currentTokenId < MAX_SUPPLY, "No tokens left to mint :("); //_currentTokenId + 1 <= MAX_SUPPLY
        
		uint256 newTokenId = _getNextTokenId();
        _mint(_toAddress, newTokenId);
        _incrementTokenId();
		
    }
    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     */
    function mintTo(address _to) public onlyOwner {
	
		require(_currentTokenId < MAX_SUPPLY, "No tokens left to mint :(");
	
        uint256 newTokenId = _getNextTokenId();
        _mint(_to, newTokenId);
        _incrementTokenId();
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

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseMetadataURI,baseAPI, Strings.toString(_tokenId)));
    }
	function contractURI() public view returns (string memory) {
		return string(abi.encodePacked(baseMetadataURI, "contract/", super.name()));
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

