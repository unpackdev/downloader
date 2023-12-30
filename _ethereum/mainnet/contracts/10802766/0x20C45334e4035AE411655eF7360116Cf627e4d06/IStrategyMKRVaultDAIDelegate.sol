
// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;

import "./IERC20.sol";


interface IStrategyMKRVaultDAIDelegate {

    function getName() external pure returns (string memory);

    function setStrategist(address _strategist) external;

    function setHarvester(address _harvester) external;

    function setWithdrawalFee(uint _withdrawalFee) external;

    function setPerformanceFee(uint _performanceFee) external;

    function setStrategistReward(uint _strategistReward) external;

    function setBorrowCollateralizationRatio(uint _c) external;

    function setWithdrawCollateralizationRatio(uint _c_safe) external;

    function setOracle(address _oracle) external;

    function setMCDValue(
        address _manager,
        address _ethAdapter,
        address _daiAdapter,
        address _spot,
        address _jug
    ) external;

    function deposit() external;

    // Controller only function for creating additional rewards from dust
    function withdraw(IERC20 _asset) external returns (uint balance);

    // Withdraw partial funds, normally used with a vault withdrawal
    function withdraw(uint _amount) external;

    // Withdraw all funds, normally used when migrating strategies
    function withdrawAll() external returns (uint balance);

    function balanceOf() external view returns (uint);

    function balanceOfWant() external view returns (uint);

    function balanceOfmVault() external view returns (uint);

    function harvest() external;

    function shouldDraw() external view returns (bool);

    function drawAmount() external view returns (uint);

    function draw() external;

    function shouldRepay() external view returns (bool);

    function repayAmount() external view returns (uint);

    function repay() external;

    function forceRebalance(uint _amount) external;

    function getTotalDebtAmount() external view returns (uint);

    function getmVaultRatio(uint amount) external view returns (uint);

    function getUnderlyingDai() external view returns (uint);

    function setGovernance(address _governance) external;

    function setController(address _controller) external;
}