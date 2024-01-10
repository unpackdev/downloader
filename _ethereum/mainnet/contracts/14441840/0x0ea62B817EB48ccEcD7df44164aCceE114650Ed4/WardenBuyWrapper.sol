// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Warden.sol";
import "./IVotingEscrow.sol";
import "./IVotingEscrowDelegation.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

/** @title Wrapper around the Warden buyDelegationBoost method  */
/** This is necessary since the case where delegator has expired boost but are not cleared before */
/** trying to purchase a Boost will fail the purchase */
/// @author Paladin
contract WardenBuyWrapper is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public constant UNIT = 1e18;
    uint256 public constant MAX_PCT = 10000;
    uint256 public constant MAX_UINT = 2**256 - 1;
    uint256 public constant WEEK = 7 * 86400;

    /** @notice ERC20 used to pay for DelegationBoost */
    IERC20 public feeToken;
    /** @notice Address of the votingToken to delegate */
    IVotingEscrow public votingEscrow;
    /** @notice Address of the Delegation Boost contract */
    IVotingEscrowDelegation public delegationBoost;
    /** @notice Address of the Delegation Boost contract */
    Warden public warden;

    constructor(
        address _feeToken,
        address _votingEscrow,
        address _delegationBoost,
        address _warden
    ) {
        feeToken = IERC20(_feeToken);
        votingEscrow = IVotingEscrow(_votingEscrow);
        delegationBoost = IVotingEscrowDelegation(_delegationBoost);
        warden = Warden(_warden);
    }


    function buyDelegationBoost(
        address delegator,
        address receiver,
        uint256 percent,
        uint256 duration, //in weeks
        uint256 maxFeeAmount
    ) external nonReentrant whenNotPaused returns(uint256){
        require(
            delegator != address(0) && receiver != address(0),
            "Warden: Zero address"
        );
        require(warden.userIndex(delegator) != 0, "Warden: Not registered");
        require(maxFeeAmount > 0, "Warden: No fees");
        require(
            percent >= warden.minPercRequired(),
            "Warden: Percent under min required"
        );
        require(percent <= MAX_PCT, "Warden: Percent over 100");

        uint256 previousBalance = feeToken.balanceOf(address(this));

        // Pull the given token amount ot this contract (must be approved beforehand)
        feeToken.safeTransferFrom(msg.sender, address(this), maxFeeAmount);
        //Set the approval to 0, then set it to totalFeesAmount (CRV : race condition)
        if(feeToken.allowance(address(this), address(warden)) != 0) feeToken.safeApprove(address(warden), 0);
        feeToken.safeApprove(address(warden), maxFeeAmount);

        // check clear expired boosts
        uint256 nbTokens = delegationBoost.total_minted(delegator);
        uint256[256] memory expiredBoosts; //Need this type of array because of batch_cancel_boosts() from veBoost
        uint256 nbExpired = 0;

        // Loop over the delegator current boosts to find expired ones
        for (uint256 i = 0; i < nbTokens;) {
            uint256 tokenId = delegationBoost.token_of_delegator_by_index(
                delegator,
                i
            );

            // If boost expired
            if (delegationBoost.token_expiry(tokenId) < block.timestamp) {
                expiredBoosts[nbExpired] = tokenId;
                nbExpired++;
            }

            unchecked{ ++i; }
        }

        if (nbExpired > 0) {
            delegationBoost.batch_cancel_boosts(expiredBoosts);
        }

        uint newTokenId = warden.buyDelegationBoost(delegator, receiver, percent, duration, maxFeeAmount);

        require(newTokenId != 0, "Boost buy fail");

        //Return all unused feeTokens to the Buyer
        uint256 endBalance = feeToken.balanceOf(address(this));
        feeToken.safeTransfer(msg.sender, (endBalance - previousBalance));

        return newTokenId;
        
    }

}