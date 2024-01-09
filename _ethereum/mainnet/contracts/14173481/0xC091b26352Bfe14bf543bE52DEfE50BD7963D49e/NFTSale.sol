// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./PaymentSplitter.sol";
import "./INeverFearTruth.sol";

/**
 * @title NFTSale
 * @dev Conducts the sale of NeverFearTruth tokens. Supports private mint for the contract owner,
 * whitelisted sale using merkle trees and public sale.
 */
contract NFTSale is Ownable, PaymentSplitter {
  // The max amount of tokens that can be minted by the owner
  uint256 public immutable MAX_RESERVED_MINT;
  // The max amount of tokens that can be minted by users
  uint256 public immutable MAX_USER_MINT;
  // The address of the nft contract
  INeverFearTruth public immutable NFT;
  // The amount of ether required to purchase a token
  uint256 public immutable TOKEN_PRICE;
  // The number of the current tokens minted by the owner
  uint256 public totalOwnerMint;
  // Keep track of users addresses that purchased a token
  mapping(address => bool) public participants;
  // Merkle tree root hash
  bytes32 public merkleRoot;
  // The start timestamp for the sale
  uint256 public startTimestamp;
  // The end timestamp for the sale
  uint256 public endTimestamp;
  // The start timestamp for the public sale. Set to 0 to disable it
  uint256 public publicSaleStartTimestamp;

  // Event emitted when the owner mints new tokens
  event OwnerMinted(address indexed receiver, uint256 amount);
  // Event emitted when a user purchases a token
  event UserPurchased(address indexed user);
  // Event emitted when a new sale is set
  event SaleConfigSet(bytes32 root, uint256 startTimestamp, uint256 endTimestamp);
  // Event emitted when a new public sale is set
  event PublicSaleSet(uint256 startTimestamp);

  /**
   * @dev Initializes the contract by setting the max reserved mint for the owner and the ERC721 contract address.
   * @param token The address of the nft contract
   * @param maxReservedMint The max amount of tokens that can be minted by the owner
   * @param tokenPrice The amount of ether required to purchase a token
   * @param payees The list of addresses that will receive the payments
   * @param shares The list of shares that will be distributed to the payees
   */
  constructor(
    INeverFearTruth token,
    uint256 maxReservedMint,
    uint256 tokenPrice,
    address[] memory payees,
    uint256[] memory shares
  ) PaymentSplitter(payees, shares) {
    NFT = token;
    MAX_RESERVED_MINT = maxReservedMint;
    MAX_USER_MINT = NFT.MAX_SUPPLY() - maxReservedMint;
    TOKEN_PRICE = tokenPrice;
  }

  /**
   * @dev Mints a new amount of reserved tokens to the receiver up to the max amount.
   * Only the owner can call this function.
   * @param receiver The address of the receiver of the token
   * @param amount The amount of tokens to mint to the receiver
   */
  function privateMint(address receiver, uint256 amount) external onlyOwner {
    require(receiver != address(0), "receiver is the zero address");
    totalOwnerMint = totalOwnerMint + amount;
    require(totalOwnerMint <= MAX_RESERVED_MINT, "max reserved supply reached");

    for (uint256 i = 0; i < amount; i++) {
      NFT.mint(receiver);
    }
    emit OwnerMinted(receiver, amount);
  }

  /**
   * @dev Sets the configuration for the token sale. Can be set multiple times. Only the owner can call this function.
   * @param newRoot The merkle tree root hash
   * @param newStartTimestamp The start timestamp for the sale
   * @param newEndTimestamp The end timestamp for the sale
   */
  function setSaleConfig(
    bytes32 newRoot,
    uint256 newStartTimestamp,
    uint256 newEndTimestamp
  ) external onlyOwner {
    require(newRoot != bytes32(0), "invalid root");
    require(newStartTimestamp > 0, "invalid start timestamp");
    require(newEndTimestamp > newStartTimestamp, "invalid end timestamp");

    merkleRoot = newRoot;
    startTimestamp = newStartTimestamp;
    endTimestamp = newEndTimestamp;

    emit SaleConfigSet(newRoot, newStartTimestamp, newEndTimestamp);
  }

  /**
   * @dev Sets the configuration for the public sale. Should be set to 0 to disable the public sale.
   * Only the owner can call this function.
   * @param publicStartTimestamp The start timestamp for the public sale
   */
  function setPublicSale(uint256 publicStartTimestamp) external onlyOwner {
    // safety check to avoid overlapping between public and private sales
    require(publicStartTimestamp == 0 || publicStartTimestamp > endTimestamp, "invalid public start timestamp");

    publicSaleStartTimestamp = publicStartTimestamp;

    emit PublicSaleSet(publicStartTimestamp);
  }

  /**
   * @dev Buy a token from the active sale
   * @param proofs The proofs to validate with the merkle root that the user is included in the list of purchasers
   */
  function buy(bytes32[] calldata proofs) external payable {
    // Validates the sale is active
    require(block.timestamp >= startTimestamp && block.timestamp <= endTimestamp, "sale not active");
    // Validates the user is in the list of purchasers
    require(MerkleProof.verify(proofs, merkleRoot, keccak256(abi.encodePacked(_msgSender()))), "invalid merkle proof");

    _buy();
  }

  /**
   * @dev Buy a token from the public sale. An account can buy a token only once.
   */
  function publicBuy() external payable {
    // Validates the public sale is active
    require(publicSaleStartTimestamp > 0 && block.timestamp >= publicSaleStartTimestamp, "public sale not active");

    _buy();
  }

  /**
   * @dev Gets the number of tokens available for users to buy
   * @dev Intended to be used as a helper for the UI and raffle
   * @return the number of tokens that can be bought
   */
  function availableTokensForBuy() public view returns (uint256) {
    return MAX_USER_MINT - (NFT.totalSupply() - totalOwnerMint);
  }

  /**
   * @dev Buy a token from the current sale
   */
  function _buy() internal {
    // Validates the user didn't already purchased a token
    require(!participants[_msgSender()], "user already purchased");
    // Validates that the correct amount of ether was sent
    require(msg.value == TOKEN_PRICE, "incorrect value sent");
    // Validates that users don't buy reserved tokens in case the merkle root includes more users than allowed
    require(availableTokensForBuy() > 0, "max user supply reached");

    participants[_msgSender()] = true;

    NFT.mint(_msgSender());
    emit UserPurchased(_msgSender());
  }
}
