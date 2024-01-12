// SPDX-License-Identifier: MIT
// Written by: Rob Secord (https://twitter.com/robsecord)
// Visit: Charged Particles - https://charged.fi
// Visit: Taggr - https://taggr.io

pragma solidity 0.8.4;

import "./Address.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";
import "./ERC721PreMint.sol";
import "./BlackholePrevention.sol";

// 1 Million Peppermint Rorschachs - Demo of ERC721PreMint
contract PeppermintRorschach is ERC721PreMint, ReentrancyGuard, BlackholePrevention {
  using Address for address payable;
  using Counters for Counters.Counter;

  /// @dev Some sales-related events
  event Purchase(address indexed newOwner, uint256 amount, uint256 lastTokenId);
  event PriceUpdate(uint256 newPrice);

  /// @dev Track number of tokens sold
  Counters.Counter internal _lastPurchasedTokenId;

  /// @dev ERC721 Base Token URI
  string internal _baseTokenURI;

  // Individual NFT Sale Price in ETH
  uint256 public _pricePer;

  // Feel the Burn!
  mapping (uint256 => uint256) internal _burns;


  /// @dev The Deployer of this contract is also the Owner and the Pre-Mint Receiver.
  constructor(
    string memory name,
    string memory symbol,
    string memory baseUri,
    uint256 maxSupply
  )
    ERC721PreMint(name, symbol, _msgSender(), maxSupply)
  {
    _baseTokenURI = baseUri;

    // Since we pre-mint to "owner", allow this contract to transfer on behalf of "owner" for sales.
    _setApprovalForAll(_msgSender(), address(this), true);
  }


  /// @dev Let's Pre-Mint a Gazillion NFTs!!  (wait, 2^^256-1 equals what again?)
  function preMint() external onlyOwner {
    _preMint();
  }


  /**
   * @dev Purchases from the Pre-Mint Receiver are a simple matter of transferring the token.
   * For this reason, we can provide a very simple "batch" transfer mechanism in order to
   * save even more gas for our users.
   */
  function purchase(uint256 amount) external payable virtual nonReentrant returns (uint256 amountTransferred) {
    uint256 index = _lastPurchasedTokenId.current();
    if (index + amount > _maxSupply) {
        amount = _maxSupply - index;
    }

    uint256 cost;
    if (_pricePer > 0) {
      cost = _pricePer * amount;
      require(msg.value >= cost, "Insufficient payment");
    }

    uint256[] memory tokenIds = new uint256[](amount);
    for (uint256 i = 0; i < amount; i++) {
      _lastPurchasedTokenId.increment();
      tokenIds[i] = _lastPurchasedTokenId.current();
    }
    amountTransferred = _batchTransfer(owner(), _msgSender(), tokenIds);

    emit Purchase(_msgSender(), amount, _lastPurchasedTokenId.current());

    // Refund overspend
    if (msg.value > cost) {
      payable(_msgSender()).sendValue(msg.value - cost);
    }
  }


  /// @dev Set the price for sales to maintain a consistent purchase price
  function setPrice(uint256 newPrice) external onlyOwner {
    _pricePer = newPrice;
    emit PriceUpdate(newPrice);
  }

  /// @dev Provide a Base URI for Token Metadata (override defined in ERC721.sol)
  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  //
  // Batch Transfers
  //

  function batchTransfer(
    address to,
    uint256[] memory tokenIds
  ) external virtual returns (uint256 amountTransferred) {
    amountTransferred = _batchTransfer(_msgSender(), to, tokenIds);
  }

  function batchTransferFrom(
    address from,
    address to,
    uint256[] memory tokenIds
  ) external virtual returns (uint256 amountTransferred) {
    amountTransferred = _batchTransfer(from, to, tokenIds);
  }

  function _batchTransfer(
    address from,
    address to,
    uint256[] memory tokenIds
  )
    internal
    virtual
    returns (uint256 amountTransferred)
  {
    uint256 count = tokenIds.length;

    for (uint256 i = 0; i < count; i++) {
      uint256 tokenId = tokenIds[i];

      // Skip invalid tokens; no need to cancel the whole tx for 1 failure
      // These are the exact same "require" checks performed in ERC721.sol for standard transfers.
      if (
        (ownerOf(tokenId) != from) ||
        (!_isApprovedOrOwner(from, tokenId)) ||
        (to == address(0))
      ) { continue; }

      _beforeTokenTransfer(from, to, tokenId);

      // Clear approvals from the previous owner
      _approve(address(0), tokenId);

      amountTransferred += 1;
      _owners[tokenId] = to;

      emit Transfer(from, to, tokenId);

      _afterTokenTransfer(from, to, tokenId);
    }

    // We can save a bit of gas here by updating these state-vars atthe end
    _balances[from] -= amountTransferred;
    _balances[to] += amountTransferred;
  }

  // Curious...
  /// @dev Very curious...
  function burn(uint256 tokenId) external virtual {
    _burn(tokenId);
    uint256 burns = _burns[tokenId];
    uint256 index = _lastPurchasedTokenId.current();
    if (index < _maxSupply && burns < 3) {
      _lastPurchasedTokenId.increment();
      uint256 newTokenId = _lastPurchasedTokenId.current();
      _burns[newTokenId] = burns + 1;
      _transfer(owner(), _msgSender(), tokenId);
    }
  }
  function getBurns(uint256 tokenId) external view returns (uint256) {
    return _burns[tokenId];
  }

  /***********************************|
  |            Only Owner             |
  |      (blackhole prevention)       |
  |__________________________________*/

  function withdrawEther(address payable receiver, uint256 amount) external onlyOwner {
    _withdrawEther(receiver, amount);
  }

  function withdrawErc20(address payable receiver, address tokenAddress, uint256 amount) external onlyOwner {
    _withdrawERC20(receiver, tokenAddress, amount);
  }

  function withdrawERC721(address payable receiver, address tokenAddress, uint256 tokenId) external onlyOwner {
    _withdrawERC721(receiver, tokenAddress, tokenId);
  }

  function withdrawERC1155(address payable receiver, address tokenAddress, uint256 tokenId, uint256 amount) external onlyOwner {
    _withdrawERC1155(receiver, tokenAddress, tokenId, amount);
  }
}
