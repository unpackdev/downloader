// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;

interface IHegicPool {
    // Governance events
    event LotManagerSet(address lotManager);
    event MinTokenReservesSet(uint256 minTokenReserves);
    event WithdrawCooldownSet(uint256 withdrawCooldown);
    event WidthawFeeSet(uint256 withdrawFee);
    event PendingGovernanceSet(address pendingGovernance);
    event GovernanceAccepted();
    event PendingManagerSet(address pendingManager);
    event ManagerAccepted();
    event CollectedDust(address token, uint256 amount);

    // Protocol events
    event RewardsClaimed(uint256 rewards);
    event LotBought();
    event Migrated();

    // User events
    event Deposited(address depositor, uint256 tokenAmount, uint256 mintedShares);
    event Withdrew(address withdrawer, uint256 burntShares, uint256 withdrawedTokens, uint256 withdrawFee);


    function isHegicPool() external pure returns (bool);
    function getToken() external view returns (address);
}
