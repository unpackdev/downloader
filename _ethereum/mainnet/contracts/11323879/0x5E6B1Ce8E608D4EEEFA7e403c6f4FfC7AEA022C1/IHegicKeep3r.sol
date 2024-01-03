// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;

interface IHegicKeep3r {
    event Keep3rSet(address keep3r);

    // Actions by Keeper
    event EthOptionUnlockedByKeeper(uint256 _optionId);
    event WbtcOptionUnlockedByKeeper(uint256 _optionId);

    // Setters
    function setKeep3r(address _keep3r) external;

    // Getters
    function ethOptionUnlockable(uint256 _optionId) external view returns (bool);
    function wbtcOptionUnlockable(uint256 _optionId) external view returns (bool);

    // Keep3r actions
    function ethUnlock(uint256 _optionId) external;
    function wbtcUnlock(uint256 _optionId) external;

    // Name of the Keep3r
    function name() external pure returns (string memory);

}
