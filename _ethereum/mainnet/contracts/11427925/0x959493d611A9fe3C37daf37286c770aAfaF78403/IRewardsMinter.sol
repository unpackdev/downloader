//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

import "./IMintableERC20.sol";

interface IRewardsMinter {
    event NewCalculatorAdded(
        address indexed adder,
        address indexed newCalulator,
        uint256 calculatorPercentage,
        uint256 currentPercentage
    );

    event CalculatorRemoved(
        address indexed remover,
        address indexed calulator,
        uint256 calculatorPercentage,
        uint256 currentPercentage
    );

    event CalculatorPercentageUpdated(
        address indexed updater,
        address indexed calulator,
        uint256 newcalculatorPercentage,
        uint256 currentPercentage
    );

    event RewardsClaimed(address indexed account, uint256 indexed periodId, uint256 amount);

    function token() external view returns (IMintableERC20);

    function settings() external view returns (address);

    function rewardPeriodsRegistry() external view returns (address);

    function currentPercentage() external view returns (uint256);

    function getCalculators() external view returns (address[] memory);

    function getAvailableRewards(uint256 periodId, address account) external view returns (uint256);

    function claimRewards(uint256 periodId) external;

    function addCalculator(address newCalculator, uint256 percentage) external;

    function removeCalculator(address calculator) external;

    function hasCalculator(address calculator) external view returns (bool);

    function updateCalculatorPercentage(address calculator, uint256 percentage) external;
}
