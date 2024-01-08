// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.5.12 <0.9.0;

import "./ERC1155.sol";
import "./ERC1155MintBurn.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./IERC1155Metadata.sol";

contract OwnableDelegateProxy { }

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title ERC1155Tradable
 * ERC1155Tradable - ERC1155 contract that whitelists an operator address, has create and mint functionality, and supports useful standards from OpenZeppelin,
  like _exists(), name(), symbol(), and totalSupply()
 */
contract ERC1155Tradable is ERC1155, ERC1155MintBurn, IERC1155Metadata, Ownable {
  event CreatorChanged(uint256 id, address newCreator, address oldCreator);
  using Strings for string;

  address[] _proxyRegistries;
  uint256 private _currentTokenID = 0;
  mapping (uint256 => address) public creators;
  mapping (uint256 => uint256) public tokenSupply;
  mapping (uint256 => string) public uris;

  string public name;
  string public symbol;

  /**
   * @dev Require msg.sender to be the creator of the token id
   */
  modifier creatorOnly(uint256 _id) {
    require(creators[_id] == msg.sender, "ERC1155Tradable#creatorOnly: ONLY_CREATOR_ALLOWED");
    _;
  }

  /**
   * @dev Require msg.sender to own more than 0 of the token id
   */
  modifier ownersOnly(uint256 _id) {
    require(balances[msg.sender][_id] > 0, "ERC1155Tradable#ownersOnly: ONLY_OWNERS_ALLOWED");
    _;
  }

  constructor(
    string memory _name,
    string memory _symbol,
    address[] memory proxyRegistries_
  ) {
    name = _name;
    symbol = _symbol;
    for(uint8 i = 0; i < proxyRegistries_.length; i++) {
      _proxyRegistries.push(proxyRegistries_[i]);
    }
  }

  /**
    * @dev Returns the total quantity for a token ID
    * @param _id uint256 ID of the token to query
    * @return amount of token in existence
    */
  function totalSupply(
    uint256 _id
  ) public view returns (uint256) {
    return tokenSupply[_id];
  }

  /**
   * @dev Returns the uri of the token
   * @param id_ Id of the token to query
   * @return URI of the token
   */
  function uri(uint256 id_) public view override returns (string memory) {
    return uris[id_];
  }

  /**
   * @dev Will add a Proxy Registry address
   * @param _proxyRegistry New Proxy Registry address
   */
  function addProxyRegistry(
    address _proxyRegistry
  ) external onlyOwner {
    require(_proxyRegistries.length < 256, "ERC1155Tradable#addProxyRegistry: MAX_NUMBER_OF_PROXIES_REACHED");
    _proxyRegistries.push(_proxyRegistry);
  }

  /**
   * @dev Will remove a Proxy Registry address
   * @param _proxyRegistry Proxy Registry address to remove
   */
  function removeProxyRegistry(
    address _proxyRegistry
  ) external onlyOwner {
    for(uint8 i=0; i< _proxyRegistries.length; i++) {
      if(_proxyRegistries[i] == _proxyRegistry) {
        delete _proxyRegistries[i];
        _proxyRegistries[i] = _proxyRegistries[_proxyRegistries.length - 1];
        delete _proxyRegistries[_proxyRegistries.length - 1];
      }
    }
  }

  /**
   * @dev Will change a Proxy Registry address
   * @param _proxyRegistry Proxy Registry address to swap with
   * @param _index Proxy Registry index to swap
   */
  function swapProxyRegistry(
    address _proxyRegistry,
    uint8 _index
  ) external onlyOwner {
    _proxyRegistries[_index] = _proxyRegistry;
  }

  /**
   * @dev Returns the registered proxy registries
   */
  function proxyRegistries() public view returns(address[] memory) {
    return _proxyRegistries;
  }

  /**
    * @dev Creates a new token type and assigns _initialSupply to an address
    * @param _initialOwner address of the first owner of the token
    * @param _initialSupply amount to supply the first owner
    * @param _uri URI for this token type
    * @param _data Data to pass if receiver is contract
    * @return The newly created token ID
    */
  function create(
    address _initialOwner,
    uint256 _initialSupply,
    string calldata _uri,
    bytes calldata _data
  ) external returns (uint256) {

    uint256 _id = _getNextTokenID();
    _incrementTokenTypeId();

    uris[_id] = _uri;
    creators[_id] = msg.sender;

    _mint(_initialOwner, _id, _initialSupply, _data);

    tokenSupply[_id] = _initialSupply;

    return _id;
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
  ) public creatorOnly(_id) {
    _mint(_to, _id, _quantity, _data);
    tokenSupply[_id] = tokenSupply[_id] + _quantity;
  }

  /**
    * @dev Mint tokens for each id in _ids
    * @param _to          The address to mint tokens to
    * @param _ids         Array of ids to mint
    * @param _quantities  Array of amounts of tokens to mint per id
    * @param _data        Data to pass if receiver is contract
    */
  function batchMint(
    address _to,
    uint256[] memory _ids,
    uint256[] memory _quantities,
    bytes memory _data
  ) public {
    for (uint256 i = 0; i < _ids.length; i++) {
      uint256 _id = _ids[i];
      require(creators[_id] == msg.sender, "ERC1155Tradable#batchMint: ONLY_CREATOR_ALLOWED");
      uint256 quantity = _quantities[i];
      tokenSupply[_id] = tokenSupply[_id] + quantity;
    }
    _batchMint(_to, _ids, _quantities, _data);
  }

  /**
    * @dev Change the creator address for given tokens
    * @param _to   Address of the new creator
    * @param _ids  Array of Token IDs to change creator
    */
  function setCreator(
    address _to,
    uint256[] memory _ids
  ) public {
    require(_to != address(0), "ERC1155Tradable#setCreator: INVALID_ADDRESS.");
    for (uint256 i = 0; i < _ids.length; i++) {
      uint256 id = _ids[i];
      _setCreator(_to, id);
    }
  }

  /**
   * Override isApprovedForAll to whitelist user's proxies accounts to enable gas-free listings.
   */
  function isApprovedForAll(
    address _owner,
    address _operator
  ) public view virtual override returns (bool isOperator) {
    // Whitelist proxy contracts for easy trading.
    for(uint8 i=0; i< _proxyRegistries.length; i++) {
      ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistries[i]);
      if (address(proxyRegistry.proxies(_owner)) == _operator) {
        return true;
      }
    }

    return super.isApprovedForAll(_owner, _operator);
  }

  /**
    * @dev Returns the creator of a token
    * @param id_ Id of the token to query
    * @return The creator's address
   */
  function creator(uint256 id_) public view returns(address){
    return creators[id_];
  }

  /**
    * @dev Change the creator address for given token
    * @param _to   Address of the new creator
    * @param _id  Token IDs to change creator of
    */
  function _setCreator(address _to, uint256 _id) internal creatorOnly(_id)
  {
    emit CreatorChanged(_id, _to, creators[_id]);
    creators[_id] = _to;
  }

  /**
    * @dev Returns whether the specified token exists by checking to see if it has a creator
    * @param _id uint256 ID of the token to query the existence of
    * @return bool whether the token exists
    */
  function _exists(
    uint256 _id
  ) internal view returns (bool) {
    return creators[_id] != address(0);
  }

  /**
    * @dev calculates the next token ID based on value of _currentTokenID
    * @return uint256 for the next token ID
    */
  function _getNextTokenID() private view returns (uint256) {
    return _currentTokenID + 1;
  }

  /**
    * @dev increments the value of _currentTokenID
    */
  function _incrementTokenTypeId() private  {
    _currentTokenID++;
  }
}
