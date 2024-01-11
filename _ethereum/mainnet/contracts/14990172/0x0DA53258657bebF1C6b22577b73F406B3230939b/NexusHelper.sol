// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;
import "./IDistributor.sol";
import "./IExchangeAdapter.sol";

library NexusHelper {
    event ClaimPayoutRedeemed(
        uint256 indexed coverId,
        uint256 indexed claimId,
        address indexed receiver,
        uint256 amountPaid,
        address coverAsset
    );

    event ClaimSubmitted(
        uint256 indexed coverId,
        uint256 indexed claimId,
        address indexed submitter
    );

    struct Cover {
        bytes32 coverType;
        uint256 productId;
        bytes32 contractName;
        uint256 coverAmount;
        uint256 premium;
        address currency;
        address contractAddress;
        uint256 expiration;
        uint256 status;
        address refAddress;
    }

    struct CoverQuote {
        uint256 prop1;
        uint256 prop2;
        uint256 prop3;
        uint256 prop4;
        uint256 prop5;
        uint256 prop6;
        uint256 prop7;
    }

    event BuyCoverEvent(
        address _productAddress,
        uint256 _productId,
        uint256 _period,
        address _asset,
        uint256 _amount,
        uint256 _price
    );
}
