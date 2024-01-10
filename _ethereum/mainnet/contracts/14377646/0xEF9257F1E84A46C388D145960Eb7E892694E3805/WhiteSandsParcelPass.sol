// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./Counters.sol";
import "./ERC165Checker.sol";

import "./DeveloperAccessControl.sol";
import "./IPresaleAccessControlHandler.sol";
import "./PresaleAccessControlHandler.sol";
import "./Sales.sol";

/**
 * @title White Sands - Parcel Pass Contract
 *
 * @notice The White Sands Parcel Pass contract allows minting a time-limited presale controlled by
 * an access list, and then a public sale. The presale is limited by the number of tokens that can
 * be minted per wallet. The presale mint allocation also counts towards the public sale limit.
 */
contract WhiteSandsParcelPass is ERC721, DeveloperAccessControl, Pausable, ReentrancyGuard {
  using Sales for Sales.PreSale;
  using Counters for Counters.Counter;
  using ERC165Checker for address;

  address constant PAYOUT_ADDRESS = address(0xe3dB823ce2eA1B9A545F4ea93886aEBeEC26fd75);
  bytes4 constant ACL_IID = type(IPresaleAccessControlHandler).interfaceId;

  uint8 constant DEFAULT_TX_LIMIT = 2;
  uint8 constant DEFAULT_WALLET_LIMIT = 2;
  uint32 constant DEFAULT_LIMIT = 3000;
  uint128 constant DEFAULT_PRICE = 0.5 ether;

  struct AppStorage {
    uint8 maxTokensPerTx;
    uint8 maxTokensPerWallet;
    uint32 supplyLimit;
    uint32 totalSupply;
    uint128 price;
    uint64 presaleStart;
    uint64 presaleEnd;
    IPresaleAccessControlHandler acl;
  }

  AppStorage public state;

  event TokenMinted(address to, uint32 token);

  constructor(
    address owner,
    address acl,
    uint64 preSaleStart
  ) DeveloperAccessControl(owner) ERC721("White Sans Parcel Pass", "WSPP") {
    state.maxTokensPerTx = DEFAULT_TX_LIMIT;
    state.maxTokensPerWallet = DEFAULT_WALLET_LIMIT;
    state.supplyLimit = DEFAULT_LIMIT;
    state.price = DEFAULT_PRICE;
    state.presaleStart = preSaleStart;
    state.presaleEnd = preSaleStart + 24 hours;
    require(acl.supportsInterface(ACL_IID), "ACL: wrong interface type for checker");
    state.acl = IPresaleAccessControlHandler(acl);
  }

  modifier onlyPresale() {
    require(block.timestamp >= state.presaleStart, "Presale not open yet");
    require(block.timestamp < state.presaleEnd, "Presale has closed");
    _;
  }

  modifier onlyPublicSale() {
    require(block.timestamp >= state.presaleEnd, "Sale not open yet");
    _;
  }

  function pause() external onlyUnlocked {
    if (paused()) {
      _unpause();
    } else {
      _pause();
    }
  }

  /// Minting method for people on the access list that can mint before the public sale.
  ///
  /// The combination of the nonce and senders address is signed by the trusted signer wallet.
  function mintPresale(
    uint16 count,
    uint256 nonce,
    bytes calldata signature
  ) external payable onlyPresale nonReentrant {
    (bool canMint, bytes memory error) = state.acl.verifyCanMintPresaleTokens(
      _msgSender(),
      uint32(balanceOf(_msgSender())),
      state.presaleStart,
      state.presaleEnd,
      count,
      nonce,
      signature
    );
    require(canMint, string(abi.encodePacked("ERROR: ", error)));
    _safeMintTokens(count);
  }

  /// Perform a regular mint with a limit per wallet on passes as well as a limit per transaction.
  function mint(uint16 count) external payable onlyPublicSale {
    _safeMintTokens(count);
  }

  function _safeMintTokens(uint16 count) internal {
    require(count <= state.maxTokensPerTx, "exceeded max per transaction");
    require(balanceOf(_msgSender()) + count <= state.maxTokensPerWallet, "exceeded max per wallet");
    require(state.totalSupply + count <= state.supplyLimit, "mint: not enough supply");

    uint256 cost = count * state.price;
    require(msg.value >= cost, "Insufficient funds");

    for (uint16 i = 0; i < count; i++) {
      uint32 token = nextTokenId();
      _safeMint(_msgSender(), token);
      emit TokenMinted(_msgSender(), token);
    }

    if (msg.value > cost) {
      uint256 refund = msg.value - cost;
      (bool success,) = payable(_msgSender()).call{value : refund}("");
      require(success, "Failed to refund additional value");
    }
  }

  function setPresaleAccessController(address acl) external onlyUnlocked {
    require(acl.supportsInterface(ACL_IID), "ACL: wrong interface type for checker");
    state.acl = IPresaleAccessControlHandler(acl);
  }

  function setPresaleDetails(uint64 startTime, uint64 durationInHours) external onlyUnlocked {
    state.presaleStart = startTime;
    state.presaleEnd = startTime + (durationInHours * 1 hours);
  }

  function getPresaleStart() public view returns (uint64) {
    return state.presaleStart;
  }

  function getSaleStart() public view returns (uint64) {
    return state.presaleEnd;
  }

  function setTokensPerTx(uint8 limit) external onlyUnlocked {
    state.maxTokensPerTx = limit;
  }

  function getTokensPerTx() external view returns (uint8) {
    return state.maxTokensPerTx;
  }

  function setTokensPerWallet(uint8 limit) external onlyUnlocked {
    state.maxTokensPerWallet = limit;
  }

  function getTokensPerWallet() external view returns (uint8) {
    return state.maxTokensPerWallet;
  }

  function setTokenSupplyLimit(uint32 limit) external onlyUnlocked {
    state.supplyLimit = limit;
  }

  function getTokenSupplyLimit() external view returns (uint32) {
    return state.supplyLimit;
  }

  function setMintPrice(uint128 _price) external onlyUnlocked {
    state.price = _price;
  }

  function price() external view returns (uint128) {
    return state.price;
  }

  /**
   * @dev Returns the total amount of tokens stored by the contract.
     */
  function totalSupply() external view returns (uint256) {
    return state.totalSupply;
  }

  /**
   * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
  function tokenByIndex(uint256 index) external pure returns (uint256) {
    return index;
  }

  function nextTokenId() internal returns (uint32) {
    state.totalSupply++;
    return state.totalSupply;
  }

  function recoverSignerAddress(
    uint256 nonce,
    address sender,
    bytes calldata signature
  ) internal pure returns (address) {
    bytes32 message = keccak256(abi.encode(nonce, sender));
    bytes32 digest = ECDSA.toEthSignedMessageHash(message);
    return ECDSA.recover(digest, signature);
  }

  function _afterTokenTransfer(
    address /*from*/,
    address /*to*/,
    uint256 /*tokenId*/
  ) internal virtual override {
    maybeLock();
  }

  /** Fallback to be able to receive ETH payments (just in case!) */
  receive() external payable {}

  function withdraw() external onlyOwner {
    require(payable(PAYOUT_ADDRESS).send(address(this).balance), "withdraw: sending funds failed");
  }
}
