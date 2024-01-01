// SPDX-License-Identifier: MIT

/// @author Tient Technologies (Twitter:https://twitter.com/tient_tech | Github:https://github.com/Tient-Technologies | LinkedIn:https://www.linkedin.com/company/tient-technologies/)
/// @dev NiceArti (https://github.com/NiceArti)
/// To maintain developer you can also donate to this address - 0xDc3d3fA1aEbd13fF247E5F5D84A08A495b3215FB
/// @title Error constants for StakingNFT contract
pragma solidity ^0.8.18;

import "./Errors.sol";

error ZeroStakerBalance();
error StakeTokenAlredyRemovedOrWasNotAdded();
error TokenIsNotAvailableToStake();
error TransferAmountExceedsStakerBalance();
error ClaimAmountExceedBalance();
error StakerIsNotOwnerOf(address stakeToken, uint256 tokenId);