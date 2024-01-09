// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ICollection {
    struct BaseCollectionStruct {
        string name;
        string symbol;
        address admin;
        uint256 maximumTokens;
        uint16 maxPurchase;
        uint16 maxHolding;
        uint256 price;
        uint256 publicSaleStartTime;
        string loadingURI;
    }

    struct PresaleableStruct {
        uint256 presaleReservedTokens;
        uint256 presalePrice;
        uint256 presaleStartTime;
        uint256 presaleMaxHolding;
        address[] presaleWhitelist;
    }

    struct PaymentSplitterStruct {
        address nftify;
        uint256 nftifyShares;
        address[] payees;
        uint256[] shares;
    }

    struct RevealableStruct {
        bytes32 projectURIProvenance;
        uint256 revealAfterTimestamp;
    }

    function setup(
        BaseCollectionStruct memory _baseCollection,
        PresaleableStruct memory _presaleable,
        PaymentSplitterStruct memory _paymentSplitter,
        RevealableStruct memory _revealable
    ) external;

    function setMetadata(string memory _metadata) external;
}
