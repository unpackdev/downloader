// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.15;

import "./IDelegateRegistry.sol";
import "./IERC721.sol";

import "./IRedeemableToken.sol";
import "./SignatureGated.sol";
import "./ExactPaymentCheck.sol";
import "./MintPassRedeemer.sol";

import "./Grails5.sol";
import "./Grails5MintPass.sol";

contract DelegatedSignatureGatedMintPassRedeemer is
    MintPassForProjectIDRedeemer,
    AccessControlledSignatureGatedBase,
    ExactPaymentCheck
{
    /**
     * @notice Thrown if the tx sender is not allowed to spend the allowance.
     */
    error NotAllowedToSpendAllowance(address spender, SignatureGatedLib.Allowance allowance);

    /**
     * @notice The delegate.cash delegation registry.
     */
    IDelegateRegistry internal immutable _delegateRegistry;

    /**
     * @notice The contract address for which delegation is being checked.
     */
    address internal immutable _delegationForContract;

    constructor(
        address admin,
        address steerer,
        ISellableByProjectID sellable_,
        IRedeemableToken pass_,
        IDelegateRegistry registry,
        address delegationForContract
    ) AccessControlled(admin, steerer) MintPassForProjectIDRedeemer(sellable_, pass_) {
        _delegationForContract = delegationForContract;
        _delegateRegistry = registry;
    }

    function _checkAndModifyPurchase(address to, uint64 num, uint256 cost_, bytes memory data)
        internal
        view
        virtual
        override(Seller, ExactPaymentCheck)
        returns (address, uint64, uint256)
    {
        return ExactPaymentCheck._checkAndModifyPurchase(to, num, cost_, data);
    }

    /**
     * @notice Redeems the given passes and an additional fee for the specified projects on the sellable.
     * @dev Reverts if the value sent is not equal to the `cost` (i.e. `price * redemptions.length`, the price on the
     * signed allowance is ignored).
     */
    function purchase(SignatureGatedLib.SignedAllowance calldata signedAllowance, Redemption[] calldata redemptions)
        external
        payable
    {
        bytes32 dig = digest(signedAllowance.allowance);
        uint256 num = redemptions.length;
        _checkSignedAllowance(dig, signedAllowance, num);
        _trackAllowanceUsage(dig, num);

        if (!_isAllowedToSpendAllowance(msg.sender, signedAllowance.allowance)) {
            revert NotAllowedToSpendAllowance(msg.sender, signedAllowance.allowance);
        }

        _purchase({to: msg.sender, externalCost: signedAllowance.allowance.price * num, redemptions: redemptions});
    }

    function _isAllowedToSpendAllowance(address spender, SignatureGatedLib.Allowance calldata allowance)
        internal
        view
        virtual
        returns (bool)
    {
        return spender == allowance.receiver
            || _delegateRegistry.checkDelegateForContract(
                spender, allowance.receiver, _delegationForContract, allowanceSpendRights()
            );
    }

    /**
     * @notice The delegate.cash subdelegation right to spend signed allowances on behalf of the actual receiver.
     */
    function allowanceSpendRights() public view virtual returns (bytes32) {
        return "spendAllowance";
    }
}

/**
 * @title Grails V: Signature gated Mint Pass Redeemer
 * @notice The mint pass redeemer for phase 1
 */
contract Grails5SignatureGatedMintPassRedeemer is DelegatedSignatureGatedMintPassRedeemer {
    constructor(
        address admin,
        address steerer,
        Grails5 grails,
        Grails5MintPass pass_,
        IDelegateRegistry registry,
        IERC721 proofCollective
    ) DelegatedSignatureGatedMintPassRedeemer(admin, steerer, grails, pass_, registry, address(proofCollective)) {}

    function allowanceSpendRights() public view virtual override returns (bytes32) {
        return "grails-claim";
    }
}
