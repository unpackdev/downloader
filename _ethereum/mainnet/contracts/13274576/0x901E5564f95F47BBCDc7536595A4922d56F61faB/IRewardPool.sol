// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import "./IERC20Upgradeable.sol";

interface IRewardPool {

    event RewardPayoutDeposited(uint8 payoutType, uint64 fromBlock, uint64 toBlockExclusive, uint256 amount);

    event TokensClaimed(uint256 claimId, uint256 amount, uint256 claimBeforeBlock, address account);

    event ClaimedParachainRewards(address account, bytes recipient, uint256 amount);

    event ClaimedTokenRewards(address account, uint256 amount);

    event TokensBurnedForRefund(address account, bytes recipient, uint256 amount);

    function initZeroRewardPayout(uint256 maxSupply, uint8 payoutType, uint64 fromBlock, uint64 toBlockExclusive, uint256 amount) external;

    function depositRewardPayout(uint8 payoutType, uint64 fromBlock, uint64 toBlockExclusive, uint256 amount) external;

    function isClaimUsed(uint256 claimId) external view returns (bool);

    function claimTokensFor(uint256 claimId, uint256 amount, uint256 claimBeforeBlock, address account, bytes memory signature) external;

    function claimableRewardsOf(address account) external view returns (uint256);

    function isTokenClaim() external view returns (bool);

    function isParachainClaim() external view returns (bool);

    function claimTokenRewards() external;

    function claimParachainRewards(bytes calldata recipient) external;

    function toggleTokenBurn(bool isEnabled) external;

    function isTokenBurnEnabled() external view returns (bool);

    function burnTokens(uint256 amount, bytes calldata recipient) external;
}
