// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./SkinnyDAOracle.sol";
import "./SponsorPool.sol";

library DAOracleHelpers {
  using SafeERC20 for IERC20;

  function claimableRewards(SkinnyDAOracle.Index storage index)
    public
    view
    returns (
      uint256 total,
      uint256 poolAmount,
      uint256 reporterAmount,
      uint256 residualAmount,
      uint256 vestingTime
    )
  {
    // multiplier = distance between last proposal and current time (in seconds)
    uint256 multiplier = block.timestamp - index.lastUpdated;

    // minimum multiplier = 1
    if (multiplier == 0) multiplier = 1;

    // reporter's share starts at floor and moves toward ceiling by tilt % per tick
    uint256 reporterShare = index.floor + (index.tilt * multiplier);
    if (reporterShare > index.ceiling) reporterShare = index.ceiling;

    total = index.drop * multiplier;
    reporterAmount = (total * reporterShare) / 1e18;
    residualAmount = ((total - reporterAmount) * index.creatorAmount) / 1e18;
    poolAmount = total - residualAmount - reporterAmount;
    vestingTime = 0;
  }

  function dispute(
    SkinnyDAOracle.Index storage index,
    SkinnyDAOracle.Proposal storage proposal,
    SkinnyOptimisticOracleInterface oracle,
    bytes32 externalIdentifier
  ) public {
    IERC20 token = index.bondToken;

    // Pull in funds from sponsor to cover the proposal bond
    token.safeTransferFrom(index.sponsor, address(this), index.bondAmount);

    // Pull in funds from disputer to match the bond
    token.safeTransferFrom(msg.sender, address(this), index.bondAmount);

    // Create the request + proposal via UMA's OO
    uint256 bond = oracle.requestAndProposePriceFor(
      externalIdentifier,
      proposal.timestamp,
      abi.encodePacked(proposal.data),
      token,
      0,
      index.bondAmount,
      index.disputePeriod,
      address(this),
      proposal.value
    );

    // Build the OO request object for the above proposal
    SkinnyOptimisticOracleInterface.Request memory request;
    request.currency = token;
    request.finalFee = bond - index.bondAmount;
    request.bond = bond - request.finalFee;
    request.proposer = address(this);
    request.proposedPrice = proposal.value;
    request.expirationTime = block.timestamp + index.disputePeriod;
    request.customLiveness = index.disputePeriod;

    // Initiate the dispute on disputer's behalf
    oracle.disputePriceFor(
      externalIdentifier,
      proposal.timestamp,
      abi.encodePacked(proposal.data),
      request,
      msg.sender,
      address(this)
    );

    // Keep track of the outstanding bond and dispute
    index.bondsOutstanding += bond;
    index.disputesOutstanding++;
  }

  function deploySponsorPool(SkinnyDAOracle.Index storage index)
    public
    returns (SponsorPool)
  {
    return new SponsorPool(ERC20(address(index.bondToken)));
  }
}
