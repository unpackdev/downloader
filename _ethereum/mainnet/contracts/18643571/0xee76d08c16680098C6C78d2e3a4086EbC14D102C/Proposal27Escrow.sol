// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

IGovernorAlpha constant governorAlpha = IGovernorAlpha(0x95129751769f99CC39824a0793eF4933DD8Bb74B);
DAI constant dai = DAI(0x6B175474E89094C44Da98b954EedeAC495271d0F);
address constant recipient = 0x284D72effa0a1a6E4801A682C464908c5716D697;

// ETA of proposal #26
// https://etherscan.io/tx/0x9565f68623486c28c91fabd39443c63cd18a086075f7fe2a196bd6fb23c3a125#eventlog
uint256 constant proposal26Expiry = 1700947211;

// Offer expires 3 hours before proposal 26 ETA
uint256 constant offerExpiry = proposal26Expiry - 3 hours;

/**
 * Our offer is 10,000 DAI in exchange for canceling proposal 27
 * at least 3 hours before proposal 26 is ready to execute.
 *
 * If claim() has not been called by then, we will reclaim our DAI.
 *
 * To cancel the proposal, you must undelegate or transfer your NDX
 * and then call cancel(27).
 */
contract Proposal27Escrow {
  address internal immutable offerer;

  constructor() {
    offerer = msg.sender;
  }

  function claim() external {
    // Call at least 3 hours before proposal 26 expires
    require(block.timestamp < offerExpiry);
    // Cancel proposal prior to calling claim()
    require(governorAlpha.state(27) == ProposalState.Canceled);
    dai.transfer(recipient, dai.balanceOf(address(this)));
  }

  function refund() external {
    // If the expiry is reached without claim() having been called, we will reclaim our DAI
    require(block.timestamp > offerExpiry);
    dai.transfer(offerer, dai.balanceOf(address(this)));
  }
}

enum ProposalState {
  Pending,
  Active,
  Canceled,
  Defeated,
  Succeeded,
  Queued,
  Expired,
  Executed
}

interface IGovernorAlpha {
  function state(uint256 proposalId) external view returns (ProposalState);
}

interface DAI {
  function transfer(address recipient, uint256 amount) external returns (bool);

  function balanceOf(address account) external view returns (uint256);
}
