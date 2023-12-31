// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./BaseUpgradeable.sol";
import "./ClaimGoodUpgradeable.sol";
import "./GoodsPaymentUpgradeable.sol";

import "./ISignatureVerifierUpgradeable.sol";
import "./IGoodsExchangeUpgradeable.sol";
import "./IERC721Upgradeable.sol";

import "./ErrorHandler.sol";
import "./Types.sol";
import "./Constants.sol";

contract GoodsExchangeUpgradeable is
    IGoodsExchangeUpgradeable,
    BaseUpgradeable,
    ClaimGoodUpgradeable,
    GoodsPaymentUpgradeable
{
    using ErrorHandler for bool;
    using Types for Types.Claim;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address roleManager_,
        address recipient_,
        address token_,
        uint256 paymentPrice_
    ) external initializer {
        __BaseUpgradeable_init_unchained(roleManager_);
        __PrimarySale_init_unchained(recipient_);
        __GoodsPayment_init_unchained(token_, paymentPrice_);
    }

    function claimGoods(Types.Claim calldata claim_, Types.Signature[] calldata signatures_) external override {
        _processClaim(claim_, signatures_);
    }

    function onERC721Received(address, address from_, uint256, bytes calldata data_) external returns (bytes4) {
        Types.Claim memory claim_;

        (uint256[] memory tokenIds, Types.Signature[] memory signatures_) = abi.decode(
            data_,
            (uint256[], Types.Signature[])
        );

        claim_.isBurning = true;
        claim_.recipient = from_;
        claim_.collection = _msgSender();
        claim_.tokenIds = tokenIds;

        _processClaim(claim_, signatures_);

        return this.onERC721Received.selector;
    }

    function _processClaim(Types.Claim memory claim_, Types.Signature[] memory signatures_) internal {
        bytes32 claimHash = claim_.hash();

        if (!ISignatureVerifierUpgradeable(roleManager).verifyExchange(claimHash, signatures_)) {
            revert IGoodsExchange__InvalidSignatures();
        }

        _claimGoods(claim_.isBurning, claim_.recipient, claim_.collection, claim_.tokenIds);
    }
}
