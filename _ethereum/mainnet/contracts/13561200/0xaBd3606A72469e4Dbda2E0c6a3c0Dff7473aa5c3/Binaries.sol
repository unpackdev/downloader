//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./SafeMath.sol";

/// @custom:security-contact @binaries_eth
contract Binaries is ERC721Enumerable, ERC721URIStorage {
  using SafeMath for uint256;
  using Strings for uint256;
  using Strings for uint8;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  error InsufficientFunds(uint256 available, uint256 required);
  error PaymentFailed();
  error CapReached();
  error NonExistentToken();
  error EmptyAttribute();
  error ContractPaused();

  // Pricing
  uint8 public MAX_SUPPLY = 255;
  uint256 public RESERVE = 0 ether;
  uint256 public CONTRIBUTIONS = 0 ether;
  uint256 public CLAIMED = 0 ether;

  // Mapping for token formulas and params
  // using Strings for uint256;
  mapping(uint => string) _formulas;
  mapping(uint => uint8[]) _params;
  mapping(uint => address) _creators;
  mapping(uint => uint) _sequence;
  mapping(address => uint) _shares;
  mapping(address => uint) _claimed;
  mapping(uint => uint) _lastTransfer;
  mapping(address => uint) _refunds;
  uint[] _burnedIndexes;

  string _uriPrefix;
  address _owner;
  uint public paused = 0;
  uint public refundable = 0;

  modifier onlyOwner() {
    require(msg.sender == _owner);
    _;
  }

  modifier pausable() {
    if (paused > 0) { revert ContractPaused(); }
    _;
  }

  struct TokenMetadata {
    address owner;
    address creator;
    string formula;
    uint8[] params;
    uint tokenId;
    uint sequence;
    uint burnPrice;
  }

  constructor() ERC721("Binaries", "BINIES") {
    _owner = msg.sender;
  }

  /**
    * @dev minting function
    *
    */
  function mint(string memory formula, uint8[] memory params)
    public
    payable
    pausable
    returns (uint256)
  {
    uint ts = totalSupply();
    if (ts >= MAX_SUPPLY) { revert CapReached(); }
    uint currentSequence = ts.add(1);

    uint256 _currentPrice = mintPrice(currentSequence);

    if (msg.value != _currentPrice)
      revert InsufficientFunds({
        available: msg.value,
        required: _currentPrice
      });

    _tokenIds.increment();
    uint256 newItemId = _tokenIds.current();

    _safeMint(msg.sender, newItemId);

    _setSequence(newItemId, currentSequence);
    _setFormula(newItemId, formula);
    _setCreator(newItemId, msg.sender);
    if (params.length > 0) {
      _setParams(newItemId, params);
    }

    RESERVE = RESERVE.add(burnPrice(currentSequence));
    CONTRIBUTIONS = CONTRIBUTIONS.add(_currentPrice.div(10));

    return newItemId;
  }

  /**
    * @dev burning function
    *
    */
  function burn(uint tokenId)
    public
    pausable
    returns (bool success)
  {
    require(msg.sender == ownerOf(tokenId));
    uint tokenSequence = _sequence[tokenId];
    uint256 price = burnPrice(tokenSequence);

    _burn(tokenId);

    delete _formulas[tokenId];
    delete _params[tokenId];
    delete _creators[tokenId];
    delete _sequence[tokenId];

    RESERVE = RESERVE.sub(price);
    (success, ) = msg.sender.call{value: price}("");
    if (success == false) { revert PaymentFailed(); }
  }

  function claim()
    public
    pausable
    returns (bool success)
  {
    uint claimableBalance = getClaimableBalance(msg.sender);
    require(claimableBalance > 0);

    CLAIMED = CLAIMED.add(claimableBalance);
    _claimed[msg.sender] += claimableBalance;
    (success, ) = msg.sender.call{value: claimableBalance}("");
    if (success == false) { revert PaymentFailed(); }
  }

  /**
    * @dev given a token supply calculates the minting price for a given token
    *
    * Formula:
    * Return = x ** 2 / 2 ** 10
    *
    * @param _tokenSequence         token sequence
    *
    * @return mint price
    */
  function mintPrice(uint256 _tokenSequence) public pure returns(uint256) {
    require(_tokenSequence > 0);

    // set initial price to max to prevent 0 price
    uint256 price = type(uint256).max;

    price = _tokenSequence.mul(_tokenSequence).mul(1e18).div(1024);

    return price;
  }

  /**
    * @dev given a token sequence calculates the burn price for a given token
    *
    * Formula:
    * Return = x ** 2 / 2 ** 10 * 0.8
    *
    * @param _tokenSequence   token sequence
    *
    * @return mint price
    */
  function burnPrice(uint256 _tokenSequence) public pure returns(uint256) {
    require(_tokenSequence > 0);

    // set initial price to min to prevent max price
    uint256 price = 0;

    price = _tokenSequence.mul(_tokenSequence).mul(8e17).div(1024);

    return price;
  }

  function allTokensMetadata()
    public
    view
    returns (TokenMetadata[] memory)
  {
    uint ts = totalSupply();
    TokenMetadata[] memory results = new TokenMetadata[](ts);

    for (uint i = 0; i < ts; i++) {
      uint tokenId = tokenByIndex(i);
      results[i] = tokenMetadata(tokenId);
    }

    return results;
  }

  function tokenMetadata(uint256 tokenId)
    public
    view
    returns (TokenMetadata memory)
  {
    TokenMetadata memory metadata;
    metadata.owner = ERC721.ownerOf(tokenId);
    metadata.creator = _creators[tokenId];
    metadata.formula = _formulas[tokenId];
    metadata.params = _params[tokenId];
    metadata.tokenId = tokenId;
    metadata.sequence = _sequence[tokenId];
    metadata.burnPrice = burnPrice(_sequence[tokenId]);

    return metadata;
  }

  /**
    * @dev Contract balance
    */
  function getBalance() public view returns (uint) {
    return address(this).balance;
  }

  /**
    * @dev Withdraw from contract keeping the reserve.
    */
  function withdraw() public onlyOwner {
    uint value = getBalance().sub(RESERVE).sub(CONTRIBUTIONS.sub(CLAIMED));
    (bool success, ) = msg.sender.call{value: value}("");
    if (success == false) { revert PaymentFailed(); }
  }

  /**
    * @dev Emergency refunds.
    *
    */
  function claimRefund()
    public
    returns (bool success)
  {
    require(refundable == 1);
    address owner = msg.sender;

    uint refund = 0 ether;
    uint count = ERC721.balanceOf(owner);
    for (uint i = 0; i < count; i += 1) {
      refund += burnPrice(_sequence[tokenOfOwnerByIndex(owner, i)]);
    }
    RESERVE = RESERVE.sub(refund);

    uint claimable = getClaimableBalance(owner);
    refund += claimable;
    CLAIMED = CLAIMED.add(claimable);

    (success, ) = owner.call{value: refund}("");
    if (success == false) { revert PaymentFailed(); }
  }

  function pause() public onlyOwner {
    paused = 1;
  }

  function unpause() public onlyOwner {
    require(refundable == 0);
    paused = 0;
  }

  function makeRefundable() public onlyOwner {
    require(paused == 1);
    refundable = 1;
  }

  /**
    * @dev Claimable balance from accrued contributions
    *
    */
  function getClaimableBalance(address owner) public view returns (uint amount) {
    uint allShares = _getAllShares();
    uint burnedShares = _getBurnedShares();
    uint accruedShares = _getAccruedSharesFromOwnedTokens(owner);
    uint shares = _shares[owner];
    shares += accruedShares;
    allShares -= burnedShares;
    amount = CONTRIBUTIONS.mul(shares).div(allShares).sub(_claimed[owner]);
  }

  function _getAllShares() internal view returns (uint shares) {
    uint current = _tokenIds.current();
    shares = current.mul(current).add(current).div(2);
  }

  function _getBurnedShares() internal view returns (uint burns) {
    uint current = _tokenIds.current();
    uint count = _burnedIndexes.length;
    for(uint i = 0; i < count; i += 1) {
      burns += current - _burnedIndexes[i];
    }
  }

  function _getAccruedSharesFromOwnedTokens(address owner) internal view returns (uint shares) {
    uint current = _tokenIds.current();
    uint count = ERC721.balanceOf(owner);
    for (uint i = 0; i < count; i += 1) {
      shares += current - _lastTransfer[tokenOfOwnerByIndex(owner, i)];
    }
  }

  /**
    * @dev Sets `_formula` as the Formula of `tokenId`.
    *
    * Requirements:
    *
    * - `tokenId` must exist.
    * - `formula` must exist.
    */
  function _setFormula(uint tokenId, string memory formula) internal virtual {
    if (!_exists(tokenId)) { revert NonExistentToken(); }
    if (bytes(formula).length == 0) { revert EmptyAttribute(); }

    _formulas[tokenId] = formula;
  }

  /**
    * @dev Sets `_formula` as the Formula of `tokenId`.
    *
    * Requirements:
    *
    * - `tokenId` must exist.
    */
  function _setCreator(uint tokenId, address creator) internal virtual {
    if (!_exists(tokenId)) { revert NonExistentToken(); }

    _creators[tokenId] = creator;
  }

  /**
    * @dev Sets `_sequence` of `tokenId`.
    *
    * Requirements:
    *
    * - `tokenId` must exist.
    * - `sequence` must be greater then 0.
    */
  function _setSequence(uint tokenId, uint sequence) internal virtual {
    if (!_exists(tokenId)) { revert NonExistentToken(); }
    if (sequence <= 0) { revert EmptyAttribute(); }

    _sequence[tokenId] = sequence;
  }

  /**
    * @dev Sets `_lastTransfer` index of `tokenId`. Used to calculate how log token was hodl before transfer
    *
    * - `tokenId` must be present.
    */
  function _setLastTransfer(uint tokenId, uint sequence) internal virtual {
    if (tokenId <= 0) { revert EmptyAttribute(); }

    _lastTransfer[tokenId] = sequence;
  }

  /**
    * @dev Sets `_params` as the Params of `tokenId`.
    *
    * Requirements:
    *
    * - `tokenId` must exist.
    * - `params` cannot be empty.
    */
  function _setParams(uint tokenId, uint8[] memory params) internal virtual {
    if (!_exists(tokenId)) { revert NonExistentToken(); }
    if (params.length == 0) { revert EmptyAttribute(); }

    _params[tokenId] = params;
  }

  /**
   *  Overrides necessary, because of two inherited versions from ERC721
   *  and ERC721Enumerable / ERC721URIStorage
   */

  /**
    * @dev See {ERC721URIStorage-tokenURI}
    *
    * Overrides ERC721URIStorage implementation:
    * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.2/contracts/token/ERC721/extensions/ERC721URIStorage.sol#L19
    */
  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
  {
    require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

    string memory base = _baseURI();
    string memory id = tokenId.toString();//uint2str(tokenId);
    return string(abi.encodePacked(base, id));
  }

  function setBaseURI(string memory prefix) public onlyOwner {
    _uriPrefix = prefix;
  }

  function _baseURI()
    internal
    view
    virtual
    override
    returns (string memory)
  {
    return _uriPrefix;
  }

  /**
    * @dev See {ERC721Enumerable-_beforeTokenTransfer}
    *
    * Overrides ERC721Enumerable implementation:
    * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.2/contracts/token/ERC721/extensions/ERC721Enumerable.sol#L71
    */
  function _beforeTokenTransfer(address from, address to, uint256 tokenId)
      internal
      pausable
      override(ERC721, ERC721Enumerable)
  {
    super._beforeTokenTransfer(from, to, tokenId);

    // case 1:
    // when minting first token, it's id is 1 and last transfer is 0 which gives 1 share
    // when burning a first token it

    uint currentId = _tokenIds.current();
    uint lastTransfer = _lastTransfer[tokenId];

    if (from == address(0)) {
      _setLastTransfer(tokenId, currentId.sub(1));
    } else if (from != to) { // incoming including burn
      // accrue shares
      assert(currentId >= lastTransfer);
      _shares[from] += currentId.sub(lastTransfer);
    }

    // burn
    if (to == address(0)) {
      _burnedIndexes.push(currentId);
      delete _lastTransfer[tokenId];
    } else if (to != from && from != address(0)) { // outgoing transfer reset the sequence
      _setLastTransfer(tokenId, currentId);
    }
  }

  /**
    * @dev See {ERC721-_burn}
    *
    * Overrides implementations:
    * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.2/contracts/token/ERC721/ERC721.sol#L304
    * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.2/contracts/token/ERC721/extensions/ERC721URIStorage.sol#L59
    */
  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  /**
    * @dev See {IERC165-supportsInterface}.
    */
  function supportsInterface(bytes4 interfaceId)
      public
      view
      override(ERC721, ERC721Enumerable)
      returns (bool)
  {
      return super.supportsInterface(interfaceId);
  }
}
