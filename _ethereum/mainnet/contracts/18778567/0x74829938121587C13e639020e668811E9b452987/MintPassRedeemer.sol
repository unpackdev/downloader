// SPDX-License-Identifier: MIT
// Copyright 2023 Proof Holdings Inc.
pragma solidity >=0.8.0 <0.9.0;

import "./RedeemableTokenRedeemer.sol";

import "./Seller.sol";
import "./InternallyPriced.sol";
import "./SellableCallbacker.sol";
import "./InternallyPriced.sol";
import "./ByProjectId.sol";

import "./SellableERC721ACommonByProjectID.sol";

/**
 * @notice Seller that redeems a mint pass.
 */
abstract contract MintPassRedeemerBase is RedeemableTokenRedeemer {
    /**
     * @notice The regular Grails Exhibition pass.
     */
    IRedeemableToken public immutable pass;

    constructor(IRedeemableToken pass_) {
        pass = pass_;
    }

    /**
     * @notice Redeems the given passes and redemptions pieces in the Grails Exhibition.
     */
    function _redeem(uint256[] memory passIds) internal {
        uint256 num = passIds.length;
        for (uint256 i = 0; i < num; ++i) {
            _redeem(pass, passIds[i]);
        }
    }
}

/**
 * @notice Seller that redeems a mint pass.
 */
abstract contract MintPassRedeemer is MintPassRedeemerBase, Seller, ImmutableSellableCallbacker {
    constructor(ISellableByProjectID sellable_, IRedeemableToken pass_)
        MintPassRedeemerBase(pass_)
        ImmutableSellableCallbacker(sellable_)
    {}

    function _purchase(address to, uint256 externalCost, uint256[] memory passIds, bytes memory purchasePayload)
        internal
        virtual
    {
        _redeem(passIds);
        _purchase(to, uint64(passIds.length), externalCost, purchasePayload);
    }
}

/**
 * @notice Seller that redeems a mint pass for a certain project on the sellable.
 */
abstract contract MintPassForProjectIDRedeemer is MintPassRedeemerBase, ByProjectId, ImmutableSellableCallbacker {
    constructor(ISellableByProjectID sellable_, IRedeemableToken pass_)
        MintPassRedeemerBase(pass_)
        ImmutableSellableCallbacker(sellable_)
    {}

    /**
     * @notice The struct encoding a redemption.
     * @param passId The ID of the pass to redeem.
     * @param projectId The ID of the project to redeem the pass for.
     */
    struct Redemption {
        uint256 passId;
        uint128 projectId;
    }

    /**
     * @notice Redeems the given passes for the specified projects on the sellable.
     */
    function _purchase(address to, uint256 externalCost, Redemption[] calldata redemptions) internal {
        uint256[] memory passIds = new uint256[](redemptions.length);
        uint128[] memory projectIds = new uint128[](redemptions.length);

        for (uint256 i = 0; i < redemptions.length; ++i) {
            passIds[i] = redemptions[i].passId;
            projectIds[i] = redemptions[i].projectId;
        }

        _redeem(passIds);
        _purchase(to, externalCost, projectIds);
    }
}

/**
 * @notice Seller that redeems a mint pass for a certain project on the Sellable, otherwise free of charge.
 */
contract FreeMintPassForProjectIDRedeemer is MintPassForProjectIDRedeemer {
    constructor(ISellableByProjectID sellable_, IRedeemableToken pass_)
        MintPassForProjectIDRedeemer(sellable_, pass_)
    {}

    function purchase(Redemption[] calldata redemptions) external {
        MintPassForProjectIDRedeemer._purchase(msg.sender, 0, redemptions);
    }
}

/**
 * @notice Seller that redeems a mint pass and an additional fee for a certain project on the sellable.
 */
contract FixedPricedMintPassForProjectIDRedeemerBase is ExactFixedPrice, MintPassForProjectIDRedeemer {
    constructor(ISellableByProjectID sellable_, IRedeemableToken pass_, uint256 price)
        MintPassForProjectIDRedeemer(sellable_, pass_)
        ExactFixedPrice(price)
    {}

    /**
     * @dev Inheritance resoultion ensuring that the seller requires the correct `cost`.
     */
    function _checkAndModifyPurchase(address to, uint64 num, uint256 cost_, bytes memory data)
        internal
        view
        virtual
        override(Seller, ExactInternallyPriced)
        returns (address, uint64, uint256)
    {
        return ExactInternallyPriced._checkAndModifyPurchase(to, num, cost_, data);
    }

    /**
     * @notice Redeems the given passes and an additional fee for the specified projects on the sellable.
     * @dev Reverts if the value sent is not equal to the `cost` (i.e. `price * redemptions.length`).
     */
    function _purchase(Redemption[] calldata redemptions) internal {
        MintPassForProjectIDRedeemer._purchase(msg.sender, type(uint256).max, redemptions);
    }
}

/**
 * @notice Seller that redeems a mint pass and an additional fee for a certain project on the sellable.
 */
contract FixedPricedMintPassForProjectIDRedeemer is FixedPricedMintPassForProjectIDRedeemerBase {
    constructor(ISellableByProjectID sellable_, IRedeemableToken pass_, uint256 price)
        FixedPricedMintPassForProjectIDRedeemerBase(sellable_, pass_, price)
    {}

    /**
     * @notice Redeems the given passes and an additional fee for the specified projects on the sellable.
     * @dev Reverts if the value sent is not equal to the `cost` (i.e. `price * redemptions.length`).
     */
    function purchase(Redemption[] calldata redemptions) external payable {
        _purchase(redemptions);
    }
}
