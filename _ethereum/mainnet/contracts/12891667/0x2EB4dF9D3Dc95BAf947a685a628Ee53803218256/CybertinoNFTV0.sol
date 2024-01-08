// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./OwnableUpgradeable.sol";
import "./ERC1155Upgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./CybertinoNFTStorageV0.sol";
import "./ICybertinoNFT.sol";
import "./console.sol";

contract CybertinoNFTV0 is
  ERC1155Upgradeable,
  OwnableUpgradeable,
  ICybertinoNFT,
  CybertinoNFTStorageV0
{
  using ECDSAUpgradeable for bytes32;
  using CountersUpgradeable for CountersUpgradeable.Counter;

  function CybertinoNFT_init(
    string memory _name,
    string memory _uri,
    string memory _symbol,
    address _signer,
    address _manager
  ) public initializer {
    __Context_init_unchained();
    __ERC165_init_unchained();
    __Ownable_init_unchained();
    __ERC1155_init_unchained(_uri);
    CybertinoNFT_init_unchained(_name, _symbol, _signer, _manager);
  }

  function CybertinoNFT_init_unchained(
    string memory _name,
    string memory _symbol,
    address _signer,
    address _manager
  ) public initializer {
    name = _name;
    symbol = _symbol;
    signer = _signer;
    transferOwnership(_manager);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC1155Upgradeable)
    returns (bool)
  {
    return
      interfaceId == type(ICybertinoNFT).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  modifier pausable {
    if (paused) {
      revert('Paused');
    } else {
      _;
    }
  }

  /**
   * @dev Creates a new NFT type
   * @param _cid Content identifier
   * @param _data Data to pass if receiver is contract
   * @param _maxSupply Max supply of this NFT
   * @return _id The newly created token ID
   */
  function create(
    string calldata _cid,
    bytes calldata _data,
    uint256 _maxSupply
  ) public onlyOwner returns (uint256 _id) {
    require(bytes(_cid).length > 0, 'Err: Missing Content Identifier');

    _id = _nextId();
    _mint(msg.sender, _id, 0, _data);

    idToUri[_id] = _cid;
    maxTokenSupply[_id] = _maxSupply;

    emit URI(uri(_id), _id);
  }

  /**
   * @dev Batch create new NFT types
   * @param _cids Content identifiers
   * @param _datas Datas to pass if receiver is contract
   * @param _maxSupplys Max supplys of these  NFTs
   * @return _id The latest token ID
   */
  function batchCreate(
    string[] calldata _cids,
    bytes[] calldata _datas,
    uint256[] calldata _maxSupplys
  ) external onlyOwner returns (uint256 _id) {
    for (uint256 i = 0; i < _cids.length; i++) {
      create(_cids[i], _datas[i], _maxSupplys[i]);
    }
    return id.current();
  }

  /**
   * @dev Mints an existing NFT type
   * @notice Enforces a maximum of 1 minting event per NFT type per account
   * @param _to Account to mint NFT to (i.e. the owner)
   * @param _id ID (i.e. type) of NFT to mint
   * @param _amount number of NFTs of same type to mint
   * @param _nonce platform nounce to prevent replay
   * @param _signature Verified signature granting _account an NFT
   * @param _data Data to pass if receiver is contract
   */
  function mint(
    address _to,
    uint256 _id,
    uint256 _amount,
    uint256 _nonce,
    bytes calldata _signature,
    bytes calldata _data
  ) public pausable {
    require(_exists(_id), 'CybertinoNFT: invalid ID');
    require(_amount >= 1, 'CybertinoNFT: must mint at least one');
    require(
      tokenSupply[_id] + _amount <= maxTokenSupply[_id],
      'CybertinoNFT: exceeds max supply'
    );
    bytes32 messageHash = getMessageHash(_to, _id, _amount, _nonce);
    require(!executed[messageHash], 'CybertinoNFT: already minted');
    require(
      _verify(messageHash, _signature),
      'CybertinoNFT: invalid signature'
    );
    executed[messageHash] = true;

    _mint(_to, _id, _amount, _data);
    tokenSupply[_id] += _amount;

    address operator = _msgSender();

    emit CybertinoMint(operator, _to, _id, _amount, _nonce);
  }

  /**
   * @dev Batch mints multiple different existing NFT types
   * @notice Enforces a maximum of 1 minting event per account per NFT type
   * @param _to Account to mint NFT to (i.e. the owner)
   * @param _ids IDs of the type of NFT to mint
   * @param _amounts numbers of NFTs of same type to mint
   * @param _nonces platform nounces to prevent replay
   * @param _signatures Verified signatures granting _account an NFT
   * @param _data Data to pass if receiver is contract
   */
  function batchMint(
    address _to,
    uint256[] calldata _ids,
    uint256[] calldata _amounts,
    uint256[] calldata _nonces,
    bytes[] calldata _signatures,
    bytes[] calldata _data
  ) external pausable {
    for (uint256 i = 0; i < _ids.length; i++) {
      mint(_to, _ids[i], _amounts[i], _nonces[i], _signatures[i], _data[i]);
    }
  }

  /**
   * @dev Sets a new URI for all token types
   */
  function setURI(string memory _uri) public onlyOwner {
    _setURI(_uri);
  }

  /**
   * @dev Returns the uri of a token given its ID
   * @param _id ID of the token to query
   * @return uri of the token or an empty string if it does not exist
   */
  function uri(uint256 _id) public view override returns (string memory) {
    string memory baseUri = super.uri(0);
    if (bytes(baseUri).length == 0) {
      return '';
    } else {
      return string(abi.encodePacked(baseUri, idToUri[_id]));
    }
  }

  /**
   * @dev Returns the total quantity for a token ID
   * @param _id ID of the token to query
   * @return amount of token in existence
   */
  function totalSupply(uint256 _id) public view returns (uint256) {
    return tokenSupply[_id];
  }

  /**
   * @dev Returns the max quantity for a token ID
   * @param _id ID of the token to query
   * @return amount of token in existence
   */
  function maxSupply(uint256 _id) public view returns (uint256) {
    return maxTokenSupply[_id];
  }

  /**
   * @dev Pause or unpause the minting and creation of NFTs
   */
  function pause() public onlyOwner {
    paused = !paused;
  }

  /**
   * @dev Update the signer
   */
  function updateSigner(address _signer) public onlyOwner {
    signer = _signer;
  }

  /**
   * @dev Create message hash to be signed
   */
  function getMessageHash(
    address _to,
    uint256 _tokenId,
    uint256 _amount,
    uint256 _nonce
  ) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(_to, _tokenId, _amount, _nonce));
  }

  function _exists(uint256 _id) internal view returns (bool) {
    return (bytes(idToUri[_id]).length > 0);
  }

  function _nextId() internal returns (uint256) {
    id.increment();
    return id.current();
  }

  function _verify(bytes32 messageHash, bytes memory signature)
    internal
    view
    returns (bool)
  {
    bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();
    return ethSignedMessageHash.recover(signature) == signer;
  }
}
