// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./Pausable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./AccessControl.sol";

import "./ContextMixin.sol";
import "./NativeMetaTransaction.sol";

contract OwnableDelegateProxy { }

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title ERC1155Tradable
 * ERC1155Tradable - ERC1155 contract that whitelists an operator address, has create and mint functionality, and supports useful standards from OpenZeppelin,
  like _exists(), name(), symbol(), and totalSupply().
 * @custom:a Heirloom Artefacts - A fungibility-agnostic NFT contract for Secondary collection of 32 weapons, initially devised to compensate minters of the Cypherverse
 * @author The Cypherverse Ltd
 */
contract ERC1155Tradable is ContextMixin, NativeMetaTransaction, Ownable, ERC1155, Pausable, AccessControl {
  using Strings for string;
  using SafeMath for uint256;
  // Constant for Minter Role
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  address proxyRegistryAddress;
  mapping (uint256 => address) public creators;
  mapping (uint256 => uint256) public tokenSupply;
  mapping (uint256 => string) customUri;
  // Contract name
  string public name;
  // Contract symbol
  string public symbol;

  /**
   * @dev Require _msgSender() to be the creator of the token id
   */
  modifier creatorOnly(uint256 _id) {
    require(creators[_id] == _msgSender(), "ERC1155Tradable#creatorOnly: ONLY_CREATOR_ALLOWED");
    _;
  }

  /**
   * @dev Require _msgSender() to own more than 0 of the token id
   */
  modifier ownersOnly(uint256 _id) {
    require(balanceOf(_msgSender(), _id) > 0, "ERC1155Tradable#ownersOnly: ONLY_OWNERS_ALLOWED");
    _;
  }

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _uri,
    address _proxyRegistryAddress,
    address _minterRoleAddress
  ) ERC1155(_uri) {
      name = _name;
      symbol = _symbol;
      proxyRegistryAddress = _proxyRegistryAddress;
      _initializeEIP712(name);
      _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
      _setupRole(MINTER_ROLE, _minterRoleAddress);
  }

  /**
  * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
  */
  function _msgSender() internal view override returns (address sender) {
	return ContextMixin.msgSender();
  }

  function uri(uint256 _id) public view override returns (string memory) {
    require(_exists(_id), "ERC1155Tradable#uri: NONEXISTENT_TOKEN");
    // We have to convert string to bytes to check for existence
    bytes memory customUriBytes = bytes(customUri[_id]);
    if (customUriBytes.length > 0) {
        return customUri[_id];
    } else {
        return super.uri(_id);
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
   * @dev Sets a new URI for all token types, by relying on the token type ID
    * substitution mechanism
    * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
   * @param _newURI New URI for all tokens
   */
  function setURI(
    string memory _newURI
  ) public onlyOwner {
    _setURI(_newURI);
  }

  /**
   * @dev Will update the base URI for the token
   * @param _tokenId The token to update. _msgSender() must be its creator.
   * @param _newURI New URI for the token.
   */
  function setCustomURI(
    uint256 _tokenId,
    string memory _newURI
  ) public creatorOnly(_tokenId) {
    customUri[_tokenId] = _newURI;
    emit URI(_newURI, _tokenId);
  }

  /**
    * @dev Creates a new token type and assigns _initialSupply to an address
    * NOTE: remove onlyOwner if you want third parties to create new tokens on
    *       your contract (which may change your IDs)
    * NOTE: The token id must be passed. This allows lazy creation of tokens or
    *       creating NFTs by setting the id's high bits with the method
    *       described in ERC1155 or to use ids representing values other than
    *       successive small integers. If you wish to create ids as successive
    *       small integers you can either subclass this class to count onchain
    *       or maintain the offchain cache of identifiers recommended in
    *       ERC1155 and calculate successive ids from that.
    * @param _initialOwner address of the first owner of the token
    * @param _id The id of the token to create (must not currenty exist).
    * @param _initialSupply amount to supply the first owner
    * @param _uri Optional URI for this token type
    * @param _data Data to pass if receiver is contract
    * @return The newly created token ID
    */
  function create(
    address _initialOwner,
    uint256 _id,
    uint256 _initialSupply,
    string memory _uri,
    bytes memory _data
  ) public onlyRole(MINTER_ROLE) returns (uint256) {
    require(!_exists(_id), "token _id already exists");
    creators[_id] = _msgSender();

    if (bytes(_uri).length > 0) {
      customUri[_id] = _uri;
      emit URI(_uri, _id);
    }

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
  ) virtual public creatorOnly(_id) {
    _mint(_to, _id, _quantity, _data);
    tokenSupply[_id] = tokenSupply[_id].add(_quantity);
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
      require(creators[_id] == _msgSender(), "ERC1155Tradable#batchMint: ONLY_CREATOR_ALLOWED");
      uint256 quantity = _quantities[i];
      tokenSupply[_id] = tokenSupply[_id].add(quantity);
    }
    _mintBatch(_to, _ids, _quantities, _data);
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
  * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings.
  */
  function isApprovedForAll(address _owner, address _operator)
    public
    view
    override
    returns (bool isOperator)
  {
    uint256 chainId = getChainId();
    // Approach for Ethereum (Mainnet) and testnets (Rinkeby, Ropsten, Goerli)
    if ((chainId == 1) || (chainId == 3) || (chainId == 4) || (chainId == 5)) {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator) {
            return true;
        }
        // Approach for Polygon (Polygon) and testnet (Mumbai)
    } else if ((chainId == 137) || (chainId == 80001)) {
        // if OpenSea's ERC1155 Proxy Address is detected, auto-return true
        if (_operator == address(proxyRegistryAddress)) {
            return true;
        }
    }
    return ERC1155.isApprovedForAll(_owner, _operator);
  }

  /**
    * @dev Change the creator address for given token
    * @param _to   Address of the new creator
    * @param _id  Token IDs to change creator of
    */
  function _setCreator(address _to, uint256 _id) internal creatorOnly(_id)
  {
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

  function exists(
    uint256 _id
  ) external view returns (bool) {
      return _exists(_id);
  }

  /**
  * @dev See {IERC165-supportsInterface}.
  */
  function supportsInterface(bytes4 interfaceId) public view override(AccessControl, ERC1155) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  /**
  * @dev See {ERC1155-_beforeTokenTransfer}.
  *
  * Requirements:
  *
  * - the contract must not be paused.
  */
  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual override {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

    require(!paused(), "ERC1155Pausable: token transfer while paused");
  }

  function burn(
    address account,
    uint256 id,
    uint256 value
  ) public virtual ownersOnly(id) {
      require(
          account == _msgSender() || isApprovedForAll(account, _msgSender()),
          "ERC1155: caller is not owner nor approved"
      );
      require(
          balanceOf(_msgSender(), id) > 0,
          "ERC1155Tradable#ownersOnly: ONLY_OWNERS_ALLOWED"
      );
      require(
          balanceOf(_msgSender(), id) >= value,
          "ERC1155Tradable#ownersOnly: BURN_AMOUNT_EXCEEDS_BALANCE"
      );
      tokenSupply[id] = tokenSupply[id].sub(value);

      _burn(account, id, value);
  }

  function burnBatch(
    address account,
    uint256[] memory ids,
    uint256[] memory values
  ) public virtual {
      require(
          account == _msgSender() || isApprovedForAll(account, _msgSender()),
          "ERC1155: caller is not owner nor approved"
      );
      require(
          ids.length == values.length,
          "ERC1155Tradable#ownersOnly: BATCH_BURN_LENGTH_MISMATCH"
      );

      for (uint256 i = 0; i < ids.length; i++) {
          uint256 _id = ids[i];
          require(
              balanceOf(_msgSender(), _id) > 0,
              "ERC1155Tradable#ownersOnly: ONLY_OWNERS_ALLOWED"
          );
          uint256 quantity = values[i];
          require(
              balanceOf(_msgSender(), _id) >= quantity,
              "ERC1155Tradable#ownersOnly: BURN_AMOUNT_EXCEEDS_BALANCE"
          );
          tokenSupply[_id] = tokenSupply[_id].sub(quantity);
      }

      _burnBatch(account, ids, values);
  }

}
