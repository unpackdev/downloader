// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./Strings.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./IRegistrar.sol";
import "./MerkleProofUpgradeable.sol";

contract AirWild2Sale is Initializable, OwnableUpgradeable {
  // zNS Registrar
  IRegistrar public zNSRegistrar;

  event RefundedEther(address buyer, uint256 amount);

  event SaleStarted(uint256 block);

  // The parent domain to mint sold domains under
  uint256 public parentDomainId;

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

  // The containing folder hash without a Qm prefix
  string public baseFolderHash;

  // Merkle root data to verify on mintlist
  bytes32[] public mintlistMerkleRoots;

  // Time in blocks that each mintlist will last (in order)
  uint256[] public mintlistDurations;

  // There are multiple mintlists in this sale. Which one are we using now?
  uint256 public currentMerkleRootIndex;

  // Mapping to keep track of how many domains an account has purchased so far
  mapping(address => uint256) public domainsPurchasedByAccount;

  function __AirWild2Sale_init(
    uint256 parentDomainId_,
    uint256 price_,
    IRegistrar zNSRegistrar_,
    address sellerWallet_,
    uint256[] memory mintlistDurations_,
    bytes32[] memory merkleRoots_,
    uint256 startingMetadataIndex_,
    string calldata baseFolderHash_, // in the following format: ipfs://Qm.../
    uint256 numForSale_
  ) public initializer {
    __Ownable_init();

    require(mintlistDurations_.length == merkleRoots_.length, "Mintlist and merkle mismatch");

    parentDomainId = parentDomainId_;
    salePrice = price_;
    zNSRegistrar = zNSRegistrar_;
    sellerWallet = sellerWallet_;
    mintlistDurations = mintlistDurations_;
    mintlistMerkleRoots = merkleRoots_;
    startingMetadataIndex = startingMetadataIndex_;
    baseFolderHash = baseFolderHash_;
    totalForSale = numForSale_;
  }

  function setRegistrar(IRegistrar zNSRegistrar_) external onlyOwner {
    require(zNSRegistrar != zNSRegistrar_, "Same registrar");
    require(address(zNSRegistrar_) != address(0), "Registrar not initialized");
    zNSRegistrar = zNSRegistrar_;
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

  // Update the merkle list roots
  function setMerkleRules(bytes32[] memory mintlistMerkleRoots_, uint256[] memory mintlistDurations_) external onlyOwner {
    require(mintlistMerkleRoots_.length == mintlistDurations_.length, "List length mismatch");
    require(mintlistMerkleRoots_.length > 0, "Empty roots array");
    // Assume lists are equivalent...
    bool listsAreEquivalent = mintlistMerkleRoots.length == mintlistMerkleRoots_.length;
    if(listsAreEquivalent){
      for(uint256 i = 0; i < mintlistMerkleRoots_.length; i++){
        // ...until proven otherwise
        if(mintlistMerkleRoots[i] != mintlistMerkleRoots_[i] || mintlistDurations_[i] != mintlistDurations[i]){
          listsAreEquivalent = false;
          break;
        }
      }
    }
    require(!listsAreEquivalent, "No state change");
    mintlistDurations = mintlistDurations_;
    mintlistMerkleRoots = mintlistMerkleRoots_;
  }

  function setMerkleRootIndex(uint8 newIndex_) external onlyOwner {
    require(currentMerkleRootIndex!=newIndex_, "Same index");
    require(mintlistMerkleRoots[newIndex_] != bytes32(0), "No mintlist stored at that index");
    // Consider this the start of a new sale
    saleStartBlock = block.number;
    currentMerkleRootIndex = newIndex_;
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
  function setParentDomainId(uint256 parentId) external onlyOwner {
    require(parentDomainId != parentId, "Same parent id");
    parentDomainId = parentId;
  }

  // Update the number of blocks that each mintlist will last
  function setMintlistDuration(uint256 index, uint256 durationInBlocks) external onlyOwner {
    require(mintlistDurations.length > index, "Index out of bounds");
    require(mintlistDurations[index] != durationInBlocks, "No state change");
    mintlistDurations[index] = durationInBlocks;
  }

  // Set the number with which to start the metadata index (e.g. number is 100, so indicies are 100, 101, ...)
  function setStartIndex(uint256 index) external onlyOwner {
    require(index != startingMetadataIndex, "Cannot set to the same index");
    startingMetadataIndex = index;
  }

  // Set the hash of the base IPFS folder that contains the domain metadata
  function setBaseFolderHash(string calldata folderHash)
    external
    onlyOwner
  {
    require(
      keccak256(bytes(folderHash)) !=
        keccak256(bytes(baseFolderHash)),
      "Cannot set to same folder uri"
    );
    baseFolderHash = folderHash;
  }

  // Add new metadata URIs to be sold
  function setAmountOfDomainsForSale(uint256 forSale) public onlyOwner {
    totalForSale = forSale;
  }

  // Remove a domain from this sale
  function releaseDomain() external onlyOwner {
    zNSRegistrar.transferFrom(address(this), owner(), parentDomainId);
  }

  // Purchase `count` domains
  // Not the `purchaseLimit` you provide must be
  // less than or equal to what is in the mintlist
  function purchaseDomains(
    uint8 count,
    uint256 index,
    uint256 purchaseLimit,
    bytes32[] calldata merkleProof
  ) public payable {
    _canAccountPurchase(msg.sender, count, purchaseLimit);
    _requireVariableMerkleProof(index, purchaseLimit, merkleProof);
    _purchaseDomains(count);
  }

  function getNftByIndex(uint256 index) public view returns (string memory) {
    return
      string(
        abi.encodePacked(
          baseFolderHash, 
          Strings.toString(startingMetadataIndex + index)
        )
      );
  }

  function _canAccountPurchase(
    address account,
    uint8 count,
    uint256 purchaseLimit
  ) internal view {
    require(count > 0, "Zero purchase count");
    require(domainsSold < totalForSale, "No domains left for sale");
    require(
      domainsPurchasedByAccount[account] + count <= purchaseLimit,
      "Purchasing beyond limit."
    );
    require(msg.value >= salePrice * count, "Not enough funds in purchase");
    require(!paused, "paused");
    require(saleStarted, "Sale hasn't started or has ended");
    require(
      block.number <= saleStartBlock + mintlistDurations[currentMerkleRootIndex],
      "Sale has ended"
    );
  }

  function _purchaseDomains(uint8 count) internal {
    uint256 numPurchased = _reserveDomainsForPurchase(count);
    uint256 proceeds = salePrice * numPurchased;
    _sendPayment(proceeds);
    _mintDomains(numPurchased);
  }

  function _reserveDomainsForPurchase(uint8 count) internal returns (uint256) {
    uint256 numPurchased = count;
    // If we would are trying to purchase more than is available, purchase the remainder
    if (domainsSold + count > totalForSale) {
      numPurchased = totalForSale - domainsSold;
    }
    domainsSold += numPurchased;

    // Update number of domains this account has purchased
    // This is done before minting domains or sending any eth to prevent
    // a re-entrance attack through a recieve() or a safe transfer callback
    domainsPurchasedByAccount[msg.sender] =
      domainsPurchasedByAccount[msg.sender] +
      numPurchased;

    return numPurchased;
  }

  // Transfer funds to the buying user, refunding if necessary
  function _sendPayment(uint256 proceeds) internal {
    payable(sellerWallet).transfer(proceeds);

    // Send refund if neceesary for any unpurchased domains
    if (msg.value - proceeds > 0) {
      payable(msg.sender).transfer(msg.value - proceeds);
      emit RefundedEther(msg.sender, msg.value - proceeds);
    }
  }

  function _mintDomains(uint256 numPurchased) internal {
    // Mint the domains after they have been purchased
    for (uint256 i = 0; i < numPurchased; ++i) {
      // The sale contract will be the minter and own them at this point
      zNSRegistrar.registerDomainAndSend(
        parentDomainId,
        Strings.toString(startingMetadataIndex + domainsSold - numPurchased + i), 
        sellerWallet,
        getNftByIndex(startingMetadataIndex + domainsSold - numPurchased + i),
        0,
        true,
        msg.sender
      );
    }
  }

  function _requireVariableMerkleProof(
    uint256 index,
    uint256 quantity,
    bytes32[] calldata merkleProof
  ) internal view {
    bytes32 node = keccak256(abi.encodePacked(index, msg.sender, quantity));
    bytes32 currentMerkleRoot = mintlistMerkleRoots[currentMerkleRootIndex];
    require(
      MerkleProofUpgradeable.verify(merkleProof, currentMerkleRoot, node),
      "Invalid Merkle Proof"
    );
  }
}
