// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./ERC721HolderUpgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IERC20Upgradeable.sol";

import "./IBasicController.sol";

contract SimpleSale is
  Initializable,
  OwnableUpgradeable,
  ERC721HolderUpgradeable
{
  event DomainPurchased(address buyer, uint256 domainId);

  struct Domain {
    string domainLabel;
    string metadataUri;
  }

  // The zNS Registrar Controller to use to mint domains
  IBasicController public controller;

  // The parent domain to mint sold domains under
  uint256 public parentDomainId;

  // Price of each domain to be sold
  uint256 public salePrice;

  // Max # of domains a single account can purchase.
  uint256 public maxPurchasesPerAccount;

  // zNS Registrar
  IERC721Upgradeable public zNSRegistrar;

  // The wallet to transfer proceeds to
  address public sellerWallet;

  // The domains that are being sold
  Domain[] public domainsForSale;

  // Total number of domains to be sold
  uint256 public totalForSale;

  // Number of domains sold so far
  uint256 public domainsSold;

  // Mapping to keep track of how many domains an account has purchased so far
  mapping(address => uint256) public domainsPurchasedByAccount;

  // The ERC20 token that sales are done with
  IERC20Upgradeable public saleToken;

  function __SimpleSale_init(
    IBasicController controller_,
    uint256 parentDomainId_,
    uint256 price,
    uint256 maxPurchasesPerAccount_,
    IERC721Upgradeable zNSRegistrar_,
    address sellerWallet_,
    address saleToken_
  ) public initializer {
    __Ownable_init();
    __ERC721Holder_init();

    controller = controller_;
    parentDomainId = parentDomainId_;
    maxPurchasesPerAccount = maxPurchasesPerAccount_;
    salePrice = price;
    zNSRegistrar = zNSRegistrar_;
    sellerWallet = sellerWallet_;
    saleToken = IERC20Upgradeable(saleToken_);
  }

  function addDomainsToSell(
    string[] calldata domainLabels,
    string[] calldata metadataUris
  ) external onlyOwner {
    // Take each pair and create a domain to sell from it
    for (uint256 i = 0; i < metadataUris.length; ++i) {
      domainsForSale.push(
        Domain({domainLabel: domainLabels[i], metadataUri: metadataUris[i]})
      );
    }

    totalForSale += metadataUris.length;
  }

  function addDomainsToSellOptimized(
    string[] calldata domainLabels,
    bytes12[] calldata chunk1,
    bytes32[] calldata chunk2
  ) external onlyOwner {
    require(chunk2.length == chunk1.length, "invalid arrays");
    string memory uri;
    for (uint256 i = 0; i < chunk1.length; ++i) {
      uri = string(abi.encodePacked("ipfs://Qm", chunk1[i], chunk2[i]));

      domainsForSale.push(
        Domain({domainLabel: domainLabels[i], metadataUri: uri})
      );
    }

    totalForSale += chunk1.length;
  }

  function setSellerWallet(address wallet) external onlyOwner {
    require(wallet != sellerWallet, "Same Wallet");
    sellerWallet = wallet;
  }

  function setParendDomainId(uint256 parentId) external onlyOwner {
    require(parentDomainId != parentId, "Same parent id");
    parentDomainId = parentId;
  }

  function setController(IBasicController controller_) external onlyOwner {
    require(controller != controller_, "Same controller");
    controller = controller_;
  }

  function purchaseDomains(uint8 count) public payable virtual {
    require(count > 0, "Zero purchase count");
    require(domainsSold < domainsForSale.length, "No domains left");

    _canAccountPurchase(msg.sender, count);
    _purchaseDomains(count);
  }

  function _canAccountPurchase(address account, uint8 count)
    internal
    view
    virtual
  {
    // Chech new purchase limit
    require(
      domainsPurchasedByAccount[account] + count <= maxPurchasesPerAccount,
      "Purchasing beyond limit."
    );
  }

  function _purchaseDomains(uint8 count) private {
    uint8 numPurchased = 0;
    uint256[] memory purchasedIndices = new uint256[](count);

    // Iterate through until we find a domain that can be purchased:
    while (numPurchased < count && domainsSold < domainsForSale.length) {
      purchasedIndices[numPurchased] = domainsSold;
      numPurchased++;
      domainsSold++;
    }

    // transfer tokens to the "seller" wallet
    uint256 proceeds = salePrice * numPurchased;
    saleToken.transferFrom(msg.sender, sellerWallet, proceeds);

    // Update number of domains this account has purchased
    // This is done before minting domains or sending any eth to prevent
    // a re-entrance attack through a recieve() or a safe transfer callback
    domainsPurchasedByAccount[msg.sender] =
      domainsPurchasedByAccount[msg.sender] +
      numPurchased;

    // Mint the domains
    for (uint8 i = 0; i < numPurchased; ++i) {
      // The sale contract will be the minter and own them at this point
      uint256 domainId =
        controller.registerSubdomainExtended(
          parentDomainId,
          domainsForSale[purchasedIndices[i]].domainLabel,
          address(this),
          domainsForSale[purchasedIndices[i]].metadataUri,
          0,
          true
        );

      emit DomainPurchased(msg.sender, domainId);

      // Transfer the domains to the buyer
      zNSRegistrar.transferFrom(address(this), msg.sender, domainId);
    }
  }
}
