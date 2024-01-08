// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./SimpleSale.sol";

import "./MerkleProofUpgradeable.sol";

import "./UUPSUpgradeable.sol";

contract WhitelistSimpleSale is UUPSUpgradeable, SimpleSale {
  bytes32 public whitelistMerkleRoot;
  bool public saleStarted;
  uint256 public saleStartBlock;
  uint256 public whitelistSaleDuration; // in blocks
  uint256 public postWhitelistMaxPurchases;
  bool public paused;

  event SaleStarted();

  function __WhitelistSimpleSale_init(
    IBasicController controller_,
    uint256 parentDomainId_,
    uint256 price,
    uint256 maxPurchasesPerAccount_,
    uint256 postWhitelistMaxPurchases_,
    IERC721Upgradeable zNSRegistrar_,
    address sellerWallet_,
    uint256 whitelistSaleDuration_,
    bytes32 merkleRoot,
    uint256 startIndex_,
    address saleToken_
  ) public initializer {
    __Ownable_init();
    __ERC721Holder_init();
    __UUPSUpgradeable_init();
    __SimpleSale_init(
      controller_,
      parentDomainId_,
      price,
      maxPurchasesPerAccount_,
      zNSRegistrar_,
      sellerWallet_,
      startIndex_,
      saleToken_
    );

    whitelistSaleDuration = whitelistSaleDuration_;
    whitelistMerkleRoot = merkleRoot;
    postWhitelistMaxPurchases = postWhitelistMaxPurchases_;
    paused = false;
  }

  function updateMerkleRoot(bytes32 root) external onlyOwner {
    require(whitelistMerkleRoot != root, "same root");
    whitelistMerkleRoot = root;
  }

  function startSale() public onlyOwner {
    require(!saleStarted, "Sale already started");
    saleStarted = true;
    saleStartBlock = block.number;
    emit SaleStarted();
  }

  function setSaleDuration(uint256 durationInBlocks) public onlyOwner {
    require(whitelistSaleDuration != durationInBlocks, "No state change");
    whitelistSaleDuration = durationInBlocks;
  }

  function setPauseStatus(bool pauseStatus) public onlyOwner {
    require(paused != pauseStatus, "No state change");
    paused = pauseStatus;
  }

  function stopSale() public onlyOwner {
    require(saleStarted, "Sale not started");
    saleStarted = false;
  }

  function purchaseDomains(uint8 count) public payable override {
    require(!paused, "paused");
    require(saleStarted, "Sale has not started yet");
    require(
      block.number > saleStartBlock + whitelistSaleDuration,
      "Whitelist sales only"
    );

    SimpleSale.purchaseDomains(count);
  }

  function purchaseDomainsWhitelisted(
    uint8 count,
    uint256 index,
    bytes32[] calldata merkleProof
  ) public payable {
    require(!paused, "paused");
    require(saleStarted, "Sale has not started yet");

    bytes32 node = keccak256(abi.encodePacked(index, msg.sender));
    require(
      MerkleProofUpgradeable.verify(merkleProof, whitelistMerkleRoot, node),
      "Invalid Merkle Proof"
    );

    SimpleSale.purchaseDomains(count);
  }

  function releaseDomain() public onlyOwner {
    zNSRegistrar.transferFrom(address(this), owner(), parentDomainId);
  }

  function currentMaxPurchaseCount() public view returns (uint256) {
    uint256 maxPurchaseCount = maxPurchasesPerAccount;
    if (block.number > saleStartBlock + whitelistSaleDuration) {
      maxPurchaseCount = postWhitelistMaxPurchases;
    }
    return maxPurchaseCount;
  }

  function _canAccountPurchase(address account, uint8 count)
    internal
    view
    override
  {
    uint256 maxPurchaseCount = currentMaxPurchaseCount();

    // Chech new purchase limit
    require(
      domainsPurchasedByAccount[account] + count <= maxPurchaseCount,
      "Purchasing beyond limit."
    );
  }

  function _authorizeUpgrade(address newImplementation)
    internal
    override
    onlyOwner
  {}
}
