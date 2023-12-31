// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./Errors.sol";
import "./IBuyNowSellingAgreementProvider.sol";

library BuyNowSellingAgreementChecks {
  function mustNotExist(
    BuyNowSellingAgreement memory sellingAgreement
  ) internal pure {
    if (sellingAgreement.price > 0) {
      revert NFTMarketBuyNow__SellingAgreement__AlreadyExists();
    }
  }

  function mustExist(
    BuyNowSellingAgreement memory sellingAgreement
  ) internal pure {
    if (sellingAgreement.price == 0) {
      revert NFTMarketBuyNow__SellingAgreement__DoesNotExist();
    }
  }

  function mustHaveStarted(
    BuyNowSellingAgreement memory sellingAgreement
  ) internal view {
    if (sellingAgreement.startTime > block.timestamp) {
      revert NFTMarketBuyNow__SellingAgreement__NotStarted();
    }
  }

  function mustBeOwnedBy(
    BuyNowSellingAgreement memory sellingAgreement,
    address seller
  ) internal pure {
    if (sellingAgreement.seller != seller) {
      revert NFTMarketBuyNow__SellingAgreement__SellerMismatch();
    }
  }
}
