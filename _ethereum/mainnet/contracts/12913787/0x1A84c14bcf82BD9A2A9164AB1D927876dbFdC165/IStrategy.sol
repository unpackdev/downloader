pragma solidity 0.7.3;

interface IStrategy {

    function unsalvagableTokens(address tokens) external view returns (bool);

    function underlying() external view returns (address);
    function vault() external view returns (address);
    function treasury() external view returns (address);

    function withdrawAllToVault() external;
    function withdrawToVault(uint256 amount) external;

    function investedUnderlyingBalance() external view returns (uint256); // itsNotMuch()

    // should only be called by controller
    function salvage(address recipient, address token, uint256 amount) external;

    function stakeOnsenFarm() external;
    function stakeSushiBar() external;
    function stakeOnxFarm() external;
    function stakeOnx() external;

    function withdrawPendingTeamFund() external;
    function withdrawPendingTreasuryFund() external;
    function withdrawXSushiToStrategicWallet() external;

    function updateAccPerShare(address user) external;
    function updateUserRewardDebts(address user) external;
    function pendingReward() external view returns (uint256);
    function pendingRewardOfUser(address user) external view returns (uint256);
    function withdrawReward(address user) external;
}
