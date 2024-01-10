// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./ReentrancyGuard.sol";

abstract contract Mintable is ERC721, ReentrancyGuard {

  /// @dev Founders count
  address[] private _foundersIndex;

  /// @dev Founders list
  mapping(address => bool) private _founders;

  /// @dev Mapping of founders addresses to their balances
  mapping(address => uint256) private _foundersBalances;

  /// @dev A token mint price (0.3 ETH)
  uint256 private _price = 300000000000000000;

  /// @dev Maximum amount of tokens
  uint256 private _maxTokenId = 10000;

  /// @dev Founders reserve
  uint256 private _foundersReserveFrom = 9800;

  /// @dev Is minting paused flag
  bool private _mintingPaused = true;

  /**
   * @dev Emits when new token is minted
   */
  event Minted(
    uint256 indexed tokenId,
    address indexed minter,
    uint256 indexed value
  );

  /**
   * @dev Emits when new token is minted
   */
  event MintedBatch(
    uint256[] tokenIds,
    address indexed minter
  );

  /**
   * @dev Emits when a founder withdraw his balance
   */
  event Withdraw(
    uint256 indexed value,
    address indexed founder
  );

  /**
   * @dev Emits when minting is became paused
   */
  event Paused(address pauser);

  /**
   * @dev Emits when minting is became unpaused
   */
  event Unpaused(address pauser);

  /**
   * Throws when token is already exists (minted)
   */
  error TokenAlreadyExists();

  /**
   * Throws when token not allowed to be minted
   */
  error TokenIdNotAllowed();

  /**
   * Throws when value provided insufficient to mint a token
   */
  error InsufficientValue();

  /**
   * Throws when the balance of founder is insufficient to withdraw
   */
  error InsufficientBalance();

  /**
   * Throws when sender try to mint a token during the paused minting state
   */
  error MintingPaused();

  /**
   * Throws when sender try to change minting state to the same value
   */
  error PausedAlready(bool paused);

  /**
   * Throws when someone access to function allowed to founders only
   */
  error OnlyFoundersAllowed();

  /**
   * @dev Prevent function execution in case of the sender is not a founder
   */
  modifier onlyFounder() {
    if (!_founders[_msgSender()]) {
      revert OnlyFoundersAllowed();
    }
    _;
  }

  constructor(address[] memory founders) {

    for (uint256 i = 0; i < founders.length; i++) {
      _foundersIndex.push(founders[i]);
      _founders[founders[i]] = true;
      _foundersBalances[founders[i]] = 0;
    }
  }

  /**
   * @dev Returns true when token is available to be minted
   */
  function isTokenMintable(uint256 tokenId)
    external
    view
    returns (bool mintable)
  {
    mintable = !_exists(tokenId) && tokenId <= _maxTokenId;
  }

  /**
   * @dev Mints the token
   */
  function mint(uint256 tokenId) external payable nonReentrant {
    _beforeTokenMint(tokenId);
    _safeMint(_msgSender(), tokenId);
    _afterTokenMint(tokenId);
  }

  /**
   * @dev Mints batch of token
   */
  function mintBatch(
    uint256[] memory ids
  ) external payable onlyFounder nonReentrant {

    address sender = _msgSender();

    for (uint256 i = 0; i < ids.length; i++) {
      _beforeTokenMint(ids[i]);
      _safeMint(sender, ids[i]);
    }

    emit MintedBatch(ids, sender);
  }

  /**
   * @dev Pauses minting
   */
  function pause() external onlyFounder {
    if (_mintingPaused == true) {
      revert PausedAlready(true);
    }

    _mintingPaused = true;
    emit Paused(_msgSender());
  }

  /**
   * @dev Resumes minting
   */
  function unpause() external onlyFounder {
    if (_mintingPaused == false) {
      revert PausedAlready(false);
    }

    _mintingPaused = false;
    emit Unpaused(_msgSender());
  }

  /**
   * @dev Returns a paused state
   */
  function isPaused() external view returns (bool paused) {
    paused = _mintingPaused;
  }

  /**
   * @dev Returns a minting price
   */
  function getPrice() external view returns (uint256 price) {
    price = _price;
  }

  /**
   * @dev Allowing to check if an address is a founder
   */
  function isFounder(address founder) external view returns (bool) {
    return _founders[founder];
  }

  /**
   * @dev Returns balance of a founder
   */
  function balanceOfFounder(address founder) external view returns (uint256 balance) {
    balance = _foundersBalances[founder];
  }

  /**
   * @dev Withdraws the balance of a founder
   */
  function withdrawFounder() external nonReentrant {
    address sender = _msgSender();
    uint256 balance = _foundersBalances[sender];

    if (balance == 0) {
      revert InsufficientBalance();
    }

    _foundersBalances[sender] = 0;
    Address.sendValue(payable(sender), balance);

    emit Withdraw(balance, sender);
  }

  /**
   * @dev Hook that is called before any token minted.
   *
   * Requirements:
   *  - token must not exists
   *  - regular senders cannot mint tokens during minting paused state
   *  - founders should not pay for minting
   *  - msg.value must be sufficient to mint a token (except for founders)
   *  - regular senders can mint tokens in allowed range from zero to _foundersReserveFrom
   *  - founders can mint tokens in allowed range from _foundersReserveFrom to _maxTokenId
   */
  function _beforeTokenMint(
    uint256 tokenId
  )
    internal
    virtual
  {
    address sender = _msgSender();

    if (_exists(tokenId)) {
      revert TokenAlreadyExists();
    }

    bool isSenderFounder = _founders[sender];

    if (!isSenderFounder && _mintingPaused) {
      revert MintingPaused();
    }

    if (
      (!isSenderFounder && tokenId >= _foundersReserveFrom) ||
      (
        isSenderFounder &&
        (
          tokenId < _foundersReserveFrom ||
          tokenId > _maxTokenId
        )
      )
    ) {
      revert TokenIdNotAllowed();
    }

    if (!isSenderFounder && msg.value < _price) {
      revert InsufficientValue();
    }
  }

  /**
   * @dev Hook that is called after any token minted.
   */
  function _afterTokenMint(
    uint256 tokenId
  )
    internal
    virtual
  {
    uint256 remainder = msg.value % _foundersIndex.length;
    uint256 share = (msg.value - remainder) / _foundersIndex.length;

    for (uint256 i = 0; i < _foundersIndex.length; i++) {
      _foundersBalances[_foundersIndex[i]] += share;
    }

    address sender = _msgSender();

    if (remainder > 0) {
      Address.sendValue(payable(sender), remainder);
    }

    emit Minted(tokenId, sender, msg.value - remainder);
  }
}
