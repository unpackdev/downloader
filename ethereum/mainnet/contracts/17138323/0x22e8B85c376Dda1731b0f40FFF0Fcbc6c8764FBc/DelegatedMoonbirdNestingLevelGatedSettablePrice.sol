// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.16;

import "./ERC721.sol";
import "./Testing.sol";
import "./DelegationRegistry.sol";

import "./CallbackerWithAccessControl.sol";
import "./ExactSettableFixedPrice.sol";
import "./InternallyPriced.sol";

import "./NestingLevelLib.sol";
import "./MoonbirdNestingLevelGated.sol";
import "./TokenApprovalChecker.sol";

/**
 * @notice Public seller with a fixed price.
 */
contract DelegatedMoonbirdNestingLevelGatedSettablePrice is
    MoonbirdNestingLevelGated,
    DelegatedTokenApprovalChecker,
    ExactSettableFixedPrice
{
    constructor(
        address admin,
        address steerer,
        ISellable sellable_,
        uint256 price,
        IERC721 gatingToken,
        NestingLevelLib.NestingLevel requiredLevel,
        IDelegationRegistry registry
    )
        CallbackerWithAccessControl(admin, steerer, sellable_)
        MoonbirdNestingLevelGated(gatingToken, requiredLevel)
        DelegatedTokenApprovalChecker(registry)
        ExactSettableFixedPrice(price)
    {}

    function _checkAndModifyPurchase(address to, uint64 num, uint256 cost_, bytes memory data)
        internal
        view
        virtual
        override(InternallyPriced, ExactInternallyPriced)
        returns (address, uint64, uint256)
    {
        return ExactInternallyPriced._checkAndModifyPurchase(to, num, cost_, data);
    }

    /**
     * @notice Changes set of signers authorised to sign allowances.
     */
    function changeAllowlistSigners(address[] calldata rm, address[] calldata add)
        public
        onlyRole(DEFAULT_STEERING_ROLE)
    {
        _changeAllowlistSigners(rm, add);
    }
}
