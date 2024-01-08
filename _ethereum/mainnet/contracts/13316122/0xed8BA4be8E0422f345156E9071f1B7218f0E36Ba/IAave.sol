// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./IERC20.sol";

interface AaveLendingPoolAddressesProvider {
    function getLendingPool() external view returns (address);

    function getAddress(bytes32 id) external view returns (address);
}

interface AToken is IERC20 {
    /**
     * @dev Returns the address of the incentives controller contract
     **/
    function getIncentivesController() external view returns (address);
}

interface AaveIncentivesController {
    function getRewardsBalance(address[] calldata assets, address user) external view returns (uint256);

    function claimRewards(
        address[] calldata assets,
        uint256 amount,
        address to
    ) external returns (uint256);
}

interface AaveLendingPool {
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;
}

interface AaveProtocolDataProvider {
    function getReserveTokensAddresses(address asset)
        external
        view
        returns (
            address aTokenAddress,
            address stableDebtTokenAddress,
            address variableDebtTokenAddress
        );

    function getReserveData(address asset)
        external
        view
        returns (
            uint256 availableLiquidity,
            uint256 totalStableDebt,
            uint256 totalVariableDebt,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 stableBorrowRate,
            uint256 averageStableBorrowRate,
            uint256 liquidityIndex,
            uint256 variableBorrowIndex,
            uint40 lastUpdateTimestamp
        );
}

//solhint-disable func-name-mixedcase
interface StakedAave is IERC20 {
    function claimRewards(address to, uint256 amount) external;

    function cooldown() external;

    function stake(address onBehalfOf, uint256 amount) external;

    function redeem(address to, uint256 amount) external;

    function getTotalRewardsBalance(address staker) external view returns (uint256);

    function stakersCooldowns(address staker) external view returns (uint256);

    function COOLDOWN_SECONDS() external view returns (uint256);

    function UNSTAKE_WINDOW() external view returns (uint256);
}
