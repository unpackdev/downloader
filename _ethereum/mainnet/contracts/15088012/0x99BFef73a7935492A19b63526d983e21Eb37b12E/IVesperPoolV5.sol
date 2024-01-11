// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
import "./IERC20.sol";

interface IVesperPoolV5 is IERC20 {
    function calculateUniversalFee(uint256 _profit) external view returns (uint256 _fee);

    function deposit() external payable;

    function deposit(uint256 _share) external;

    function getStrategies() external view returns (address[] memory);

    function governor() external view returns (address);

    function keepers() external view returns (address[] memory);

    function isKeeper(address _address) external view returns (bool);

    function withdraw(uint256 _amount) external;

    function withdrawETH(uint256 _amount) external;

    function pricePerShare() external view returns (uint256);

    function poolRewards() external view returns (address);

    function strategy(address _strategy)
        external
        view
        returns (
            bool _active,
            uint256 _interestFee, // Obsolete
            uint256 _debtRate, // Obsolete
            uint256 _lastRebalance,
            uint256 _totalDebt,
            uint256 _totalLoss,
            uint256 _totalProfit,
            uint256 _debtRatio,
            uint256 _externalDepositFee
        );

    function token() external view returns (address);

    function tokensHere() external view returns (uint256);

    function totalDebtOf(address _strategy) external view returns (uint256);

    function totalValue() external view returns (uint256);
}
