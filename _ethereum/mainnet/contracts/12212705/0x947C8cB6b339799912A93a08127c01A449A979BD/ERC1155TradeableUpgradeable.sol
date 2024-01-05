// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "./OwnableUpgradeable.sol";
import "./ERC1155Upgradeable.sol";
import "./StringsLib.sol";
import "./IProxyRegistry.sol";
import "./MinterRoleUpgradeable.sol";
import "./WhitelistAdminRoleUpgradeable.sol";
import "./ListsLib.sol";

/**
 * @title ERC1155Tradeable
 * ERC1155Tradable - ERC1155 contract that whitelists an operator address, 
 * has create and mint functionality, and supports useful standards from OpenZeppelin,
  like _exists(), name(), symbol(), and totalSupply()
 */
contract ERC1155TradeableUpgradeable is ERC1155Upgradeable, OwnableUpgradeable, MinterRoleUpgradeable, WhitelistAdminRoleUpgradeable {
	using ListsLib for uint256[];

	address proxyRegistryAddress;
	uint256 private _currentTokenID;
	
	mapping(uint256 => address) public creators;
	mapping(uint256 => uint256) public tokenSupply;
	mapping(uint256 => uint256) public tokenMaxSupply;
	struct URIRecord {
          bool exists;
	  string uri;
	}
	mapping (uint256 => URIRecord) internal _uriRecords;
  
	// Contract name
	string public name;
	// Contract symbol
	string public symbol;
	string private _baseURI;

	function __ERC1155Tradeable_init_unchained(
		string memory _name,
		string memory _symbol,
		address _proxyRegistryAddress
	) internal {
		name = _name;
		symbol = _symbol;
		proxyRegistryAddress = _proxyRegistryAddress;
		__MinterRole_init_unchained();
		__WhitelistAdminRole_init_unchained();
		__Ownable_init_unchained();
		__ERC1155_init_unchained("");
	}

	function __ERC1155Tradeable_init(string memory _name, string memory _symbol, address _proxyRegistryAddress) internal initializer {
        	__ERC1155Tradeable_init_unchained(_name, _symbol, _proxyRegistryAddress);
	}

	function _setBaseURI(string memory _base) internal virtual {
          _baseURI = _base;
	}

	function setBaseURI(string memory _base) public onlyOwner {
          _setBaseURI(_base);
	}

	function removeWhitelistAdmin(address /* account */) public view onlyOwner {
            revert("unsupported");
	}

	function removeMinter(address /* account */) public view onlyOwner {
	    revert("unsupported");
	}

	function addMinter(address /* account */) public view override onlyOwner {
	    revert("unsupported");
	}

	function uri(uint256 _id) public view override returns (string memory) {
		require(_exists(_id), "ERC721Tradeable#uri: NONEXISTENT_TOKEN");
		if (_uriRecords[_id].exists) return _uriRecords[_id].uri;
		return StringsLib.strConcat(_baseURI, StringsLib.toString(_id));
	}
	function setURI(uint256 _id, string memory _uri) public onlyOwner {
          require(_exists(_id), "ERC721Tradeable#uri: NONEXISTENT_TOKEN");
	  _uriRecords[_id] = URIRecord({
	    exists: true,
	    uri: _uri
	  });
	}

	/**
	 * @dev Returns the total quantity for a token ID
	 * @param _id uint256 ID of the token to query
	 * @return amount of token in existence
	 */
	function totalSupply(uint256 _id) public view returns (uint256) {
		return tokenSupply[_id];
	}

	/**
	 * @dev Returns the max quantity for a token ID
	 * @param _id uint256 ID of the token to query
	 * @return amount of token in existence
	 */
	function maxSupply(uint256 _id) public view returns (uint256) {
		return tokenMaxSupply[_id];
	}

	/**
	 * @dev Will update the base URL of token's URI
	 * @param _newBaseMetadataURI New base URL of token's URI
	 */
	function setBaseMetadataURI(string memory _newBaseMetadataURI) public onlyWhitelistAdmin {
		_setURI(_newBaseMetadataURI);
	}

	/**
	 * @dev Creates a new token type and assigns _initialSupply to an address
	 * @param _targets addresses to receive NFTs
	 * @param _amounts amounts to receive NFTs for respective address in _targets
	 * @param _maxSupply max supply allowed
	 * @param _uri Optional URI for this token type
	 * @param _data Optional data to pass if receiver is contract
	 * @return tokenId The newly created token ID
	 */
	function create(
		address[] memory _targets,
		uint256[] memory _amounts,
		uint256 _maxSupply,
		string memory _uri,
		bytes memory _data
	) external onlyWhitelistAdmin returns (uint256 tokenId) {
		uint256 _initialSupply = _amounts.sum();
		require(_initialSupply <= _maxSupply, "Initial supply cannot be more than max supply");

		uint256 _id = _getNextTokenID();
		_incrementTokenTypeId();

		creators[_id] = msg.sender;
		if (bytes(_uri).length > 0) {
			_uriRecords[_id] = URIRecord({
		          exists: true,
			  uri: _uri
			});
		}

		if (_initialSupply != 0) {
	          require(_targets.length == _amounts.length, "targets list must have same length as amounts list");
		  for (uint256 i = 0; i < _targets.length; i++) {
		    _mint(_targets[i], _id, _amounts[i], _data);
		  }
		}
		tokenSupply[_id] = _initialSupply;
		tokenMaxSupply[_id] = _maxSupply;
	        emit URI(uri(_id), _id);
		return _id;
	}

	function getCurrentTokenID() public view returns (uint256) {
		return _currentTokenID;
	}

	/**
	 * @dev Mints some amount of tokens to an address
	 * @param _to          Address of the future owner of the token
	 * @param _id          Token ID to mint
	 * @param _quantity    Amount of tokens to mint
	 * @param _data        Data to pass if receiver is contract
	 */
	function mint(
		address _to,
		uint256 _id,
		uint256 _quantity,
		bytes memory _data
	) public onlyMinter {
		uint256 tokenId = _id;

		require(tokenSupply[tokenId].add(_quantity) <= tokenMaxSupply[tokenId], "Max supply reached");
		_mint(_to, _id, _quantity, _data);
		tokenSupply[_id] = tokenSupply[_id].add(_quantity);
	}

	/**
	 * @dev Burns some amount of tokens to an address
	 * @param _from          Address of the future owner of the token
	 * @param _id          Token ID to mint
	 * @param _quantity    Amount of tokens to mint
	 */
	function burn(
		address _from,
		uint256 _id,
		uint256 _quantity
	) public onlyMinter {
		uint256 tokenId = _id;
		require(tokenSupply[tokenId] > 0, "No token exists");
		_burn(_from, _id, _quantity);
		tokenSupply[_id] = tokenSupply[_id].sub(_quantity);
	}

	/**
	 * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings.
	 */
	function isApprovedForAll(address _owner, address _operator) public view override returns (bool isOperator) {
		// Whitelist OpenSea proxy contract for easy trading.
		IProxyRegistry proxyRegistry = IProxyRegistry(proxyRegistryAddress);
		if (proxyRegistry.proxies(_owner) == _operator) {
			return true;
		}

		return ERC1155Upgradeable.isApprovedForAll(_owner, _operator);
	}

	/**
	 * @dev Returns whether the specified token exists by checking to see if it has a creator
	 * @param _id uint256 ID of the token to query the existence of
	 * @return bool whether the token exists
	 */
	function _exists(uint256 _id) public view returns (bool) {
		return creators[_id] != address(0);
	}

	/**
	 * @dev calculates the next token ID based on value of _currentTokenID
	 * @return uint256 for the next token ID
	 */
	function _getNextTokenID() private view returns (uint256) {
		return _currentTokenID.add(1);
	}

	/**
	 * @dev increments the value of _currentTokenID
	 */
	function _incrementTokenTypeId() private {
		_currentTokenID ++;
	}
}
