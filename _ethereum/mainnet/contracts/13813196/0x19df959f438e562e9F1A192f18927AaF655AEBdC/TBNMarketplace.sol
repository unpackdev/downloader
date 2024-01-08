pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

import "./IERC721.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ERC721Holder.sol";
import "./AccessControl.sol";
import "./SafeMath.sol";
import "./EnumerableSet.sol";
import "./ReentrancyGuard.sol";

import "./console.sol";

// Token Backed NFTs Marketplace
contract TBNMarketplace is ERC721Holder, AccessControl, ReentrancyGuard {
  using EnumerableSet for EnumerableSet.UintSet;
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  bytes32 public constant ROLE_ADMIN = keccak256("ROLE_ADMIN");
  address payable public treasuryWallet;
  address payable public charityWallet;
  uint256 public basisPointFee;
  uint256 public nextListingId;

  struct Listing {
    address payable ownerAddress;
    address nftTokenAddress;
    address paymentTokenAddress;
    uint256 paymentAmount;
    uint256 nftTokenId;
    uint256 charityBasisPoint;
  }

  mapping(uint256 => Listing) public listings;
  EnumerableSet.UintSet private listingIds;

  event ListingCreated(
    address ownerAddress,
    address nftTokenAddress,
    address paymentTokenAddress,
    uint256 paymentAmount,
    uint256 nftTokenId,
    uint256 listingId,
    uint256 charityBasisPoint
  );
  event ListingRemoved(uint256 listingId);

  modifier onlyAdmin {
    require(hasRole(ROLE_ADMIN, msg.sender), "Sender is not admin");
    _;
  }

  constructor(
    address _admin,
    address payable _treasuryWallet,
    address payable _charityWallet,
    uint256 _basisPointFee
  ) public {
    require(_treasuryWallet != address(0), "Treasury wallet cannot be 0 address");
    _setupRole(ROLE_ADMIN, _admin);
    _setRoleAdmin(ROLE_ADMIN, ROLE_ADMIN);

    treasuryWallet = _treasuryWallet;
    charityWallet = _charityWallet;
    basisPointFee = _basisPointFee;
  }

  /**
    Update the basisPointFee. For example, if you want a 2.5% fee set _basisPointFee to be 250
  */
  function updateBasisPointFee(uint256 _basisPointFee) external onlyAdmin() {
    basisPointFee = _basisPointFee;
  }

  /**
    Update the charityWallet address
  */
  function updateCharityWalletAddress(address payable _charityWallet) external onlyAdmin() {
    charityWallet = _charityWallet;
  }

  /**
    Update the treasuryWallet address
  */
  function updateTreasuryWalletAddress(address payable _treasuryWallet) external onlyAdmin() {
    treasuryWallet = _treasuryWallet;
  }

  // Get number of listings
  function getNumListings() external view returns (uint256) {
    return listingIds.length();
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
  function getListingAtIndex(uint256 index) external view returns (Listing memory) {
    return listings[listingIds.at(index)];
  }

  /**
    Create a new listing.

    @param nftTokenAddress Address of the contract of the NFT
    @param paymentTokenAddress Address of the requested payment token
    @param paymentAmount Amount of paymentTokenAddress for payment
    @param nftTokenId id of the NFT
    @param charityBasisPoint Basis point fee given to charity
  */
  function listTBNTokens(
    address nftTokenAddress,
    address paymentTokenAddress,
    uint256 paymentAmount,
    uint256 nftTokenId,
    uint256 charityBasisPoint
  ) external nonReentrant() {
    require((basisPointFee + charityBasisPoint) <= 10000, "Your charity basisPoint is too high");

    IERC721 token = IERC721(nftTokenAddress);
    token.safeTransferFrom(msg.sender, address(this), nftTokenId);

    uint256 listingId = generateListingId();
    listings[listingId] = Listing(
      msg.sender,
      nftTokenAddress,
      paymentTokenAddress,
      paymentAmount,
      nftTokenId,
      charityBasisPoint
    );
    listingIds.add(listingId);

    emit ListingCreated(
      msg.sender,
      nftTokenAddress,
      paymentTokenAddress,
      paymentAmount,
      nftTokenId,
      listingId,
      charityBasisPoint
    );
  }

  /**
    Remove a listing.

    @param listingId id of listing
  */
  function removeListing(uint256 listingId) external {
    require(listingIds.contains(listingId), "Listing does not exist.");
    Listing storage listing = listings[listingId];
    require(msg.sender == listing.ownerAddress, "You must be the person who created the listing");

    IERC721 token = IERC721(listing.nftTokenAddress);
    token.safeTransferFrom(address(this), listing.ownerAddress, listing.nftTokenId, "");
    listingIds.remove(listingId);

    emit ListingRemoved(listingId);
  }

  /**
    Buy listing.

    @param listingId id of listing
  */
  function buyToken(uint256 listingId) external payable nonReentrant() {
    require(listingIds.contains(listingId), "Listing does not exist.");

    Listing storage listing = listings[listingId];
    address paymentTokenAddress = listing.paymentTokenAddress;

    uint256 fullCost = listing.paymentAmount;
    uint256 payoutToSeller =
      (fullCost.mul((10000 - basisPointFee - listing.charityBasisPoint))).div(10000);
    uint256 payoutToTreasury = (fullCost.mul(basisPointFee)).div(10000);
    uint256 payoutToCharity = (fullCost.mul((listing.charityBasisPoint))).div(10000);

    if (paymentTokenAddress == address(0)) {
      require(msg.value == fullCost, "Incorrect transaction value.");

      listing.ownerAddress.transfer(payoutToSeller);
      treasuryWallet.transfer(payoutToTreasury);
      charityWallet.transfer(payoutToCharity);
    } else {
      IERC20 paymentToken = IERC20(paymentTokenAddress);

      paymentToken.transferFrom(msg.sender, listing.ownerAddress, payoutToSeller);
      paymentToken.transferFrom(msg.sender, treasuryWallet, payoutToTreasury);
      paymentToken.transferFrom(msg.sender, charityWallet, payoutToCharity);
    }

    IERC721 token = IERC721(listing.nftTokenAddress);
    token.safeTransferFrom(address(this), msg.sender, listing.nftTokenId, "");

    listingIds.remove(listingId);
    emit ListingRemoved(listingId);
  }

  // Generate ID for next listing
  function generateListingId() internal returns (uint256) {
    return nextListingId++;
  }
}
