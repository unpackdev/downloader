// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./Strings.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./IRegistrar.sol";
import "./IZNSHub.sol";

contract ClaimWithChildSale is Initializable, OwnableUpgradeable {
  // zNS Hub
  IZNSHub public zNSHub;

  IRegistrar public newDomainRegistrar;

  event RefundedEther(address buyer, uint256 amount);

  event SaleStarted(uint256 block);

  // Domains under this parent will be allowed to make claims.
  uint256 public claimingParentId;

  // The parent domain to mint sold domains under
  uint256 public newDomainParentId;

  // Price of each domain to be sold
  uint256 public salePrice;

  // The wallet to transfer proceeds to
  address public sellerWallet;

  // Total number of domains to be sold
  uint256 public totalForSale;

  // Number of domains sold so far
  uint256 public domainsSold;

  // Indicating whether the sale has started or not
  bool public saleStarted;

  // The block number that a sale started on
  uint256 public saleStartBlock;

  // If a sale has been paused
  bool public paused;

  // The number with which to start the metadata index (e.g. number is 100, so indicies are 100, 101, ...)
  uint256 public startingMetadataIndex;

  // The ID of the folder group that has been set up for this sale - needs to be initialized in advance
  uint256 public folderGroupID;

  // Time in blocks that the claiming period will occur
  uint256 public saleDuration;

  // Mapping to keep track of who has purchased which domain.
  mapping(uint256 => address) public domainsClaimedWithBy;

  function __ClaimWithChildSale_init(
    uint256 newDomainParentId_,
    uint256 price_,
    IZNSHub zNSHub_,
    address sellerWallet_,
    uint256 saleDuration_,
    uint256 startingMetadataIndex_,
    uint256 folderGroupID_,
    uint256 totalForSale_,
    IRegistrar newDomainRegistrar_,
    uint256 claimingParentId_
  ) public initializer {
    __Ownable_init();

    newDomainParentId = newDomainParentId_;
    salePrice = price_;
    zNSHub = zNSHub_;
    sellerWallet = sellerWallet_;
    startingMetadataIndex = startingMetadataIndex_;
    folderGroupID = folderGroupID_;
    saleDuration = saleDuration_;
    totalForSale = totalForSale_;
    newDomainRegistrar = newDomainRegistrar_;
    claimingParentId = claimingParentId_;
  }

  function setHub(IZNSHub zNSHub_) external onlyOwner {
    require(zNSHub != zNSHub_, "Same hub");
    zNSHub = zNSHub_;
  }

  // Start the sale if not started
  function startSale() external onlyOwner {
    require(!saleStarted, "Sale already started");
    saleStarted = true;
    saleStartBlock = block.number;
    emit SaleStarted(saleStartBlock);
  }

  // Stop the sale if started
  function stopSale() external onlyOwner {
    require(saleStarted, "Sale not started");
    saleStarted = false;
  }

  // Pause a sale
  function setPauseStatus(bool pauseStatus) external onlyOwner {
    require(paused != pauseStatus, "No state change");
    paused = pauseStatus;
  }

  // Set the price of this sale
  function setSalePrice(uint256 price) external onlyOwner {
    require(salePrice != price, "No price change");
    salePrice = price;
  }

  // Modify the address of the seller wallet
  function setSellerWallet(address wallet) external onlyOwner {
    require(wallet != sellerWallet, "Same Wallet");
    sellerWallet = wallet;
  }

  // Modify parent domain ID of a domain
  function setNewDomainParentId(uint256 parentId) external onlyOwner {
    require(newDomainParentId != parentId, "Same parent id");
    newDomainParentId = parentId;
  }

  function setClaimingParentId(uint256 parentId) external onlyOwner {
    require(claimingParentId != parentId, "Same parent id");
    claimingParentId = parentId;
  }

  // Update the number of blocks that the sale will occur
  function setSaleDuration(uint256 durationInBlocks) external onlyOwner {
    require(saleDuration != durationInBlocks, "No state change");
    saleDuration = durationInBlocks;
  }

  // Set the number with which to start the metadata index (e.g. number is 100, so indicies are 100, 101, ...)
  function setStartIndex(uint256 index) external onlyOwner {
    require(index != startingMetadataIndex, "Cannot set to the same index");
    startingMetadataIndex = index;
  }

  // Set the hash of the base IPFS folder that contains the domain metadata
  function setFolderGroupID(uint256 folderGroupID_) external onlyOwner {
    require(folderGroupID != folderGroupID_, "Cannot set to same folder group");
    folderGroupID = folderGroupID_;
  }

  // Add new metadata URIs to be sold
  function setAmountOfDomainsForSale(uint256 forSale) public onlyOwner {
    totalForSale = forSale;
  }

  function setNewDomainRegistrar(IRegistrar newDomainRegistrar_) public {
    require(newDomainRegistrar != newDomainRegistrar_, "No state change");
    newDomainRegistrar = newDomainRegistrar_;
  }

  // Remove a domain from this sale
  function releaseDomain() external onlyOwner {
    IRegistrar zNSRegistrar = zNSHub.getRegistrarForDomain(newDomainParentId);
    zNSRegistrar.transferFrom(address(this), owner(), newDomainParentId);
  }

  // Purchase `count` domains
  // Not the `purchaseLimit` you provide must be
  // less than or equal to what is in the mintlist
  function claimDomains(uint256[] calldata claimingIds) public payable {
    _canAccountClaim(claimingIds);
    _claimDomains(claimingIds);
  }

  function _canAccountClaim(uint256[] calldata claimingIds) internal view {
    require(claimingIds.length > 0, "Zero purchase count");
    require(domainsSold < totalForSale, "No domains left for claim");
    require(
      msg.value >= salePrice * claimingIds.length,
      "Not enough funds in purchase"
    );
    require(!paused, "paused");
    require(saleStarted, "Sale hasn't started or has ended");
    require(block.number <= saleStartBlock + saleDuration, "Sale has ended");
    for (uint256 i = 0; i < claimingIds.length; i++) {
      require(
        domainsClaimedWithBy[claimingIds[i]] == address(0),
        "NFT already claimed"
      );
      IRegistrar zNSRegistrar = zNSHub.getRegistrarForDomain(claimingIds[i]);
      require(
        zNSHub.ownerOf(claimingIds[i]) == msg.sender,
        "Claiming with unowned NFT"
      );
      require(
        zNSRegistrar.parentOf(claimingIds[i]) == claimingParentId,
        "Claiming with ineligible NFT"
      );
    }
  }

  function _claimDomains(uint256[] calldata claimingIds) internal {
    uint256 numPurchased = _reserveDomainsForPurchase(claimingIds.length);
    uint256 proceeds = salePrice * numPurchased;
    if (proceeds > 0) {
      _sendPayment(proceeds);
    }
    _mintDomains(numPurchased, claimingIds);
  }

  function _reserveDomainsForPurchase(uint256 count)
    internal
    returns (uint256)
  {
    uint256 numPurchased = count;
    // If we are trying to purchase more than is available, purchase the remainder
    if (domainsSold + count > totalForSale) {
      numPurchased = totalForSale - domainsSold;
    }
    domainsSold += numPurchased;

    return numPurchased;
  }

  // Transfer funds to the buying user, refunding if necessary
  function _sendPayment(uint256 proceeds) internal {
    payable(sellerWallet).transfer(proceeds);

    // Send refund if neceesary for any unclaimed domains
    if (msg.value - proceeds > 0) {
      payable(msg.sender).transfer(msg.value - proceeds);
      emit RefundedEther(msg.sender, msg.value - proceeds);
    }
  }

  function _mintDomains(uint256 numPurchased, uint256[] calldata claimingIds)
    internal
  {
    // Mint the domains after they have been claimed
    uint256 startingIndex = startingMetadataIndex + domainsSold - numPurchased;

    newDomainRegistrar.registerDomainInGroupBulk(
      newDomainParentId, //parentId
      folderGroupID, //groupId
      0, //namingOffset
      startingIndex, //startingIndex
      startingIndex + numPurchased, //endingIndex
      sellerWallet, //minter
      0, //royaltyAmount
      msg.sender //sendTo
    );
    for (uint256 i = 0; i < numPurchased; ++i) {
      domainsClaimedWithBy[claimingIds[i]] = msg.sender;
    }
  }
}
