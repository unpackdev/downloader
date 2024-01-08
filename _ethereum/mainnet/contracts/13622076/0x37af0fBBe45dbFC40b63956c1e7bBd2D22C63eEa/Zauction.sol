// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ECDSA.sol";
import "./SafeERC20.sol";
import "./IERC721.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./IRegistrar.sol";

contract ZAuction is Initializable, OwnableUpgradeable {
  using ECDSA for bytes32;

  IERC20 public token;
  IRegistrar public registrar;

  // Original zAuction contract address for backward compatibility
  address legacyZAuction;

  struct Listing {
    uint256 price;
    address holder;
  }

  mapping(uint256 => Listing) public priceInfo;
  mapping(address => mapping(uint256 => bool)) public consumed;
  mapping(uint256 => uint256) public topLevelDomainIdCache;
  mapping(uint256 => uint256) public topLevelDomainFee;

  event BidAccepted(
    uint256 auctionId,
    address indexed bidder,
    address indexed seller,
    uint256 amount,
    address nftAddress,
    uint256 tokenId,
    uint256 expireBlock
  );

  event DomainSold(
    address indexed buyer,
    address indexed seller,
    uint256 amount,
    address nftAddress,
    uint256 indexed tokenId
  );

  event BidCancelled(uint256 auctionId, address indexed bidder);

  function getTopLevelId(uint256 tokenId) private returns (uint256) {
    uint256 topLevelId = topLevelDomainIdCache[tokenId];
    if (topLevelId == 0) {
      topLevelId = topLevelDomainIdOf(tokenId);
      topLevelDomainIdCache[tokenId] = topLevelId;
    }
    return topLevelId;
  }

  function initialize(
    IERC20 tokenAddress,
    IRegistrar registrarAddress,
    address legacyZAuctionAddress
  ) public initializer {
    __Ownable_init();
    token = tokenAddress;
    registrar = registrarAddress;
    legacyZAuction = legacyZAuctionAddress;
  }

  /// recovers bidder's signature based on seller's proposed data and, if bid data hash matches the message hash, transfers nft and payment
  /// @param signature type encoded message signed by the bidder
  /// @param auctionId unique per address auction identifier chosen by seller
  /// @param bidder address of who the seller says the bidder is, for confirmation of the recovered bidder
  /// @param bid token amount bid
  /// @param tokenId token id we are transferring
  /// @param minbid minimum bid allowed
  /// @param startBlock block number at which acceptBid starts working
  /// @param expireBlock block number at which acceptBid stops working
  function acceptBid(
    bytes memory signature,
    uint256 auctionId,
    address bidder,
    uint256 bid,
    uint256 tokenId,
    uint256 minbid,
    uint256 startBlock,
    uint256 expireBlock
  ) external {
    require(startBlock <= block.number, "zAuction: auction hasn't started");
    require(expireBlock > block.number, "zAuction: auction expired");
    require(minbid <= bid, "zAuction: cannot accept bid below min");
    require(bidder != msg.sender, "zAuction: cannot sell to self");

    bytes32 data = createBid(
      auctionId,
      bid,
      address(registrar),
      tokenId,
      minbid,
      startBlock,
      expireBlock
    );

    if (bidder != recover(toEthSignedMessageHash(data), signature)) {
      // Encode data with legacy zAuction address for backwards compatibility
      bytes32 legacyData = createLegacyBid(
        auctionId,
        bid,
        address(registrar),
        tokenId,
        minbid,
        startBlock,
        expireBlock
      );
      require(
        bidder == recover(toEthSignedMessageHash(legacyData), signature),
        "zAuction: recovered incorrect bidder"
      );
    }
    require(!consumed[bidder][auctionId], "zAuction: data already consumed");

    consumed[bidder][auctionId] = true;

    // Transfer payment, royalty to minter, and fee to topLevel domain
    paymentTransfers(bidder, bid, msg.sender, getTopLevelId(tokenId), tokenId);

    // Owner -> Bidder, send NFT
    registrar.safeTransferFrom(msg.sender, bidder, tokenId);

    emit BidAccepted(
      auctionId,
      bidder,
      msg.sender,
      bid,
      address(registrar),
      tokenId,
      expireBlock
    );
  }

  function setBuyPrice(uint256 amount, uint256 tokenId) external {
    address owner = registrar.ownerOf(tokenId);
    require(msg.sender == owner, "zAuction: only owner can set price");
    require(
      priceInfo[tokenId].price != amount,
      "zAuction: listing already exists"
    );
    priceInfo[tokenId] = Listing(amount, owner);
  }

  /// recovers buyer's signature based on seller's proposed data and, if bid data hash matches the message hash, transfers nft and payment
  /// @param amount token amount of sale
  /// @param tokenId token id we are transferring
  function buyNow(uint256 amount, uint256 tokenId) external {
    require(amount == priceInfo[tokenId].price, "zAuction: wrong sale price");
    address seller = registrar.ownerOf(tokenId);
    require(msg.sender != seller, "zAuction: cannot sell to self");
    require(
      priceInfo[tokenId].holder == seller,
      "zAuction: not listed for sale"
    );
    require(priceInfo[tokenId].price != 0, "zAuction: item not for sale");

    // Transfer payment, royalty to minter, and fee to topLevel domain
    paymentTransfers(
      msg.sender,
      amount,
      seller,
      getTopLevelId(tokenId),
      tokenId
    );

    priceInfo[tokenId].price = 0;

    // Owner -> message sender, send NFT
    registrar.safeTransferFrom(seller, msg.sender, tokenId);

    emit DomainSold(msg.sender, seller, amount, address(registrar), tokenId);
  }

  /// Cancels an existing bid for an NFT by marking it as already consumed
  /// so that it can never be fulfilled.
  /// @param account The account that made the specific bid
  /// @param auctionId The ID of the auction associated with that bid
  function cancelBid(address account, uint256 auctionId) external {
    require(
      msg.sender == account,
      "zAuction: Cannot cancel someone else's bid"
    );
    require(
      !consumed[account][auctionId],
      "zAuction: Cannot cancel an already consumed bid"
    );

    consumed[account][auctionId] = true;

    emit BidCancelled(auctionId, account);
  }

  /// Allows the owner of the given token to set the fee owed upon sale
  /// Amount given should be as a percent with 5 decimals of precision
  /// e.g. 10% (max) is 1000000, 0.0001% (min) is 1
  /// @param id The id of the domain to update
  /// @param amount The
  function setTopLevelDomainFee(uint256 id, uint256 amount) public {
    require(
      msg.sender == registrar.ownerOf(id),
      "zAuction: Cannot set fee on unowned domain"
    );
    require(amount <= 1000000, "zAuction: Cannot set a fee higher than 10%");
    require(amount != topLevelDomainFee[id], "zAuction: Amount is already set");
    topLevelDomainFee[id] = amount;
  }

  /// Fetch the top level domain fee if it exists and calculate the token amount
  /// @param topLevelId The id of the top level domain for a subdomain
  /// @param bid The bid for the fee to apply to
  function calculateTopLevelDomainFee(uint256 topLevelId, uint256 bid)
    public
    view
    returns (uint256)
  {
    require(topLevelId > 0, "zAuction: must provide a valid id");
    require(bid > 0, "zAuction: Cannot calculate domain fee on an empty bid");

    // Find what percent they've specified as a royalty
    uint256 fee = topLevelDomainFee[topLevelId];
    if (fee == 0) return 0;

    uint256 calculatedFee = (bid * fee * 10**13) / (100 * 10**18);

    return calculatedFee;
  }

  /// Fetch the minter royalty if it exists and calculate the token amount
  /// @param bid The bid for the royalty to be calculated
  /// @param id The id of the minted domain
  function calculateMinterRoyalty(uint256 id, uint256 bid)
    public
    pure
    returns (uint256)
  {
    require(id > 0, "zAuction: must provide a valid id");
    uint256 domainRoyalty = 1000000;
    uint256 royalty = (bid * domainRoyalty * 10**13) / (100 * 10**18);

    return royalty;
  }

  /// Create a bid object hashed with the current contract address
  /// @param auctionId unique per address auction identifier chosen by seller
  /// @param bid token amount bid
  /// @param nftAddress address of the nft contract
  /// @param tokenId token id we are transferring
  /// @param minbid minimum bid allowed
  /// @param startBlock block number at which acceptBid starts working
  /// @param expireBlock block number at which acceptBid stops working
  function createBid(
    uint256 auctionId,
    uint256 bid,
    address nftAddress,
    uint256 tokenId,
    uint256 minbid,
    uint256 startBlock,
    uint256 expireBlock
  ) public view returns (bytes32 data) {
    data = keccak256(
      abi.encode(
        auctionId,
        address(this),
        block.chainid,
        bid,
        nftAddress,
        tokenId,
        minbid,
        startBlock,
        expireBlock
      )
    );
    return data;
  }

  /// Create a bid object hashed with the legacy contract address
  /// for backwards compatability.
  /// @param auctionId unique per address auction identifier chosen by seller
  /// @param bid token amount bid
  /// @param nftAddress address of the nft contract
  /// @param tokenId token id we are transferring
  /// @param minbid minimum bid allowed
  /// @param startBlock block number at which acceptBid starts working
  /// @param expireBlock block number at which acceptBid stops working
  function createLegacyBid(
    uint256 auctionId,
    uint256 bid,
    address nftAddress,
    uint256 tokenId,
    uint256 minbid,
    uint256 startBlock,
    uint256 expireBlock
  ) public view returns (bytes32 data) {
    data = keccak256(
      abi.encode(
        auctionId,
        legacyZAuction,
        block.chainid,
        bid,
        nftAddress,
        tokenId,
        minbid,
        startBlock,
        expireBlock
      )
    );
    return data;
  }

  // Will return self if already at the top level
  function topLevelDomainIdOf(uint256 id) public view returns (uint256) {
    uint256 parentId = registrar.parentOf(id);
    uint256 holder = id;
    while (parentId != 0) {
      holder = parentId; // Hold on to previous parent
      parentId = registrar.parentOf(parentId);
    }
    return holder;
  }

  /// Recover an account from a signature hash
  /// @param hash the bytes object
  /// @param signature the signature to recover from
  function recover(bytes32 hash, bytes memory signature)
    public
    pure
    returns (address)
  {
    return hash.recover(signature);
  }

  function toEthSignedMessageHash(bytes32 hash) public pure returns (bytes32) {
    return hash.toEthSignedMessageHash();
  }

  /// Send all required payment transfers when an NFT is sold
  /// This requires paying the owner, minter, and top level domain owner
  /// @param bidder address of who the seller says the bidder is, for confirmation of the recovered bidder
  /// @param bid token amount bid
  /// @param owner address of the owner of that domain pre-transfer
  /// @param topLevelId the ID of the top level domain for a given domain or subdomain
  /// @param tokenId the ID of the domain
  function paymentTransfers(
    address bidder,
    uint256 bid,
    address owner,
    uint256 topLevelId,
    uint256 tokenId
  ) internal {
    address topLevelOwner = registrar.ownerOf(topLevelId);
    uint256 topLevelFee = calculateTopLevelDomainFee(topLevelId, bid);
    uint256 minterRoyalty = calculateMinterRoyalty(tokenId, bid);

    uint256 bidActual = bid - minterRoyalty - topLevelFee;

    // Bidder -> Owner, pay transaction
    SafeERC20.safeTransferFrom(token, bidder, owner, bidActual);

    // Bidder -> Minter, pay minter royalty
    SafeERC20.safeTransferFrom(
      token,
      bidder,
      registrar.minterOf(tokenId),
      minterRoyalty
    );

    // Bidder -> topLevel Owner, pay top level owner fee
    SafeERC20.safeTransferFrom(token, bidder, topLevelOwner, topLevelFee);
  }
}
