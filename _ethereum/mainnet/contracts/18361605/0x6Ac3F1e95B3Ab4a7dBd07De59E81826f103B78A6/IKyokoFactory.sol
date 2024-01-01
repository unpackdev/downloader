// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.18;

import "./DataTypes.sol";

interface IKyokoFactory {
    event CreatePool(uint256 indexed blockNumber, address kToken, address variableDebtAddress, address stableDebtAddress);
    event CreateKToken(address indexed user, address kToken);
    event CreateVariableToken(address indexed user, address variableDebtAddress);
    event CreateStableToken(address indexed user, address stableDebtAddress);
    event FactorUpdate(uint16 factor);
    event InitilLiquidityUpdate(uint256 amount);
    event LiquidationThreshold(uint16 threshold);
    event LockTime(uint32 lockTime);
    event FactoryUpdate(address kToken, address debtToken);

    function createPool(
        address _nftAddress
    ) external returns (address kTokenAddress, address variableDebtAddress, address stableDebtAddress);

    function createSharedPool() external returns (address kTokenAddress, address variableDebtAddress, address stableDebtAddress);

    function initReserve(
        address _nftAddress,
        uint40 _period,
        uint16 _ratio,
        uint24 _liqDuration,
        uint24 _bidDuration,
        bool _enabledStableBorrow,
        address kTokenAddress, 
        address variableDebtAddress, 
        address stableDebtAddress,
        DataTypes.RateStrategyInput memory _rateInput
    ) external payable;

    function setFactor(uint16 _factor) external;
    function setInitialLiquidity(uint256 amount) external;
    function setLiqThreshold(uint16 threshold) external;
    function setLockTime(uint32 lockTime) external;
    function setTokenFactory(address _createKToken, address _createDebtToken) external;
    function switchOnly() external;
}

interface INFT {
    function symbol() external view returns (string memory);
}