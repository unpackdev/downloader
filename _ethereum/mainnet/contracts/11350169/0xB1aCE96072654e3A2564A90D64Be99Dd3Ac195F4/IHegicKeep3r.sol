// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface IHegicKeep3r {
    event Keep3rSet(address keep3r);
    event Keep3rHelperSet(address keep3rHelper);
    event SlidingOracleSet(address slidingOracle);
    event UnlockGasCostSet(uint256 unlockGasCost);
    event UnlockValueMultiplierSet(uint256 unlockValueMultiplier);

    // Actions by Keeper
    event EthOptionUnlockedByKeeper(uint256 _optionId);
    event WbtcOptionUnlockedByKeeper(uint256 _optionId);

    // Setters
    function setKeep3r(address _keep3r) external;
    function setKeep3rHelper(address _keep3rHelper) external;
    function setSlidingOracle(address _slidingOracle) external;
    function setUnlockGasCost(uint256 _unlockGasCost) external;
    function setUnlockValueMultiplier(uint256 _unlockValueMultiplier) external;

    // Getters
    function ethOptionsUnlockable(uint256[] calldata optionIDs) external view returns (bool);
    function wbtcOptionsUnlockable(uint256[] calldata optionIDs) external view returns (bool);

    // Keep3r actions
    function ethUnlockAll(uint256[] calldata optionIDs) external;
    function wbtcUnlockAll(uint256[] calldata optionIDs) external;

    // Helpers
    function weightedUnlockValue(uint256 poolUsage, uint256 unlockValue) external view returns (uint256);
    function unlockValue(uint256 totalUnlock) external view returns (uint256);
    function ethCallCost(uint256 optionsQty) external view returns (uint256);
    function wbtcCallCost(uint256 optionsQty) external view returns (uint256);
    function ethPoolUsage() external view returns (uint256);
    function wbtcPoolUsage() external view returns (uint256);

    function ethTotalUnlock(uint256[] calldata optionIDs) external view returns (uint256);
    function wbtcTotalUnlock(uint256[] calldata optionIDs) external view returns (uint256);

    // Name of the Keep3r
    function name() external pure returns (string memory);

}
