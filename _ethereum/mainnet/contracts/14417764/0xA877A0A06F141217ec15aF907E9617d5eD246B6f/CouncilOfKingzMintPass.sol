// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./ERC721.sol";

contract CouncilOfKingzMintPass is ERC721, Ownable {
  using SafeMath for uint256;
  using Strings for uint256;

  // Contract controls
  bool public isPaused; //defaults to false
  address public redeemer;
  uint256 public expiration = 7 days; // 7 days

  // counters
  uint256 private _totalSupply = 0; // start with zero
  uint256 private _totalUsed = 0; // start with zero

  // metadata URIs
  string private _contractURI; // initially set at deploy
  string private _validURI; // initially set at deploy
  string private _usedURI; // initially set at deploy
  string private _expiredURI; // initially set at deploy

  mapping(uint256 => bool) public usedTokens;
  mapping(uint256 => uint256) public mintTime;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initContractURI,
    string memory _initValidURI,
    string memory _initUsedURI,
    string memory _initExpiredURI
  ) ERC721(_name, _symbol) {
    _contractURI = _initContractURI;
    _validURI = _initValidURI;
    _usedURI = _initUsedURI;
    _expiredURI = _initExpiredURI;
  }

  modifier contractIsNotPaused() {
    require(isPaused == false, 'Contract paused');
    _;
  }

  /**
   * @dev Returns the URI to the contract metadata
   */
  function contractURI() external view returns (string memory) {
    return _contractURI;
  }

  /**
   * @dev Returns the URI to the tokens metadata
   */
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(_exists(tokenId), 'Nonexistent token');

    if (isUsed(tokenId)) {
      return _usedURI;
    }

    if (isExpired(tokenId)) {
      return _expiredURI;
    }
    return _validURI;
  }

  /**
   * @dev Returns whether a token has been used for a claim or not
   */
  function isValid(uint256 tokenId) external view returns (bool) {
    require(_exists(tokenId), 'Nonexistent token');
    if (!isUsed(tokenId) && !isExpired(tokenId)) {
      return true;
    }
    return false;
  }

  /**
   * @dev Returns whether a token has been used for a claim or not
   */
  function isUsed(uint256 tokenId) public view returns (bool) {
    require(_exists(tokenId), 'Nonexistent token');
    return usedTokens[tokenId];
  }

  /**
   * @dev Returns the amount of time (sec) a token has for validity
   */
  function isExpired(uint256 tokenId) public view returns (bool) {
    require(_exists(tokenId), 'Nonexistent token');
    uint256 t = secondsSinceMint(tokenId);
    if (t < expiration) {
      return false;
    } else {
      return true;
    }
  }

  /**
   * @dev Returns the amount of time (sec) until the pass is expired
   */
  function secondsUntilExpired(uint256 tokenId)
    external
    view
    returns (uint256)
  {
    require(_exists(tokenId), 'Nonexistent token');
    if (expiration > secondsSinceMint(tokenId)) {
      return expiration - secondsSinceMint(tokenId);
    } else {
      return 0;
    }
  }

  /**
   * @dev Returns the amount of time (sec) have passed since the token was minted
   */
  function secondsSinceMint(uint256 tokenId) public view returns (uint256) {
    require(_exists(tokenId), 'Nonexistent token');
    return block.timestamp - mintTime[tokenId];
  }

  /**
   * @dev Returns the total number of tokens in circulation
   */
  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev Returns the total number of valid tokens in circulation
   */
  function totalValid() external view returns (uint256) {
    return _totalSupply - _totalUsed - totalExpired();
  }

  /**
   * @dev Returns the total number of used tokens in circulation
   */
  function totalUsed() external view returns (uint256) {
    return _totalUsed;
  }

  /**
   * @dev Returns the total number of expired tokens in circulation
   */
  function totalExpired() public view returns (uint256) {
    uint256 _totalExpired = 0;
    for (uint256 i = 1; i <= _totalSupply; i++) {
      if (_exists(i) && isExpired(i) && !isUsed(i)) {
        _totalExpired++;
      }
    }
    return _totalExpired;
  }

  /**
   * @dev Returns list of token ids owned by address
   */
  function walletOfOwner(address _owner)
    external
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    require(ownerTokenCount > 0, 'No tokens');
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    uint256 k = 0;
    // use the total actually minted since we aren't randomizing
    // token ids
    for (uint256 i = 1; i <= _totalSupply; i++) {
      if (_exists(i) && _owner == ownerOf(i)) {
        tokenIds[k] = i;
        k++;
      }
    }
    delete ownerTokenCount;
    delete k;
    return tokenIds;
  }

  /**
   * @dev Flags the tokens as used
   */
  function setAsUsed(uint256 tokenId) external contractIsNotPaused {
    require(_msgSender() == redeemer, 'Invalid caller');
    require(_exists(tokenId), 'Nonexistent token');
    require(!isUsed(tokenId), 'Token used');
    require(!isExpired(tokenId), 'Token expired');
    _totalUsed++;
    usedTokens[tokenId] = true;
  }

  // Owner Functions

  /**
   * @dev Owner mint function
   */
  function ownerMintTokensToAddresses(address[] memory _addresses)
    external
    onlyOwner
    contractIsNotPaused
  {
    // offset by 1 to start with token 1
    uint256 _newTokenId = _totalSupply + 1;
    for (uint256 i; i < _addresses.length; i++) {
      _mint(_addresses[i], _newTokenId);
      mintTime[_newTokenId] = block.timestamp;
      _newTokenId++;
    }
    _totalSupply += _addresses.length;
    delete _newTokenId;
  }

  /**
   * @dev Sets the paused state of the contract
   */
  function flipPausedState() external onlyOwner {
    isPaused = !isPaused;
  }

  /**
   * @dev Sets the address that can use the tokens
   */
  function setRedeemer(address _redeemer) external onlyOwner {
    require(_redeemer != address(0), 'Zero address');
    redeemer = _redeemer;
  }

  /**
   * @dev Sets the expiration duration
   */
  function setExpiration(uint256 _newExpiration) external onlyOwner {
    expiration = _newExpiration;
  }

  /**
   * @dev Sets the Contract URI
   */
  function setContractURI(string memory _newContractURI) external onlyOwner {
    _contractURI = _newContractURI;
  }

  /**
   * @dev Sets the uri for valid passes
   */
  function setValidURI(string memory _newValidURI) external onlyOwner {
    _validURI = _newValidURI;
  }

  /**
   * @dev Sets the uri for used passes
   */
  function setUsedURI(string memory _newUsedURI) external onlyOwner {
    _usedURI = _newUsedURI;
  }

  /**
   * @dev Sets the uri for expired passes
   */
  function setExpiredURI(string memory _newExpiredURI) external onlyOwner {
    _expiredURI = _newExpiredURI;
  }

  /**
   * @dev Reset an expired pass
   */
  function resetTokens(uint256[] memory _tokenIds) external onlyOwner {
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      uint256 _tokenId = _tokenIds[i];
      if (_exists(_tokenId) && isExpired(_tokenId) && !isUsed(_tokenId)) {
        mintTime[_tokenId] = block.timestamp;
      }
      delete _tokenId;
    }
  }

  function withdraw() external payable onlyOwner {
    (bool success, ) = payable(_msgSender()).call{
      value: address(this).balance
    }('');
    require(success);
  }

  /**
   * @dev A fallback functions in case someone sends ETH to the contract
   */
  fallback() external payable {}

  receive() external payable {}
}
