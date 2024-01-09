// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./ERC721HolderUpgradeable.sol";
import "./IERC721Upgradeable.sol";

import "./IBasicController.sol";

contract SimpleSale is
  Initializable,
  OwnableUpgradeable,
  ERC721HolderUpgradeable
{
  event DomainPurchased(address buyer, uint256 domainId);
  event RefundedEther(address buyer, uint256 amount);

  struct Domain {
    string metadataUri;
  }

  IBasicController public controller;
  uint256 public parentDomainId;
  uint256 public salePrice;
  uint256 public maxPurchasesPerAccount;
  IERC721Upgradeable public zNSRegistrar;
  address public sellerWallet;

  Domain[] public domainsForSale;
  uint256 public totalForSale;
  uint256 public domainsSold;
  uint256 public startIndex;
  mapping(address => uint256) public domainsPurchasedByAccount;

  function __SimpleSale_init(
    IBasicController controller_,
    uint256 parentDomainId_,
    uint256 price,
    uint256 maxPurchasesPerAccount_,
    IERC721Upgradeable zNSRegistrar_,
    address sellerWallet_,
    uint256 startIndex_
  ) public initializer {
    __Ownable_init();
    __ERC721Holder_init();

    controller = controller_;
    parentDomainId = parentDomainId_;
    maxPurchasesPerAccount = maxPurchasesPerAccount_;
    salePrice = price;
    zNSRegistrar = zNSRegistrar_;
    sellerWallet = sellerWallet_;
    startIndex = startIndex_;
  }

  function addDomainsToSell(string[] calldata metadataUris) external onlyOwner {
    // Take each pair and create a domain to sell from it
    for (uint256 i = 0; i < metadataUris.length; ++i) {
      domainsForSale.push(Domain({metadataUri: metadataUris[i]}));
    }

    totalForSale += metadataUris.length;
  }

  function addDomainsToSellOptimized(
    bytes12[] calldata chunk1,
    bytes32[] calldata chunk2
  ) external onlyOwner {
    require(chunk2.length == chunk1.length, "invalid arrays");
    string memory uri;
    for (uint256 i = 0; i < chunk1.length; ++i) {
      uri = string(abi.encodePacked("ipfs://Qm", chunk1[i], chunk2[i]));

      domainsForSale.push(Domain({metadataUri: uri}));
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

  function setStartIndex(uint256 index) external onlyOwner {
    require(startIndex != index, "same index");
    startIndex = index;
  }

  function purchaseDomains(uint8 count) public payable virtual {
    require(count > 0, "Zero purchase count");
    require(domainsSold < domainsForSale.length, "No domains left");
    // Make sure enough eth was sent to purchase domains
    require(msg.value == salePrice * count, "Invalid amount of eth");

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
    uint256 initialIndex = startIndex + domainsSold;

    // Iterate through until we find a domain that can be purchased:
    while (numPurchased < count && domainsSold < domainsForSale.length) {
      purchasedIndices[numPurchased] = domainsSold;
      numPurchased++;
      domainsSold++;
    }

    // Update number of domains this account has purchased
    // This is done before minting domains or sending any eth to prevent
    // a re-entrance attack through a recieve() or a safe transfer callback
    domainsPurchasedByAccount[msg.sender] =
      domainsPurchasedByAccount[msg.sender] +
      numPurchased;

    // transfer paid ETH to the "seller" wallet
    uint256 proceeds = salePrice * numPurchased;
    payable(sellerWallet).transfer(proceeds);

    // refund any extra ETH
    if (numPurchased < count) {
      uint256 refundAmount = msg.value - proceeds;
      payable(msg.sender).transfer(refundAmount);
      emit RefundedEther(msg.sender, refundAmount);
    }

    // Mint the domains
    for (uint8 i = 0; i < numPurchased; ++i) {
      // The sale contract will be the minter and own them at this point
      uint256 domainId =
        controller.registerSubdomainExtended(
          parentDomainId,
          uint2str(initialIndex + i),
          address(this),
          domainsForSale[purchasedIndices[i]].metadataUri,
          0,
          true
        );

      emit DomainPurchased(msg.sender, domainId);

      // Transfer the domains to the buyer
      zNSRegistrar.safeTransferFrom(address(this), msg.sender, domainId);
    }
  }

  function setSalePrice(uint256 price) public onlyOwner {
    require(salePrice != price, "No price change");
    salePrice = price;
  }

  function uint2str(uint256 _i)
    internal
    pure
    returns (string memory _uintAsString)
  {
    if (_i == 0) {
      return "0";
    }
    uint256 j = _i;
    uint256 len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint256 k = len;
    while (_i != 0) {
      k = k - 1;
      uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
      bytes1 b1 = bytes1(temp);
      bstr[k] = b1;
      _i /= 10;
    }
    return string(bstr);
  }
}
