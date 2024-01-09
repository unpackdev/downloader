// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Royalties.sol";

contract Collection is Royalties {
    bool public isValid;

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

    /**
     * @dev setup presale and base collection details including whitelist
     * @param _baseCollection struct with params to setup base collection
     * @param _presaleable struct with params to setup presale
     * @param _paymentSplitter struct with params to setup payment splitting
     * @param _revealable struct with params to setup reveal details
     */
    function setup(
        BaseCollectionStruct memory _baseCollection,
        PresaleableStruct memory _presaleable,
        PaymentSplitterStruct memory _paymentSplitter,
        RevealableStruct memory _revealable
    ) external {
        require(!isValid, "C:001");
        isValid = true;
        setupBaseCollection(
            _baseCollection.name,
            _baseCollection.symbol,
            _baseCollection.admin,
            _baseCollection.maximumTokens,
            _baseCollection.maxPurchase,
            _baseCollection.maxHolding,
            _baseCollection.price,
            _baseCollection.publicSaleStartTime,
            _baseCollection.loadingURI
        );
        setupPresale(
            _presaleable.presaleReservedTokens,
            _presaleable.presalePrice,
            _presaleable.presaleStartTime,
            _presaleable.presaleMaxHolding,
            _presaleable.presaleWhitelist
        );
        setupPaymentSplitter(
            _paymentSplitter.nftify,
            _paymentSplitter.nftifyShares,
            _paymentSplitter.payees,
            _paymentSplitter.shares
        );
        setRevealableDetails(
            _revealable.projectURIProvenance,
            _revealable.revealAfterTimestamp
        );
    }
}
