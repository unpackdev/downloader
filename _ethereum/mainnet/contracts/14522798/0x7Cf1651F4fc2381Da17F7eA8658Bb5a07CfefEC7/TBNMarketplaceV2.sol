pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./IERC721.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./SafeERC20.sol";
import "./ERC721Holder.sol";
import "./AccessControl.sol";
import "./SafeMath.sol";
import "./EnumerableSet.sol";
import "./ReentrancyGuard.sol";
import "./AggregatorV3Interface.sol";
import "./ISimpleOracle.sol";
import "./ITBNERC721.sol";
import "./IChainLinkOracle.sol";

// Token Backed NFTs Marketplace
contract TNFTMarketplace is ERC721Holder, AccessControl, ReentrancyGuard {
  using EnumerableSet for EnumerableSet.UintSet;
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  bytes32 public constant ROLE_ADMIN = keccak256("ROLE_ADMIN");
  address public treasuryWallet;
  address public tbnNftAddress;
  address public wethAddress;
  IChainLinkOracle public chainLink;
  ISimpleOracle public oracle;
  uint256 public basisPointFee;
  uint256 public nextListingId;
  uint256 public errorMarginBasisPoint = 500;

  struct Listing {
    address ownerAddress;
    address nftTokenAddress;
    address paymentTokenAddress;
    uint256 priceBandBasisPoint;
    uint256 nftTokenId;
    uint256 fixedPrice; // min price listing is willing to sell for or payment amount if not price bound
    bool isPriceBound; // if true then price is bound to marketplace
  }

  mapping(uint256 => Listing) public listings;
  mapping(address => uint256[]) public sellerListings; // Get all TBNS for an address

  EnumerableSet.UintSet private listingIds;

  event ListingCreated(
    address ownerAddress,
    address nftTokenAddress,
    address TBNAddress,
    address paymentTokenAddress,
    uint256 TBNAmount,
    uint256 priceBandBasisPoint,
    uint256 nftTokenId,
    uint256 listingId,
    uint256 fixedPrice,
    bool isPriceBound
  );
  event ListingRemoved(uint256 listingId);
  event ListingSold(
    uint256 listingId,
    uint256 tbnTokenId,
    uint256 tbnTokenAmount,
    uint256 paymentTokenAmount,
    address tbnTokenAddress,
    address paymentTokenAddress,
    address buyer,
    address seller
  );

  modifier onlyAdmin() {
    require(hasRole(ROLE_ADMIN, msg.sender), "Sender is not admin");
    _;
  }

  constructor(
    address _admin,
    address payable _treasuryWallet,
    address _tbnNFTAddress,
    address _oracleAddress,
    address _chainLinkAddress,
    address _wethAddress,
    uint256 _basisPointFee
  ) {
    require(_admin != address(0), "Admin wallet cannot be 0 address");
    require(
      _treasuryWallet != address(0),
      "Treasury wallet cannot be 0 address"
    );
    require(_tbnNFTAddress != address(0), "TBN address cannot be 0 address");
    require(_oracleAddress != address(0), "Uniswap oracle cannot be 0 address");
    require(
      _chainLinkAddress != address(0),
      "Chainlink oracle cannot be 0 address"
    );
    require(_wethAddress != address(0), "Weth address cannot be 0 address");
    require(_basisPointFee < 10000, "Basis point fee must be less than 10000");
    _setupRole(ROLE_ADMIN, _admin);
    _setRoleAdmin(ROLE_ADMIN, ROLE_ADMIN);

    treasuryWallet = _treasuryWallet;
    tbnNftAddress = _tbnNFTAddress;

    oracle = ISimpleOracle(_oracleAddress);
    chainLink = IChainLinkOracle(_chainLinkAddress);

    basisPointFee = _basisPointFee;
    wethAddress = _wethAddress;
  }

  function updateWethAddress(address newWeth) external onlyAdmin {
    require(newWeth != address(0), "Weth cannot be 0 address");
    wethAddress = newWeth;
  }

  function updateOracleAddress(address newOracle) external onlyAdmin {
    require(newOracle != address(0), "Uniswap oracle cannot be 0 address");
    oracle = ISimpleOracle(newOracle);
  }

  function updateChainLinkOracleAddress(address newChainLinkOracle)
    external
    onlyAdmin
  {
    require(
      newChainLinkOracle != address(0),
      "Chainlink oracle cannot be 0 address"
    );
    chainLink = IChainLinkOracle(newChainLinkOracle);
  }

  function updateErrorMarginBasisPoint(uint256 newErrorMarginBasisPoint)
    external
    onlyAdmin
  {
    require(
      newErrorMarginBasisPoint <= 10000,
      "Error margin must be less than 10,000"
    );
    errorMarginBasisPoint = newErrorMarginBasisPoint;
  }

  function updateTbnNftAddress(address _tbnNftAddress) external onlyAdmin {
    require(_tbnNftAddress != address(0), "TBN address cannot be 0");
    tbnNftAddress = _tbnNftAddress;
  }

  /**
    Update the basisPointFee. For example, if you want a 2.5% fee set _basisPointFee to be 250
  */
  function updateBasisPointFee(uint256 _basisPointFee) external onlyAdmin {
    require(_basisPointFee <= 10000, "Basis point cannot be more than 10,000");
    basisPointFee = _basisPointFee;
  }

  /**
    Update the treasuryWallet address
  */
  function updateTreasuryWalletAddress(address payable _treasuryWallet)
    external
    onlyAdmin
  {
    require(
      _treasuryWallet != address(0),
      "Treasury wallet cannot be 0 address"
    );
    treasuryWallet = _treasuryWallet;
  }

  // Get number of listings
  function getNumListings() external view returns (uint256) {
    return listingIds.length();
  }

  /**
   * @dev Get listing ID by user
   *
   * Params:
   * @param userAddress: address of user
   */
  function getListingIdsByUser(address userAddress)
    external
    view
    returns (uint256[] memory)
  {
    return sellerListings[userAddress];
  }

  /**
   * @dev Get listing with listings id
   *
   * Params:
   * @param ids: array of listing ids
   */
  function getListingsByListingIds(uint256[] calldata ids)
    external
    view
    returns (Listing[] memory)
  {
    Listing[] memory userListings = new Listing[](ids.length);
    for (uint256 i = 0; i < userListings.length; i++) {
      userListings[i] = listings[ids[i]];
    }
    return userListings;
  }

  /**
   * @dev Get listing ID at index
   *
   * Params:
   * index: index of ID
   */
  function getListingIds(uint256 index) external view returns (uint256) {
    return listingIds.at(index);
  }

  /**
   * @dev Get listing correlated to index
   *
   * Params:
   * index: index of ID
   */
  function getListingAtIndex(uint256 index)
    external
    view
    returns (Listing memory)
  {
    return listings[listingIds.at(index)];
  }

  /**
      Create a new listing.
      @param nftTokenAddress Address of the contract of the NFT
      @param paymentTokenAddress Address of the requested payment token
      @param priceBandBasisPoint Amount of paymentTokenAddress for payment
      @param nftTokenId id of the NFT
      @param fixedPrice Min amount willing to sell for
      @param priceBound true if price is bound to market price
  */
  function listTBNTokens(
    address nftTokenAddress,
    address paymentTokenAddress,
    uint256 priceBandBasisPoint,
    uint256 nftTokenId,
    uint256 fixedPrice,
    bool priceBound
  ) external nonReentrant {
    require(nftTokenAddress == tbnNftAddress, "Only TBN NFTs can be listed");
    ITBNERC721 token = ITBNERC721(nftTokenAddress);
    // Get TBN data
    (address TBNAddress, uint256 TBNAmount) = token.nftsToTokenData(nftTokenId);
    // should not be able to list with contained token
    require(
      paymentTokenAddress != TBNAddress,
      "The same pair of tokens cannot be listed"
    );
    token.safeTransferFrom(msg.sender, address(this), nftTokenId);

    uint256 listingId = generateListingId();
    listings[listingId] = Listing(
      msg.sender,
      nftTokenAddress,
      paymentTokenAddress,
      priceBandBasisPoint,
      nftTokenId,
      fixedPrice,
      priceBound
    );
    listingIds.add(listingId);
    sellerListings[msg.sender].push(listingId);

    emit ListingCreated(
      msg.sender,
      nftTokenAddress,
      TBNAddress,
      paymentTokenAddress,
      TBNAmount,
      priceBandBasisPoint,
      nftTokenId,
      listingId,
      fixedPrice,
      priceBound
    );
  }

  /**
    Remove a listing.
        @param listingId id of listing
    */
  function removeListing(uint256 listingId) external {
    require(listingIds.contains(listingId), "Listing does not exist.");
    Listing memory listing = listings[listingId];
    require(
      msg.sender == listing.ownerAddress,
      "You must be the person who created the listing"
    );

    IERC721 token = IERC721(listing.nftTokenAddress);
    token.safeTransferFrom(
      address(this),
      listing.ownerAddress,
      listing.nftTokenId
    );
    listingIds.remove(listingId);

    _removeFromSellersListings(listingId);

    emit ListingRemoved(listingId);
  }

  /**
        Buy listing.
        @param listingId id of listing
    */
  function buyToken(uint256 listingId, uint256 expectedPaymentAmount)
    external
    payable
    nonReentrant
  {
    require(listingIds.contains(listingId), "Listing does not exist.");
    Listing storage listing = listings[listingId];
    // Get TBN data
    ITBNERC721 token = ITBNERC721(listing.nftTokenAddress);
    (address TBNAddress, uint256 TBNAmount) = token.nftsToTokenData(
      listing.nftTokenId
    );
    require(TBNAmount > 0, "TBN does not contain any tokens");
    uint256 fullCost;

    if (!listing.isPriceBound) {
      fullCost = listing.fixedPrice;
    } else {
      // paymentTokensPerTBNToken should have extra 18 decimals to keep precision
      uint256 paymentTokensPerTBNToken;
      // get the decimals for both tokens
      uint8 tbnTokenDecimals = 18;
      uint8 paymentTokenDecimals = 18;
      uint256 tbnPrice;
      uint256 paymentPrice;
      bool isNative = false;

      if (
        chainLink.hasToken(listing.paymentTokenAddress) &&
        chainLink.hasToken(TBNAddress)
      ) {
        // both tokens exist in chainlink oracle
        // native token will always exist in chainlink
        tbnPrice = chainLink.getLatestPrice(TBNAddress);
        paymentPrice = chainLink.getLatestPrice(listing.paymentTokenAddress);
        paymentTokensPerTBNToken = (tbnPrice * 1 ether) / paymentPrice;
      } else if (
        listing.paymentTokenAddress == address(0) ||
        listing.paymentTokenAddress == wethAddress
      ) {
        isNative = true;
        // tbn address is not on chainlink
        (uint256 tbnWETHReserves, uint256 tbnTokenReserves) = oracle
          .getReservesForTokenPool(TBNAddress);
        tbnPrice = (tbnWETHReserves * 1 ether) / tbnTokenReserves;
        // payment token is native token
        // WETH to ETH is 1 to 1
        paymentPrice = 1 ether;
        // for when paymentTokenDecimals != 18
        paymentTokensPerTBNToken = (tbnPrice * 1 ether) / paymentPrice;
      } else if (TBNAddress == address(0) || TBNAddress == wethAddress) {
        isNative = true;
        // tbn token is native token
        // WETH to ETH is 1 to 1
        tbnPrice = 1 ether;
        // payment token is not on chainlink
        (uint256 paymentWETHReserves, uint256 paymentTokenReserves) = oracle
          .getReservesForTokenPool(listing.paymentTokenAddress);
        paymentPrice = (paymentWETHReserves * 1 ether) / paymentTokenReserves;
        paymentTokensPerTBNToken = (tbnPrice * 1 ether) / paymentPrice;
      } else {
        // both tokens are not native and do not exist on chainlink
        paymentTokensPerTBNToken = oracle.getTokenPrice(
          TBNAddress,
          listing.paymentTokenAddress
        );
      }

      // only update decimals for non native tokens
      if (TBNAddress != address(0)) {
        tbnTokenDecimals = IERC20Metadata(TBNAddress).decimals();
      }
      if (listing.paymentTokenAddress != address(0)) {
        paymentTokenDecimals = IERC20Metadata(listing.paymentTokenAddress)
          .decimals();
      }

      // handle decimal diff
      if (paymentTokenDecimals > tbnTokenDecimals && !isNative) {
        fullCost =
          (paymentTokensPerTBNToken *
            TBNAmount *
            listing.priceBandBasisPoint *
            (10**(paymentTokenDecimals - tbnTokenDecimals))) /
          (10000 * (1 ether));
        // 10**18 to remove extra decimals from oracle price
      } else if (tbnTokenDecimals > paymentTokenDecimals && !isNative) {
        fullCost =
          (paymentTokensPerTBNToken * TBNAmount * listing.priceBandBasisPoint) /
          (10000 * (1 ether) * (10**(tbnTokenDecimals - paymentTokenDecimals)));
        // 10**18 to remove extra decimals from oracle price
      } else {
        fullCost =
          (paymentTokensPerTBNToken * TBNAmount * listing.priceBandBasisPoint) /
          (10000 * (1 ether));
        // 10**18 to remove extra decimals from oracle price
      }

      if (fullCost < listing.fixedPrice) {
        fullCost = listing.fixedPrice;
      }
    }

    // check if correct price
    require(
      expectedPaymentAmount <
        ((fullCost * (10000 + errorMarginBasisPoint)) / 10000),
      "Oracle price above error margin"
    );
    require(
      expectedPaymentAmount >
        ((fullCost * (10000 - errorMarginBasisPoint)) / 10000),
      "Oracle price below error margin"
    );

    uint256 payoutToTreasury = (fullCost.mul(basisPointFee)).div(10000);
    uint256 payoutToSeller = fullCost.sub(payoutToTreasury);

    IERC20 paymentToken = IERC20(listing.paymentTokenAddress);

    if (listing.paymentTokenAddress == address(0)) {
      require(msg.value >= fullCost, "Incorrect transaction value.");
      if (msg.value > fullCost) {
        payable(msg.sender).transfer(msg.value - fullCost);
      }
      payable(listing.ownerAddress).transfer(payoutToSeller);
      payable(treasuryWallet).transfer(payoutToTreasury);
    } else {
      paymentToken.safeTransferFrom(
        msg.sender,
        listing.ownerAddress,
        payoutToSeller
      );
      paymentToken.safeTransferFrom(
        msg.sender,
        treasuryWallet,
        payoutToTreasury
      );
    }
    token.safeTransferFrom(address(this), msg.sender, listing.nftTokenId);

    listingIds.remove(listingId);
    _removeFromSellersListings(listingId);
    emit ListingSold(
      listingId,
      listing.nftTokenId,
      TBNAmount,
      fullCost,
      TBNAddress,
      listing.paymentTokenAddress,
      msg.sender,
      listing.ownerAddress
    );
  }

  // Generate ID for next listing
  function generateListingId() internal returns (uint256) {
    return nextListingId++;
  }

  /** Internal funtions */
  function _removeFromSellersListings(uint256 listingId) internal {
    for (uint256 i = 0; i < sellerListings[msg.sender].length; i++) {
      if (sellerListings[msg.sender][i] == listingId) {
        delete sellerListings[msg.sender][i];
        return;
      }
    }
  }
}
